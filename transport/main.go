package main

import (
	"flag"
	"log"
	"net"
	"os"
)

func main() {

	flag.CommandLine.Parse(os.Args[1:])

	remote := os.Getenv("SS_REMOTE_HOST") + ":" + os.Getenv("SS_REMOTE_PORT")
	local := net.JoinHostPort(os.Getenv("SS_LOCAL_HOST"), os.Getenv("SS_LOCAL_PORT"))

	if os.Getenv("SS_LOCAL_HOST") == "" {
		log.Println("No SIP003 env detected")
		os.Exit(1)
	}

	log.Printf("Plugin activo | Local: %s | Remoto: %s", local, remote)

	l, err := net.Listen("tcp", local)
	if err != nil {
		log.Fatal(err)
	}

	for {
		conn, err := l.Accept()
		if err != nil {
			continue
		}
		conn.Close()
	}
}
