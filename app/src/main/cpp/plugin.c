#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[]) {

    printf("Minimal plugin launcher\n");

    char *cmd =
    "/data/data/com.github.shadowsocks.plugin.minimal/lib/libsimple-tls.so "
    "-listen 127.0.0.1:1081 "
    "-remote 2.brawlpass.online:443 "
    "-sni google.com";

    system(cmd);

    return 0;
}
