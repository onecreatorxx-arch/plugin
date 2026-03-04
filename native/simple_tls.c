#include <arpa/inet.h>
#include <errno.h>
#include <netdb.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

static volatile sig_atomic_t running = 1;

static void handle_signal(int sig) {
    (void)sig;
    running = 0;
}

static int must_get_port(const char *name) {
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

    return (int)port;
}

int main(void) {
    const char *local_host = getenv("SS_LOCAL_HOST");
    int local_port = must_get_port("SS_LOCAL_PORT");

    if (local_host == NULL || local_host[0] == '\0' || local_port < 0) {
        fprintf(stderr, "SIP003 environment not found; refusing to start\n");
        return 1;
    }

    signal(SIGINT, handle_signal);
    signal(SIGTERM, handle_signal);

    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror("socket");
        return 1;
    }

    int reuse = 1;
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse)) < 0) {
        perror("setsockopt");
        close(server_fd);
        return 1;
    }

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons((uint16_t)local_port);

    if (inet_pton(AF_INET, local_host, &addr.sin_addr) != 1) {
        fprintf(stderr, "unsupported SS_LOCAL_HOST (must be IPv4): %s\n", local_host);
        close(server_fd);
        return 1;
    }

    if (bind(server_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("bind");
        close(server_fd);
        return 1;
    }

    if (listen(server_fd, 64) < 0) {
        perror("listen");
        close(server_fd);
        return 1;
    }

    fprintf(stderr, "simple-tls plugin listening on %s:%d\n", local_host, local_port);

    while (running) {
        int client_fd = accept(server_fd, NULL, NULL);
        if (client_fd < 0) {
            if (errno == EINTR) continue;
            perror("accept");
            break;
        }
        close(client_fd);
    }

    close(server_fd);
    return 0;
}
