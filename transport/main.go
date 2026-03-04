package main

import (
"io"
"log"
"net"
"os"
)

func relay(a net.Conn, b net.Conn) {
go io.Copy(a, b)
io.Copy(b, a)
a.Close()
b.Close()
}

func main() {

localHost := os.Getenv("SS_LOCAL_HOST")
localPort := os.Getenv("SS_LOCAL_PORT")
remoteHost := os.Getenv("SS_REMOTE_HOST")
remotePort := os.Getenv("SS_REMOTE_PORT")

if localHost == "" {
os.Exit(1)
}

localAddr := net.JoinHostPort(localHost, localPort)
remoteAddr := net.JoinHostPort(remoteHost, remotePort)

l, err := net.Listen("tcp", localAddr)
if err != nil {
log.Fatal(err)
}

for {
client, err := l.Accept()
if err != nil {
continue
}

remote, err := net.Dial("tcp", remoteAddr)
if err != nil {
client.Close()
continue
}

go relay(client, remote)
}
}
