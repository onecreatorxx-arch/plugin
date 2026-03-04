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
