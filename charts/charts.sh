#!/usr/bin/env bash
set -euo pipefail

# Каталог со скриптом
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Где лежат чарты
CHARTS_DIR="${CHARTS_DIR:-${SCRIPT_DIR}/helm-charts}"
# Файл с порядком установки
ORDER_FILE="${ORDER_FILE:-${CHARTS_DIR}/install-order.yaml}"

usage() {
    echo "Использование: $0 [list|install|upgrade|uninstall|install-all|upgrade-all|uninstall-all] [CHART] [NAMESPACE]" >&2
    exit 1
}

# Показать все доступные чарты
list_charts() {
    for d in "${CHARTS_DIR}"/*; do
        [ -f "$d/Chart.yaml" ] && basename "$d"
    done
}

# Вызов helm с нужными параметрами
run_helm() {
    local action=$1
    local chart=$2
    local ns=$3
    local chart_path="${CHARTS_DIR}/${chart}"
    [ -d "$chart_path" ] || { echo "Чарт $chart не найден" >&2; exit 1; }
    helm "$action" "$chart" "$chart_path" --namespace "$ns" --create-namespace
}

# Список чартов согласно файлу порядка установки
all_charts() {
    if [ -f "$ORDER_FILE" ]; then
        yq '.charts[]' "$ORDER_FILE"
    else
        list_charts
    fi
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
    install-all|upgrade-all|uninstall-all)
        action=${cmd%%-*}
        ns=${2:-default}
        for chart in $(all_charts); do
            run_helm "$action" "$chart" "$ns"
        done
        ;;
    *)
        usage
        ;;
esac
