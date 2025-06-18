# Charts Toolkit

This small tool helps install local Helm charts.

## Usage

```bash
./charts.sh list
./charts.sh install <chart> [namespace]
./charts.sh upgrade <chart> [namespace]
./charts.sh uninstall <chart> [namespace]
```

The script expects charts in `charts/helm-charts`.
