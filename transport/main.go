package main

import (
	"flag"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	// Ignorar todos los flags que Shadowsocks intente pasar
	flag.CommandLine.Parse(os.Args[1:]) 

	remote := os.Getenv("SS_REMOTE_HOST") + ":" + os.Getenv("SS_REMOTE_PORT")
	local := net.JoinHostPort(os.Getenv("SS_LOCAL_HOST"), os.Getenv("SS_LOCAL_PORT"))

	if os.Getenv("SS_LOCAL_HOST") == "" {
		log.Println("Error: No se detectaron variables SIP003")
		os.Exit(1)
	}

	log.Printf("Plugin Activo | Local: %s | Remoto: %s", local, remote)

	// Crear el listener para que Shadowsocks detecte que el plugin "está listo"
	l, err := net.Listen("tcp", local)
	if err != nil {
		log.Fatalf("Fallo al abrir puerto local: %v", err)
	}
	defer l.Close()

	// Mantener el proceso vivo
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	<-sigCh
}
