# Build stage
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.* ./

# Copy source code
COPY . .

# Build binary
ARG VERSION=development
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/build/zakenak -ldflags="-X main.Version=${VERSION}" ./cmd/zakenak

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache ca-certificates

# Copy binary from builder
COPY --from=builder /app/build/zakenak /usr/local/bin/zakenak

# Set entrypoint
ENTRYPOINT ["zakenak"]

# Add metadata
LABEL org.opencontainers.image.source="https://github.com/i8megabit/zakenak"
LABEL org.opencontainers.image.description="Zakenak - Kubernetes cluster management tool"
LABEL org.opencontainers.image.licenses="MIT"

/* 
MIT License

Copyright (c) 2024 @eberil

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
*/