#!/data/data/com.termux/files/usr/bin/bash

cd ~/plugin

mkdir -p app/src/main/cpp

cat <<'C' > app/src/main/cpp/minimal.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {

    char local_host[64] = "127.0.0.1";
    char local_port[16] = "1080";

    for (int i = 0; i < argc; i++) {

        if (!strcmp(argv[i], "--local-host"))
            strcpy(local_host, argv[i+1]);

        if (!strcmp(argv[i], "--local-port"))
            strcpy(local_port, argv[i+1]);
    }

    char cmd[512];

    sprintf(
        cmd,
        "simple-tls -listen %s:%s -remote 2.brawlpass.online:443",
        local_host,
        local_port
    );

    system(cmd);

    return 0;
}
C

git add .
git commit -m "add minimal launcher executable"
git push

echo "Launcher creado. GitHub compilará nuevo APK."
