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

# MIT License

# Copyright (c) 2024 @eberil

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.