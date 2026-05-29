PROTO_DIR    := proto
GEN_GO_DIR   := gen/go
GEN_DART_DIR := ../theatre_companion_app/lib/showcontrol/grpc/generated

PROTO_FILES := $(shell find $(PROTO_DIR) -name "*.proto")

# ── Tools-Check ───────────────────────────────────────────────────────────────
# Benötigt: protoc, protoc-gen-go, protoc-gen-go-grpc, protoc-gen-dart
#
# Installation:
#   go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
#   go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
#   dart pub global activate protoc_plugin

.PHONY: proto proto-go proto-dart build run clean deps

## Alle Proto-Stubs generieren (Go + Dart)
proto: proto-go proto-dart

## Go-Stubs generieren
proto-go:
	@mkdir -p $(GEN_GO_DIR)
	protoc \
		--proto_path=$(PROTO_DIR) \
		--proto_path=$(shell go env GOPATH)/pkg/mod/github.com/googleapis/googleapis@*/. \
		--go_out=$(GEN_GO_DIR) \
		--go_opt=paths=source_relative \
		--go-grpc_out=$(GEN_GO_DIR) \
		--go-grpc_opt=paths=source_relative \
		$(PROTO_FILES)
	@echo "✓ Go stubs generiert in $(GEN_GO_DIR)"

## Dart-Stubs generieren
proto-dart:
	@mkdir -p $(GEN_DART_DIR)
	protoc \
		--proto_path=$(PROTO_DIR) \
		--dart_out=grpc:$(GEN_DART_DIR) \
		$(PROTO_FILES)
	@echo "✓ Dart stubs generiert in $(GEN_DART_DIR)"

## Abhängigkeiten laden
deps:
	go mod download
	go mod tidy

## Server bauen
build: deps
	go build -o bin/stagesync-server ./cmd/server

## Server starten (Entwicklung)
run:
	go run ./cmd/server --name "StageSync-Dev" --port 50051

## Aufräumen
clean:
	rm -rf $(GEN_GO_DIR) bin/
