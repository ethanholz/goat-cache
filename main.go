package main

import (
	// "context"
	// "database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"

	_ "embed"

	_ "modernc.org/sqlite"

	// "github.com/ethanholz/goat-cache/db"
	"github.com/ethanholz/goat-cache/oidc"
)

const (
	audience = "goat-cache.fly.dev"
	port     = ":8080"
)

type Server struct {
	audience     string
	allowedRepos []string
}

func NewServer(audience string, allowedRepos []string) (*Server, error) {
	return &Server{
		audience:     audience,
		allowedRepos: allowedRepos,
	}, nil
}

func (s *Server) github(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	authHeader := r.Header.Get("Authorization")
	if !strings.HasPrefix(authHeader, "Bearer ") {
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	tokenString := strings.TrimPrefix(authHeader, "Bearer ")

	// Validate the token
	claims, err := oidc.ValidateTokenCameFromGitHub(tokenString)
	// Validate the audience is correct
	if claims.Audience[0] != s.audience {
		http.Error(w, "Invalid audience", http.StatusUnauthorized)
		return
	}

	if err != nil {
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}

	// Return the received claims back
	response := map[string]interface{}{
		"authenticated": true,
		"repo":          claims.Repo,
		"workflow":      claims.Workflow,
		"actor":         claims.Actor,
		"event_name":    claims.EventName,
	}
	fmt.Println(response)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

//go:embed schema.sql
var ddl string

func main() {
	// ctx := context.Background()
	// base, err := sql.Open("sqlite", "test.db")
	// if err != nil {
	// 	log.Fatal(err)
	// }
	//
	// _, err = base.ExecContext(ctx, ddl)
	// if err != nil {
	// 	log.Fatal(err)
	// }
	//
	// queries := db.New(base)

	server, err := NewServer(audience, []string{"ethanholz/goat-cache-testing"})
	if err != nil {
		panic(err)
	}

	http.HandleFunc("/oidc/github", server.github)
	log.Printf("Listening on %s", port)
	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal(err)
	}
}
