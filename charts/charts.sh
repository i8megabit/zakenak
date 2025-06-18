#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHARTS_DIR="${CHARTS_DIR:-${SCRIPT_DIR}/helm-charts}"

usage() {
    echo "Usage: $0 [install|upgrade|uninstall|list] CHART [NAMESPACE]" >&2
    exit 1
}

list_charts() {
    for d in "${CHARTS_DIR}"/*; do
        [ -f "$d/Chart.yaml" ] && basename "$d"
    done
}

run_helm() {
    local action=$1
    local chart=$2
    local ns=$3
    local chart_path="${CHARTS_DIR}/${chart}"
    [ -d "$chart_path" ] || { echo "Chart $chart not found" >&2; exit 1; }
    helm "$action" "$chart" "$chart_path" --namespace "$ns" --create-namespace
}

cmd=${1:-}
case "$cmd" in
    list)
        list_charts
        ;;
    install|upgrade|uninstall)
        [ $# -ge 2 ] || usage
        chart=$2
        ns=${3:-default}
        run_helm "$cmd" "$chart" "$ns"
        ;;
    *)
        usage
        ;;
esac
