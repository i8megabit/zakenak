FROM golang:1.21 as builder

ARG VERSION=dev

WORKDIR /app
COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o zakenak \
    -ldflags="-X main.Version=${VERSION}" \
    ./cmd/zakenak

FROM nvidia/cuda:12.8.0-base-ubuntu22.04




COPY --from=builder /app/zakenak /usr/local/bin/
RUN chmod +x /usr/local/bin/zakenak

WORKDIR /workspace
ENTRYPOINT ["zakenak"]
