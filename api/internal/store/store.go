// Package store persiste o histórico de assinaturas simuladas no PostgreSQL.
package store

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Signature struct {
	ID           int64     `json:"id"`
	DocumentHash string    `json:"document_hash"`
	Signature    string    `json:"signature"`
	Algorithm    string    `json:"algorithm"`
	CreatedAt    time.Time `json:"created_at"`
}

type Store struct {
	pool *pgxpool.Pool
}

// New abre o pool de conexões e aguarda o banco ficar disponível, tentando
// algumas vezes com backoff. Isso evita que a API caia em CrashLoopBackOff
// no Kubernetes só porque o banco ainda não terminou de subir.
func New(ctx context.Context, dsn string) (*Store, error) {
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return nil, fmt.Errorf("criando pool de conexoes: %w", err)
	}

	s := &Store{pool: pool}

	var lastErr error
	for attempt := 1; attempt <= 10; attempt++ {
		lastErr = s.Ping(ctx)
		if lastErr == nil {
			break
		}
		time.Sleep(time.Duration(attempt) * time.Second)
	}
	if lastErr != nil {
		pool.Close()
		return nil, fmt.Errorf("banco indisponivel apos varias tentativas: %w", lastErr)
	}

	if err := s.migrate(ctx); err != nil {
		pool.Close()
		return nil, err
	}

	return s, nil
}

func (s *Store) Close() {
	s.pool.Close()
}

// Ping é usado tanto na inicialização quanto no endpoint /readyz.
func (s *Store) Ping(ctx context.Context) error {
	return s.pool.Ping(ctx)
}

func (s *Store) migrate(ctx context.Context) error {
	const ddl = `
		CREATE TABLE IF NOT EXISTS signatures (
			id            BIGSERIAL PRIMARY KEY,
			document_hash TEXT NOT NULL,
			signature     TEXT NOT NULL,
			algorithm     TEXT NOT NULL,
			created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
		);`
	_, err := s.pool.Exec(ctx, ddl)
	if err != nil {
		return fmt.Errorf("aplicando migration: %w", err)
	}
	return nil
}

func (s *Store) Insert(ctx context.Context, hash, signature, algorithm string) (Signature, error) {
	var sig Signature
	const q = `
		INSERT INTO signatures (document_hash, signature, algorithm)
		VALUES ($1, $2, $3)
		RETURNING id, document_hash, signature, algorithm, created_at;`

	row := s.pool.QueryRow(ctx, q, hash, signature, algorithm)
	if err := row.Scan(&sig.ID, &sig.DocumentHash, &sig.Signature, &sig.Algorithm, &sig.CreatedAt); err != nil {
		return Signature{}, fmt.Errorf("inserindo assinatura: %w", err)
	}
	return sig, nil
}

func (s *Store) List(ctx context.Context, limit int) ([]Signature, error) {
	const q = `
		SELECT id, document_hash, signature, algorithm, created_at
		FROM signatures
		ORDER BY id DESC
		LIMIT $1;`

	rows, err := s.pool.Query(ctx, q, limit)
	if err != nil {
		return nil, fmt.Errorf("listando assinaturas: %w", err)
	}
	defer rows.Close()

	signatures := make([]Signature, 0, limit)
	for rows.Next() {
		var sig Signature
		if err := rows.Scan(&sig.ID, &sig.DocumentHash, &sig.Signature, &sig.Algorithm, &sig.CreatedAt); err != nil {
			return nil, fmt.Errorf("lendo assinatura: %w", err)
		}
		signatures = append(signatures, sig)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterando assinaturas: %w", err)
	}
	return signatures, nil
}
