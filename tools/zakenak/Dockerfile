# Copyright (c) 2024 Mikhail Eberil
# Dockerfile for Ƶakenak™®

# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY . .

# Установка зависимостей
RUN go mod download

# Сборка с поддержкой GPU
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o zakenak ./cmd/zakenak

# Final stage
FROM nvidia/cuda:12.8.0-base-ubuntu22.04

WORKDIR /app
COPY --from=builder /app/zakenak .

# Установка необходимых runtime зависимостей
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Настройка переменных окружения для NVIDIA
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV PATH="/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/lib/wsl/lib:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}"

ENTRYPOINT ["/app/zakenak"]