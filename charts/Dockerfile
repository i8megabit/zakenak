FROM alpine:3.19
RUN apk add --no-cache bash curl tar yq
RUN curl -L https://get.helm.sh/helm-v3.14.2-linux-amd64.tar.gz -o helm.tar.gz && \
    tar -xzvf helm.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf linux-amd64 helm.tar.gz
COPY . /charts
WORKDIR /charts
ENTRYPOINT ["/charts/charts.sh"]
