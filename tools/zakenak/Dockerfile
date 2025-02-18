FROM golang:1.21 as builder

ARG VERSION=dev

WORKDIR /app
COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o zakenak \
    -ldflags="-X main.Version=${VERSION}" \
    ./tools/zakenak/cmd/zakenak

FROM nvidia/cuda:12.8.0-base-ubuntu22.04

# Настройка переменных окружения для NVIDIA
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV PATH="/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/lib/wsl/lib:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}"

# Установка необходимых runtime зависимостей
RUN apt-get update && apt-get install -y \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/zakenak /usr/local/bin/
RUN chmod +x /usr/local/bin/zakenak

WORKDIR /workspace
ENTRYPOINT ["zakenak"]
