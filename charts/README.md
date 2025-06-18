# Charts Toolkit

This script helps install and manage the charts in this repo. It can work on a host with Helm or from the provided Docker image.

## Commands

```bash
./charts.sh list                       # show available charts
./charts.sh install CHART [namespace]  # install a chart
./charts.sh upgrade CHART [namespace]  # upgrade a chart
./charts.sh uninstall CHART [namespace]# remove a chart
./charts.sh install-all [namespace]    # install all charts in defined order
```

`CHARTS_DIR` and `ORDER_FILE` environment variables can override the default locations of the charts and installation order.
