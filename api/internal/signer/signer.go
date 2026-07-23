// Package signer simula uma assinatura digital: gera um hash SHA-256 do
// documento recebido e assina esse hash com uma chave RSA (RSA-PSS).
//
// A chave é gerada em memória na inicialização do processo — cada réplica
// da API tem seu próprio par de chaves. Isso é suficiente para demonstrar
// o fluxo de assinatura fim a fim; um cenário real de produção usaria uma
// chave centralizada (ex: HashiCorp Vault ou um HSM) compartilhada entre
// as réplicas, para que a assinatura de qualquer uma delas seja verificável
// com a mesma chave pública.
package signer

import (
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"fmt"
)

const Algorithm = "RSA-PSS-SHA256"

type Signer struct {
	privateKey *rsa.PrivateKey
}

func New() (*Signer, error) {
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		return nil, fmt.Errorf("gerando chave RSA: %w", err)
	}
	return &Signer{privateKey: key}, nil
}

// Sign retorna o hash SHA-256 do documento (hex) e a assinatura RSA-PSS
// desse hash (base64), nessa ordem.
func (s *Signer) Sign(document []byte) (hash string, signature string, err error) {
	digest := sha256.Sum256(document)

	sig, err := rsa.SignPSS(rand.Reader, s.privateKey, crypto.SHA256, digest[:], nil)
	if err != nil {
		return "", "", fmt.Errorf("assinando documento: %w", err)
	}

	return hex.EncodeToString(digest[:]), base64.StdEncoding.EncodeToString(sig), nil
}
