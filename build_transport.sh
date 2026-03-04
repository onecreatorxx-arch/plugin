#!/data/data/com.termux/files/usr/bin/bash

cd ~/plugin

echo "Creando plugin SIP003 en Go..."

mkdir -p transport

cat <<'GO' > transport/main.go
package main

import (
"log"
"net"
"os"
"os/signal"
"syscall"
)

func main() {

remoteHost := os.Getenv("SS_REMOTE_HOST")
remotePort := os.Getenv("SS_REMOTE_PORT")

localHost := os.Getenv("SS_LOCAL_HOST")
localPort := os.Getenv("SS_LOCAL_PORT")

remote := remoteHost + ":" + remotePort
local := net.JoinHostPort(localHost, localPort)

log.Printf("Transport plugin iniciado")
log.Printf("Local: %s", local)
log.Printf("Remote: %s", remote)

listener, err := net.Listen("tcp", local)

if err != nil {
log.Printf("Error listener: %v", err)
os.Exit(1)
}

defer listener.Close()

sigCh := make(chan os.Signal, 1)

signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

<-sigCh
}
GO

echo "Compilando binario Android..."

env GOOS=android GOARCH=arm64 go build -ldflags="-s -w" -o libtransport.so transport/main.go

echo "Moviendo binario al proyecto..."

mkdir -p app/src/main/jniLibs/arm64-v8a

mv libtransport.so app/src/main/jniLibs/arm64-v8a/

echo "Subiendo cambios..."

git add .
git commit -m "add SIP003 transport plugin"
git push

echo ""
echo "Listo."
echo "GitHub Actions ahora compilará el APK automáticamente."
