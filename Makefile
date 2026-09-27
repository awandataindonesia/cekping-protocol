# Pinned toolchain versions. Keep these in sync with the headers of the generated files.
PROTOC_VERSION             := 33.4
PROTOC_GEN_GO_VERSION      := v1.36.11
PROTOC_GEN_GO_GRPC_VERSION := v1.6.0

.PHONY: generate tools check

generate:
	protoc --go_out=. --go_opt=paths=source_relative \
		--go-grpc_out=. --go-grpc_opt=paths=source_relative \
		cekping.proto

# Installs the Go plugins. protoc itself must be downloaded separately from
# https://github.com/protocolbuffers/protobuf/releases/tag/v$(PROTOC_VERSION)
tools:
	go install google.golang.org/protobuf/cmd/protoc-gen-go@$(PROTOC_GEN_GO_VERSION)
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@$(PROTOC_GEN_GO_GRPC_VERSION)

# Fails if the generated code is out of date with cekping.proto.
check: generate
	git diff --exit-code -- '*.pb.go'
