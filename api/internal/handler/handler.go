// Package handler expõe a API HTTP: healthcheck, assinatura de documentos
// e consulta do histórico.
package handler

import (
	"context"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/Guilherme-vinholes/meu-desafio-devops-bry/api/internal/signer"
	"github.com/Guilherme-vinholes/meu-desafio-devops-bry/api/internal/store"
)

type Store interface {
	Ping(ctx context.Context) error
	Insert(ctx context.Context, hash, signature, algorithm string) (store.Signature, error)
	List(ctx context.Context, limit int) ([]store.Signature, error)
}

type Signer interface {
	Sign(document []byte) (hash string, signature string, err error)
}

type Handler struct {
	signer   Signer
	store    Store
	hostname string
}

func New(sg Signer, st Store, hostname string) *Handler {
	return &Handler{signer: sg, store: st, hostname: hostname}
}

func (h *Handler) Routes() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", h.Healthz)
	mux.HandleFunc("GET /readyz", h.Readyz)
	mux.HandleFunc("POST /api/sign", h.Sign)
	mux.HandleFunc("GET /api/signatures", h.ListSignatures)
	return mux
}

// Healthz é a liveness probe: só confirma que o processo está de pé.
func (h *Handler) Healthz(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"status": "ok",
		"host":   h.hostname,
	})
}

// Readyz é a readiness probe: confirma que a dependência (banco) está
// acessível antes do pod receber tráfego.
func (h *Handler) Readyz(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()

	if err := h.store.Ping(ctx); err != nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{
			"status": "unavailable",
			"reason": err.Error(),
		})
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
}

type signRequest struct {
	Document string `json:"document"`
}

type signResponse struct {
	ID           int64     `json:"id"`
	DocumentHash string    `json:"document_hash"`
	Signature    string    `json:"signature"`
	Algorithm    string    `json:"algorithm"`
	SignedAt     time.Time `json:"signed_at"`
	HandledBy    string    `json:"handled_by"`
}

func (h *Handler) Sign(w http.ResponseWriter, r *http.Request) {
	var req signRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "corpo da requisicao invalido"})
		return
	}
	if req.Document == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "campo 'document' e obrigatorio"})
		return
	}

	hash, signature, err := h.signer.Sign([]byte(req.Document))
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "falha ao assinar documento"})
		return
	}

	saved, err := h.store.Insert(r.Context(), hash, signature, signer.Algorithm)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "falha ao persistir assinatura"})
		return
	}

	writeJSON(w, http.StatusCreated, signResponse{
		ID:           saved.ID,
		DocumentHash: saved.DocumentHash,
		Signature:    saved.Signature,
		Algorithm:    saved.Algorithm,
		SignedAt:     saved.CreatedAt,
		HandledBy:    h.hostname,
	})
}

func (h *Handler) ListSignatures(w http.ResponseWriter, r *http.Request) {
	limit := 20
	if raw := r.URL.Query().Get("limit"); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil && parsed > 0 && parsed <= 200 {
			limit = parsed
		}
	}

	signatures, err := h.store.List(r.Context(), limit)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "falha ao listar assinaturas"})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"handled_by": h.hostname,
		"count":      len(signatures),
		"signatures": signatures,
	})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}
