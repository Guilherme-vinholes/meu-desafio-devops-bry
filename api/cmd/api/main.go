package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/Guilherme-vinholes/meu-desafio-devops-bry/api/internal/handler"
	"github.com/Guilherme-vinholes/meu-desafio-devops-bry/api/internal/signer"
	"github.com/Guilherme-vinholes/meu-desafio-devops-bry/api/internal/store"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	port := getEnv("PORT", "8080")
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL nao definida")
	}

	st, err := store.New(ctx, dsn)
	if err != nil {
		log.Fatalf("conectando ao banco: %v", err)
	}
	defer st.Close()

	sg, err := signer.New()
	if err != nil {
		log.Fatalf("gerando par de chaves: %v", err)
	}

	hostname, err := os.Hostname()
	if err != nil {
		hostname = "unknown"
	}

	h := handler.New(sg, st, hostname)

	srv := &http.Server{
		Addr:              ":" + port,
		Handler:           h.Routes(),
		ReadHeaderTimeout: 5 * time.Second,
	}

	go func() {
		log.Printf("api ouvindo em :%s (host=%s)", port, hostname)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("servidor encerrado com erro: %v", err)
		}
	}()

	<-ctx.Done()
	log.Println("sinal de encerramento recebido, finalizando conexoes em andamento...")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("erro no shutdown: %v", err)
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
