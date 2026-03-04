#!/data/data/com.termux/files/usr/bin/bash

cd ~/plugin

mkdir -p app/src/main/cpp

cat <<'C' > app/src/main/cpp/plugin.c
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
C

git add .
git commit -m "add plugin launcher"
git push

echo "Launcher agregado. GitHub compilará nuevo APK."
