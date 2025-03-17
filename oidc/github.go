package oidc

import (
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"math/big"
	"net/http"

	"github.com/golang-jwt/jwt/v5"
)

type JWK struct {
	N   string
	Kty string
	Kid string
	Alg string
	E   string
	Use string
	X5c []string
	X5t string
}

type JWKS struct {
	Keys []JWK
}

type Claims struct {
	jwt.RegisteredClaims
	Repo      string `json:"repository"`
	Workflow  string `json:"workflow"`
	Actor     string `json:"actor"`
	EventName string `json:"event_name"`
}

// This allows for us to get the key from the JWKS endpoint
func getKeyFromJwks(jwksBytes []byte) func(*jwt.Token) (interface{}, error) {
	return func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}

		var jwks JWKS
		if err := json.Unmarshal(jwksBytes, &jwks); err != nil {
			return nil, fmt.Errorf("unable to parse JWKS")
		}

		for _, jwk := range jwks.Keys {
			if jwk.Kid == token.Header["kid"] {
				nBytes, err := base64.RawURLEncoding.DecodeString(jwk.N)
				if err != nil {
					return nil, fmt.Errorf("unable to parse key")
				}
				var n big.Int

				eBytes, err := base64.RawURLEncoding.DecodeString(jwk.E)
				if err != nil {
					return nil, fmt.Errorf("unable to parse key")
				}
				var e big.Int

				key := rsa.PublicKey{
					N: n.SetBytes(nBytes),
					E: int(e.SetBytes(eBytes).Uint64()),
				}

				return &key, nil
			}
		}

		return nil, fmt.Errorf("unknown kid: %v", token.Header["kid"])
	}
}

// Validate the token came from GitHub using the JWKS endpoint
func ValidateTokenCameFromGitHub(oidcTokenString string) (*Claims, error) {
	resp, err := http.Get("https://token.actions.githubusercontent.com/.well-known/jwks")
	if err != nil {
		fmt.Println(err)
		return nil, fmt.Errorf("unable to get JWKS configuration")
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("unable to read JWKS configuration: %s", err)
	}

	claims := &Claims{}
	// Attempt to validate JWT with JWKS
	oidcToken, err := jwt.ParseWithClaims(oidcTokenString, claims, getKeyFromJwks(body))
	if err != nil || !oidcToken.Valid {
		return nil, fmt.Errorf("unable to validate JWT")
	}

	return claims, nil
}
