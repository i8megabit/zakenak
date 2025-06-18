# Charts Collection

A set of Helm charts with a helper script to manage them.

## Requirements
- bash
- helm
- yq

## Quick start

List charts:
```bash
./charts/charts.sh list
```

Install one chart:
```bash
./charts/charts.sh install <chart> [namespace]
```

Install all charts in the order from `install-order.yaml`:
```bash
./charts/charts.sh install-all [namespace]
```

Each chart lives in `charts/helm-charts` and may have its own README.
Build a Docker image with the script if you prefer an isolated environment:
```bash
docker build -t charts ./charts
```
