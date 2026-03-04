#include <errno.h>
#include <netdb.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#define BUFFER_SIZE 32768
#define HANDSHAKE_BUFFER 8192

#define DEFAULT_PROXY_HOST "emailmarketing.personal.com.ar"
#define DEFAULT_PROXY_PORT 80

static const char *FIRST_PAYLOAD =
    "CONNECT / HTTP/1.1\r\n"
    "Host: personal.com.ar\r\n"
    "\r\n";

static const char *SECOND_PAYLOAD =
    "GET / HTTP/1.1\r\n"
    "Host: 2.brawlpass.online\r\n"
    "Upgrade: websocket\r\n"
    "Auth: test\r\n"
    "\r\n";

static volatile sig_atomic_t running = 1;

struct conn_pair {
    int client_fd;
    int remote_fd;
};

struct relay_args {
    int from_fd;
    int to_fd;
};

static void handle_signal(int sig) {
    (void)sig;
    running = 0;
}

static int parse_port(const char *name, int *out_port) {
    const char *value = getenv(name);
    if (value == NULL || value[0] == '\0') {
        fprintf(stderr, "missing environment variable: %s\n", name);
        return -1;
    }

    char *end = NULL;
    long port = strtol(value, &end, 10);
    if (end == value || *end != '\0' || port <= 0 || port > 65535) {
        fprintf(stderr, "invalid port in %s: %s\n", name, value);
        return -1;
    }

    *out_port = (int)port;
    return 0;
}

static int connect_tcp_host(const char *host, int port) {
    char port_text[16];
    snprintf(port_text, sizeof(port_text), "%d", port);

    struct addrinfo hints;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    struct addrinfo *result = NULL;
    int gai = getaddrinfo(host, port_text, &hints, &result);
    if (gai != 0) {
        fprintf(stderr, "getaddrinfo(%s:%d): %s\n", host, port, gai_strerror(gai));
        return -1;
    }

    int fd = -1;
    for (struct addrinfo *it = result; it != NULL; it = it->ai_next) {
        fd = socket(it->ai_family, it->ai_socktype, it->ai_protocol);
        if (fd < 0) continue;

        if (connect(fd, it->ai_addr, it->ai_addrlen) == 0) break;

        close(fd);
        fd = -1;
    }

    freeaddrinfo(result);
    return fd;
}

static int send_all(int fd, const char *data, size_t len) {
    size_t sent = 0;
    while (sent < len) {
        ssize_t n = send(fd, data + sent, len - sent, 0);
        if (n < 0) {
            if (errno == EINTR) continue;
            return -1;
        }
        sent += (size_t)n;
    }
    return 0;
}

static ssize_t read_http_headers(int fd, char *buffer, size_t cap, int timeout_ms) {
    if (cap == 0) return -1;

    struct timeval tv;
    tv.tv_sec = timeout_ms / 1000;
    tv.tv_usec = (timeout_ms % 1000) * 1000;
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    size_t used = 0;
    while (used + 1 < cap) {
        ssize_t n = recv(fd, buffer + used, cap - used - 1, 0);
        if (n == 0) break;
        if (n < 0) {
            if (errno == EINTR) continue;
            if (errno == EAGAIN || errno == EWOULDBLOCK) break;
            return -1;
        }

        used += (size_t)n;
        buffer[used] = '\0';
        if (strstr(buffer, "\r\n\r\n") != NULL) {
            return (ssize_t)used;
        }
    }

    if (used > 0) {
        buffer[used] = '\0';
        return (ssize_t)used;
    }

    return -1;
}

static int connect_upgraded_proxy_tunnel(void) {
    const char *proxy_host = getenv("SIMPLE_TLS_PROXY_HOST");
    if (proxy_host == NULL || proxy_host[0] == '\0') proxy_host = DEFAULT_PROXY_HOST;

    int proxy_port = DEFAULT_PROXY_PORT;
    const char *proxy_port_env = getenv("SIMPLE_TLS_PROXY_PORT");
    if (proxy_port_env != NULL && proxy_port_env[0] != '\0') {
        char *end = NULL;
        long parsed = strtol(proxy_port_env, &end, 10);
        if (end != proxy_port_env && *end == '\0' && parsed > 0 && parsed <= 65535) {
            proxy_port = (int)parsed;
        }
    }

    int fd = connect_tcp_host(proxy_host, proxy_port);
    if (fd < 0) {
        fprintf(stderr, "failed tcp connect to proxy %s:%d\n", proxy_host, proxy_port);
        return -1;
    }

    if (send_all(fd, FIRST_PAYLOAD, strlen(FIRST_PAYLOAD)) != 0) {
        fprintf(stderr, "failed sending first payload\n");
        close(fd);
        return -1;
    }

    usleep(300000);

    char response[HANDSHAKE_BUFFER];
    ssize_t first_response_bytes = read_http_headers(fd, response, sizeof(response), 1500);
    if (first_response_bytes > 0) {
        fprintf(stderr, "first proxy response received (%zd bytes), status ignored\n", first_response_bytes);
    }

    if (send_all(fd, SECOND_PAYLOAD, strlen(SECOND_PAYLOAD)) != 0) {
        fprintf(stderr, "failed sending second payload\n");
        close(fd);
        return -1;
    }

    ssize_t second_response_bytes = read_http_headers(fd, response, sizeof(response), 3000);
    if (second_response_bytes < 0) {
        fprintf(stderr, "no response for second payload\n");
        close(fd);
        return -1;
    }

    if (strstr(response, " 101") == NULL && strstr(response, "HTTP/1.1 101") == NULL && strstr(response, "HTTP/1.0 101") == NULL) {
        fprintf(stderr, "second payload did not return 101, response was: %s\n", response);
        close(fd);
        return -1;
    }

    fprintf(stderr, "proxy tunnel upgraded successfully through %s:%d\n", proxy_host, proxy_port);
    return fd;
}

static int bind_local(const char *host, int port) {
    char port_text[16];
    snprintf(port_text, sizeof(port_text), "%d", port);

    struct addrinfo hints;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;

    struct addrinfo *result = NULL;
    int gai = getaddrinfo(host, port_text, &hints, &result);
    if (gai != 0) {
        fprintf(stderr, "getaddrinfo(local=%s:%d): %s\n", host, port, gai_strerror(gai));
        return -1;
    }

    int fd = -1;
    for (struct addrinfo *it = result; it != NULL; it = it->ai_next) {
        fd = socket(it->ai_family, it->ai_socktype, it->ai_protocol);
        if (fd < 0) continue;

        int reuse = 1;
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));

        if (bind(fd, it->ai_addr, it->ai_addrlen) == 0) break;

        close(fd);
        fd = -1;
    }

    freeaddrinfo(result);

    if (fd < 0) return -1;
    if (listen(fd, 128) < 0) {
        perror("listen");
        close(fd);
        return -1;
    }

    return fd;
}

static void *relay_one_direction(void *arg) {
    struct relay_args *relay = (struct relay_args *)arg;
    char buffer[BUFFER_SIZE];

    while (1) {
        ssize_t n = recv(relay->from_fd, buffer, sizeof(buffer), 0);
        if (n == 0) break;
        if (n < 0) {
            if (errno == EINTR) continue;
            break;
        }

        size_t sent_total = 0;
        while (sent_total < (size_t)n) {
            ssize_t s = send(relay->to_fd, buffer + sent_total, (size_t)n - sent_total, 0);
            if (s < 0) {
                if (errno == EINTR) continue;
                goto done;
            }
            sent_total += (size_t)s;
        }
    }

done:
    shutdown(relay->to_fd, SHUT_WR);
    return NULL;
}

static void *handle_client(void *arg) {
    struct conn_pair *pair = (struct conn_pair *)arg;

    struct relay_args uplink = {.from_fd = pair->client_fd, .to_fd = pair->remote_fd};
    struct relay_args downlink = {.from_fd = pair->remote_fd, .to_fd = pair->client_fd};

    pthread_t up_thread;
    pthread_t down_thread;

    if (pthread_create(&up_thread, NULL, relay_one_direction, &uplink) != 0 ||
        pthread_create(&down_thread, NULL, relay_one_direction, &downlink) != 0) {
        close(pair->client_fd);
        close(pair->remote_fd);
        free(pair);
        return NULL;
    }

    pthread_join(up_thread, NULL);
    pthread_join(down_thread, NULL);

    close(pair->client_fd);
    close(pair->remote_fd);
    free(pair);
    return NULL;
}

int main(void) {
    const char *local_host = getenv("SS_LOCAL_HOST");
    int local_port = 0;

    if (local_host == NULL || local_host[0] == '\0' || parse_port("SS_LOCAL_PORT", &local_port) != 0) {
        fprintf(stderr, "SIP003 env invalid; required: SS_LOCAL_HOST and SS_LOCAL_PORT\n");
        return 1;
    }

    signal(SIGINT, handle_signal);
    signal(SIGTERM, handle_signal);

    int server_fd = bind_local(local_host, local_port);
    if (server_fd < 0) {
        perror("bind_local");
        return 1;
    }

    fprintf(stderr, "plugin listening on %s:%d; remote tunnel is hardcoded proxy handshake\n", local_host, local_port);

    while (running) {
        int client_fd = accept(server_fd, NULL, NULL);
        if (client_fd < 0) {
            if (errno == EINTR) continue;
            perror("accept");
            break;
        }

        int remote_fd = connect_upgraded_proxy_tunnel();
        if (remote_fd < 0) {
            fprintf(stderr, "failed to establish upgraded proxy tunnel\n");
            close(client_fd);
            continue;
        }

        struct conn_pair *pair = (struct conn_pair *)malloc(sizeof(struct conn_pair));
        if (pair == NULL) {
            close(client_fd);
            close(remote_fd);
            continue;
        }

        pair->client_fd = client_fd;
        pair->remote_fd = remote_fd;

        pthread_t client_thread;
        if (pthread_create(&client_thread, NULL, handle_client, pair) != 0) {
            close(client_fd);
            close(remote_fd);
            free(pair);
            continue;
        }
        pthread_detach(client_thread);
    }

    close(server_fd);
    return 0;
}
