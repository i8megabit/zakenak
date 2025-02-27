#!/usr/bin/bash
#   _____ _                _       
#  / ____| |              | |      
# | |    | |__   __ _ _ __| |_ ___ 
# | |    | '_ \ / _` | '__| __/ __|
# | |____| | | | (_| | |  | |_\__ \
#  \_____|_| |_|\__,_|_|   \__|___/
#                         by @eberil
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# Helm Charts Management Tool
# Version: 1.2.0
#
# HUJAK-HUJAK PRODUCTION PRESENTS...
# "Because managing charts shouldn't be a pain"

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
K8S_KIND_SETUP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CHARTS_DIR="${TOOLS_DIR}/../helm-charts"

# Загрузка общих переменных
source "${K8S_KIND_SETUP_DIR}/env/src/env.sh"

# Загрузка функций из setup-ingress.sh
if [ -f "${K8S_KIND_SETUP_DIR}/setup-ingress/src/setup-ingress.sh" ]; then
    # Create a more selective temporary copy of the script
    # Only include the function definition and export
    awk '/^toggle_ingress_webhook\(\)/,/^export -f toggle_ingress_webhook/ {print}' "${K8S_KIND_SETUP_DIR}/setup-ingress/src/setup-ingress.sh" > /tmp/setup-ingress-functions.sh
    
    # Add necessary environment variables at the beginning
    sed -i '1i#!/usr/bin/bash\n' /tmp/setup-ingress-functions.sh
    sed -i '2i# Environment variables\n' /tmp/setup-ingress-functions.sh
    sed -i '3iexport NAMESPACE_INGRESS="ingress-nginx"\n' /tmp/setup-ingress-functions.sh
    sed -i '4i# Color definitions\n' /tmp/setup-ingress-functions.sh
    sed -i '5iexport RED="\\033[0;31m"\n' /tmp/setup-ingress-functions.sh
    sed -i '6iexport GREEN="\\033[0;32m"\n' /tmp/setup-ingress-functions.sh
    sed -i '7iexport YELLOW="\\033[1;33m"\n' /tmp/setup-ingress-functions.sh
    sed -i '8iexport CYAN="\\033[0;36m"\n' /tmp/setup-ingress-functions.sh
    sed -i '9iexport NC="\\033[0m"\n' /tmp/setup-ingress-functions.sh
    
    # Ensure the temporary file is executable
    chmod +x /tmp/setup-ingress-functions.sh
    
    # Source the temporary file
    source /tmp/setup-ingress-functions.sh
    
    # Clean up
    rm -f /tmp/setup-ingress-functions.sh
fi

# Функция получения списка чартов
get_charts() {
	local charts=()
	for chart_dir in "${CHARTS_DIR}"/*; do
		if [ -f "${chart_dir}/Chart.yaml" ]; then
			charts+=("$(basename "${chart_dir}")")
		fi
	done
	echo "${charts[@]}"
}

# Функция генерации цветного меню чартов
generate_charts_menu() {
	local charts=($1)
	echo -e "${CYAN}Доступные чарты:${NC}"
	echo -e "${GREEN}  all          ${YELLOW}-${NC} Все чарты"
	for chart in "${charts[@]}"; do
		local description=""
		if [ -f "${CHARTS_DIR}/${chart}/Chart.yaml" ]; then
			description=$(grep "description:" "${CHARTS_DIR}/${chart}/Chart.yaml" | cut -d'"' -f2 || echo "")
		fi
		printf "${GREEN}  %-12s ${YELLOW}-${NC} %s\n" "$chart" "${description:-$chart}"
	done
}

# Charts Banner
charts_banner() {
	echo -e "${BLUE}"
	cat << "EOF"
   ██████╗██╗  ██╗ █████╗ ██████╗ ████████╗███████╗
  ██╔════╝██║  ██║██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
  ██║     ███████║███████║██████╔╝   ██║   ███████╗
  ██║     ██╔══██║██╔══██║██╔══██╗   ██║   ╚════██║
  ╚██████╗██║  ██║██║  ██║██║  ██║   ██║   ███████║
   ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
EOF
	echo -e "${NC}"
	echo "Copyright (c) 2023-2025 Mikhail Eberil (@eberil)"
	echo "\"Because managing charts shouldn't be a pain\""
}




# Функция перезапуска CoreDNS
restart_coredns() {
	echo -e "${CYAN}Перезапуск CoreDNS...${NC}"

	# Проверка текущего состояния
	echo -e "${CYAN}Текущее состояние CoreDNS:${NC}"
	kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide
	kubectl describe deployment coredns -n kube-system

	# Применение обновленной конфигурации
	echo -e "${CYAN}Применение конфигурации CoreDNS...${NC}"
	# First check if the ConfigMap exists
	if kubectl get configmap coredns -n kube-system &>/dev/null; then
		# If it exists, get the current ConfigMap and save it to a temporary file
		kubectl get configmap coredns -n kube-system -o yaml > /tmp/coredns-current.yaml
		
		# Apply the new configuration with --force flag to replace the existing ConfigMap
		kubectl apply -f "${K8S_KIND_SETUP_DIR}/setup-dns/src/coredns-custom.yaml" --force
	else
		# If it doesn't exist, create it with --save-config to ensure the annotation is set
		kubectl apply -f "${K8S_KIND_SETUP_DIR}/setup-dns/src/coredns-custom.yaml" --save-config
	fi

	# Перезапуск CoreDNS
	kubectl rollout restart deployment/coredns -n kube-system
	
	# Ждем немного дольше для полной синхронизации
	echo -e "${CYAN}Ожидание перезапуска подов CoreDNS...${NC}"
	sleep 20

	echo -e "${CYAN}Ожидание готовности CoreDNS...${NC}"
	if ! kubectl rollout status deployment/coredns -n kube-system --timeout=300s; then
		echo -e "${RED}Ошибка при ожидании готовности CoreDNS${NC}"
		echo -e "${YELLOW}Проверка логов новых подов...${NC}"
		kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50 || true
		echo -e "${YELLOW}Описание подов...${NC}"
		kubectl describe pods -n kube-system -l k8s-app=kube-dns
		exit 1
	fi

	# Проверка резолвинга с более подробной диагностикой
	echo -e "${CYAN}Проверка DNS резолвинга...${NC}"
	echo -e "${CYAN}Тестирование резолвинга dashboard.prod.local...${NC}"

	# Создаем под для тестирования DNS
	cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: dnsutils
  namespace: default
spec:
  containers:
  - name: dnsutils
    image: gcr.io/kubernetes-e2e-test-images/dnsutils:1.3
    command:
      - sleep
      - "3600"
EOF

	# Ждем, пока под будет готов
	kubectl wait --for=condition=ready pod/dnsutils --timeout=60s

	# Выполняем тесты DNS
	echo -e "${CYAN}Выполнение dig для dashboard.prod.local...${NC}"
	kubectl exec -i dnsutils -- dig dashboard.prod.local

	echo -e "${CYAN}Выполнение nslookup для dashboard.prod.local...${NC}"
	kubectl exec -i dnsutils -- nslookup dashboard.prod.local

	# Проверяем локальное разрешение
	echo -e "${CYAN}Проверка локального разрешения имен...${NC}"
	kubectl exec -i dnsutils -- cat /etc/resolv.conf

	# Удаляем тестовый под
	kubectl delete pod dnsutils --grace-period=0 --force

	# Проверяем конфигурацию CoreDNS
	echo -e "${CYAN}Проверка конфигурации CoreDNS...${NC}"
	kubectl get configmap coredns -n kube-system -o yaml

	# Финальная проверка
	echo -e "${CYAN}Финальное состояние CoreDNS:${NC}"
	kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide

	echo -e "${GREEN}CoreDNS успешно перезапущен${NC}"
}

# Функция проверки эндпоинтов чарта
check_chart_endpoints() {
	local chart=$1
	local namespace=$2
	local max_attempts=30
	local attempt=1
	local ready=false

	echo -e "${CYAN}Проверка эндпоинтов для чарта ${chart} в namespace ${namespace}...${NC}"
	
	# Для nvidia-device-plugin не проверяем эндпоинты, так как это DaemonSet
	if [ "$chart" = "nvidia-device-plugin" ]; then
		echo -e "${CYAN}Проверка статуса DaemonSet для ${chart}...${NC}"
		if kubectl rollout status daemonset/nvidia-device-plugin-daemonset -n kube-system --timeout=60s &>/dev/null; then
			echo -e "${GREEN}DaemonSet ${chart} готов${NC}"
			return 0
		else
			echo -e "${YELLOW}DaemonSet ${chart} запущен, но может быть не полностью готов${NC}"
			echo -e "${CYAN}Это нормально для GPU-окружений в процессе инициализации${NC}"
			return 0
		fi
	fi

	# Получаем список всех сервисов чарта
	local services=($(kubectl get services -n "${namespace}" -l "app.kubernetes.io/instance=${chart}" -o name 2>/dev/null))
	
	if [ ${#services[@]} -eq 0 ]; then
		echo -e "${YELLOW}Сервисы для чарта ${chart} не найдены${NC}"
		return 0
	fi

	while [ $attempt -le $max_attempts ]; do
		echo -e "${CYAN}Проверка готовности сервисов (попытка $attempt/$max_attempts)...${NC}"
		ready=true

		for service in "${services[@]}"; do
			local service_name=$(basename "$service")
			echo -e "${CYAN}Проверка сервиса ${service_name}...${NC}"

			# Проверяем наличие эндпоинтов
			if ! kubectl get endpoints -n "${namespace}" "${service_name}" -o json | grep -q '"addresses":\[{'; then
				echo -e "${YELLOW}Эндпоинты для ${service_name} не готовы${NC}"
				ready=false
				break
			fi

			# Проверяем готовность подов, связанных с сервисом
			local selector=$(kubectl get service -n "${namespace}" "${service_name}" -o jsonpath='{.spec.selector}' 2>/dev/null)
			if [ -n "$selector" ]; then
				if ! kubectl wait --namespace "${namespace}" --for=condition=ready pod \
					--selector="$selector" --timeout=10s >/dev/null 2>&1; then
					echo -e "${YELLOW}Поды для ${service_name} не готовы${NC}"
					ready=false
					break
				fi
			fi
		done

		if [ "$ready" = true ]; then
			echo -e "${GREEN}Все сервисы чарта ${chart} готовы${NC}"
			return 0
		fi

		attempt=$((attempt + 1))
		sleep 10
	done

	echo -e "${RED}Превышено время ожидания готовности сервисов чарта ${chart}${NC}"
	echo -e "${YELLOW}Текущее состояние сервисов:${NC}"
	kubectl get services,endpoints,pods -n "${namespace}" -l "app.kubernetes.io/instance=${chart}"
	return 1
}

# Функция настройки GPU
setup_gpu() {
    local namespace=$1
    echo -e "${CYAN}Настройка GPU для namespace ${namespace}...${NC}"
    
    # Динамическое определение версии драйвера
    local driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null)
    if [ -z "$driver_version" ]; then
        echo -e "${RED}Ошибка: NVIDIA драйвер не найден${NC}"
        return 1
    fi
    
    # Проверка NVIDIA Container Toolkit
    if ! docker run --rm --gpus all nvidia/cuda:12.6.1-base-ubuntu22.04 nvidia-smi &>/dev/null; then
        echo -e "${RED}Ошибка: NVIDIA Container Toolkit не настроен${NC}"
        return 1
    fi
    
    # Динамическое определение доступной GPU памяти
    local gpu_memory=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader | head -n1 | cut -d' ' -f1)
    local gpu_memory_limit=$(( gpu_memory * 90 / 100 )) # 90% от доступной памяти
    
    # Создание ConfigMap с динамическими параметрами GPU
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: gpu-config
  namespace: $namespace
data:
  NVIDIA_DRIVER_VERSION: "$driver_version"
  CUDA_VERSION: "12.6.1"
  NVIDIA_VISIBLE_DEVICES: "all"
  NVIDIA_DRIVER_CAPABILITIES: "compute,utility"
  GPU_MEMORY_LIMIT: "${gpu_memory_limit}Mi"
  GPU_MEMORY_UTILIZATION: "0.9"
  TENSOR_PARALLEL: "true"
  FLASH_ATTENTION: "true"
  KV_CACHE_STRATEGY: "dynamic"
EOF
    
    echo -e "${GREEN}GPU успешно настроен для namespace ${namespace}${NC}"
    return 0
}

# Функция установки/обновления чарта
install_chart() {
	local action=$1
	local chart=$2
	local namespace=${3:-$NAMESPACE_PROD}
	local version=$4
	local values_file=$5
	
	# Setup GPU for charts that need it
	case "$chart" in
		"ollama"|"open-webui")
			if ! setup_gpu "$namespace"; then
				echo -e "${RED}Ошибка при настройке GPU для чарта ${chart}${NC}"
				exit 1
			fi
			;;
	esac
	
	# Обработка алиасов чартов
	case "$chart" in
		"dashboard")
			chart="kubernetes-dashboard"
			;;
		"coredns")
			chart="coredns"
			restart_coredns
			;;
		"ingress-nginx")
			chart="ingress-nginx"
			;;
		"nvidia-device-plugin")
			chart="nvidia-device-plugin"
			;;
		*)
			;;
	esac
	
	if [ ! -d "${CHARTS_DIR}/${chart}" ]; then
		if declare -F error_banner >/dev/null; then
			error_banner "Чарт ${chart} не найден"
		fi
		echo -e "${RED}Ошибка: Чарт ${chart} не найден${NC}"
		exit 1
	fi

	# Показываем соответствующий баннер для чарта
	case "$chart" in
		"cert-manager")
			if declare -F cert_manager_banner >/dev/null; then
				cert_manager_banner
			fi
			;;
		"local-ca")
			if declare -F local_ca_banner >/dev/null; then
				local_ca_banner
			fi
			;;
		"kubernetes-dashboard")
			if declare -F dashboard_banner >/dev/null; then
				dashboard_banner
			fi
			;;
		"nginx-ingress")
			if declare -F nginx_ingress_banner >/dev/null; then
				nginx_ingress_banner
			fi
			;;
		"coredns")
			if declare -F coredns_banner >/dev/null; then
				coredns_banner
			fi
			;;
		"prometheus")
			if declare -F prometheus_banner >/dev/null; then
				prometheus_banner
			fi
			;;
		"grafana")
			if declare -F grafana_banner >/dev/null; then
				grafana_banner
			fi
			;;
		"ingress")
			if declare -F ingress_banner >/dev/null; then
				ingress_banner
			fi
			;;
		"ollama")
			if declare -F ollama_banner >/dev/null; then
				ollama_banner
			fi
			;;
		"open-webui")
			if declare -F open_webui_banner >/dev/null; then
				open_webui_banner
			fi
			;;
		"sidecar-injector")
			if declare -F sidecar_injector_banner >/dev/null; then
				sidecar_injector_banner
			fi
			;;
	esac

	# Удаляем существующий релиз только при install
	if [ "$action" = "install" ]; then
		echo -e "${CYAN}Проверка существующего релиза ${chart}...${NC}"
		helm uninstall ${chart} -n ${namespace} 2>/dev/null || true
		# Ждем удаления релиза
		sleep 5
	fi

	# Специальная обработка для local-ca
	if [ "$chart" = "local-ca" ] && [ "$action" = "install" ]; then
		echo -e "${CYAN}Подготовка к установке local-ca...${NC}"
		
		# Показываем баннер local-ca
		if declare -F local_ca_banner >/dev/null; then
			local_ca_banner
		fi
		
		# Удаляем существующий релиз если он есть
		helm uninstall local-ca -n ${namespace} 2>/dev/null || true
		
		# Ждем удаления релиза
		sleep 5
		
		# Удаляем существующие сертификаты и их секреты
		kubectl delete certificate -n ${namespace} --all 2>/dev/null || true
		kubectl delete secret -n ${namespace} ollama-tls 2>/dev/null || true
		
		# Ждем полного удаления ресурсов
		sleep 5
	fi

	# Специальная обработка для cert-manager
	if [ "$chart" = "cert-manager" ]; then
		echo -e "${CYAN}Подготовка к установке cert-manager...${NC}"
		
		# Проверяем существование релиза перед upgrade

		if [ "$action" = "upgrade" ] && ! helm status cert-manager -n cert-manager >/dev/null 2>&1; then
			echo -e "${YELLOW}Релиз cert-manager не найден, выполняем установку...${NC}"
			action="install"
		fi
		
		# Если это установка, выполняем полную очистку
		if [ "$action" = "install" ]; then
			# Удаляем существующий релиз cert-manager если он есть
			helm uninstall cert-manager -n cert-manager 2>/dev/null || true
			
			# Ждем удаления релиза
			sleep 10
			
			# Удаляем namespace если он существует
			kubectl delete namespace cert-manager --timeout=60s 2>/dev/null || true
			
			# Принудительно удаляем все CRD cert-manager
			for crd in $(kubectl get crd -o name | grep cert-manager 2>/dev/null || true); do
				kubectl patch $crd -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
				kubectl delete $crd --timeout=60s --force --grace-period=0 2>/dev/null || true
			done
			
			# Ждем полного удаления ресурсов
			sleep 10
		fi
		
		# Проверяем наличие репозитория jetstack
		if ! helm repo list | grep -q "jetstack"; then
			echo -e "${CYAN}Добавление репозитория cert-manager...${NC}"
			helm repo add jetstack https://charts.jetstack.io
			helm repo update
		fi

		# Устанавливаем в правильный namespace
		namespace="cert-manager"

		# Устанавливаем CRD напрямую из репозитория
		echo -e "${CYAN}Установка CRD для cert-manager...${NC}"
		kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml || {
			echo -e "${RED}Ошибка при установке CRD для cert-manager${NC}"
			exit 1
		}

		# Добавляем метки и аннотации Helm для CRD
		for crd in $(kubectl get crd -o name | grep cert-manager 2>/dev/null || true); do
			echo -e "${CYAN}Настройка меток и аннотаций для ${crd}...${NC}"
			kubectl patch $crd -p '{
				"metadata": {
					"labels": {
						"app.kubernetes.io/managed-by": "Helm"
					},
					"annotations": {
						"meta.helm.sh/release-name": "cert-manager",
						"meta.helm.sh/release-namespace": "cert-manager"
					}
				}
			}' --type=merge || true
		done

		# Ждем готовности CRD с проверкой их наличия
		echo -e "${CYAN}Ожидание готовности CRD cert-manager...${NC}"
		local crds=(
			"certificates.cert-manager.io"
			"challenges.acme.cert-manager.io"
			"clusterissuers.cert-manager.io"
			"issuers.cert-manager.io"
			"orders.acme.cert-manager.io"
			"certificaterequests.cert-manager.io"
		)
		
		for crd in "${crds[@]}"; do
			echo -e "${CYAN}Ожидание готовности CRD ${crd}...${NC}"
			local retries=0
			while [ $retries -lt 30 ]; do
				if kubectl get crd $crd >/dev/null 2>&1; then
					if kubectl wait --for=condition=established --timeout=10s crd/$crd >/dev/null 2>&1; then
						echo -e "${GREEN}CRD ${crd} готов${NC}"
						break
					fi
				fi
				retries=$((retries + 1))
				sleep 2
			done
			if [ $retries -eq 30 ]; then
				echo -e "${RED}Превышено время ожидания готовности CRD ${crd}${NC}"
				exit 1
			fi
		done
	fi

	# Проверяем наличие репозитория kubernetes-dashboard для чарта kubernetes-dashboard
	if [ "$chart" = "kubernetes-dashboard" ] && ! helm repo list | grep -q "kubernetes-dashboard"; then
		echo -e "${CYAN}Добавление репозитория kubernetes-dashboard...${NC}"
		helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
		helm repo update
	fi

	# Специальная обработка для kubernetes-dashboard
	if [ "$chart" = "kubernetes-dashboard" ]; then
		echo -e "${CYAN}Подготовка к установке kubernetes-dashboard...${NC}"
		
		# Проверяем существование релиза перед upgrade

		if [ "$action" = "upgrade" ] && ! helm status kubernetes-dashboard -n kubernetes-dashboard >/dev/null 2>&1; then
			echo -e "${YELLOW}Релиз kubernetes-dashboard не найден, выполняем установку...${NC}"
			action="install"
		fi
		
		# Если это установка, выполняем полную очистку
		if [ "$action" = "install" ]; then
			# Удаляем существующий релиз если он есть
			helm uninstall kubernetes-dashboard -n kubernetes-dashboard 2>/dev/null || true
			
			# Ждем удаления релиза
			sleep 10
			
			# Удаляем namespace если он существует
			kubectl delete namespace kubernetes-dashboard --timeout=60s 2>/dev/null || true
			
			# Ждем полного удаления ресурсов
			sleep 10
		fi

		# Устанавливаем в правильный namespace
		namespace="kubernetes-dashboard"

		# Отключаем валидационный вебхук ingress-nginx перед установкой dashboard
		if type toggle_ingress_webhook &>/dev/null; then
			echo -e "${CYAN}Отключение валидационного вебхука ingress-nginx перед установкой dashboard...${NC}"
			toggle_ingress_webhook "disable" || {
				echo -e "${YELLOW}Предупреждение: Не удалось отключить вебхук, продолжаем установку...${NC}"
			}
		else
			echo -e "${YELLOW}Функция toggle_ingress_webhook не найдена, пропускаем отключение вебхука${NC}"
		fi
		
		# Применяем конфигурацию admin-user для доступа к дашборду
		if [ "$action" = "install" ]; then
			echo -e "${CYAN}Применение конфигурации admin-user для доступа к dashboard...${NC}"
			kubectl apply -f "${SCRIPT_DIR}/kubernetes-dashboard/admin-user.yaml"
		fi

	fi

	# Добавляем сборку зависимостей перед установкой
	echo -e "${CYAN}Проверка и сборка зависимостей чарта ${chart}...${NC}"
	helm dependency build "${CHARTS_DIR}/${chart}" || {
		echo -e "${RED}Ошибка при сборке зависимостей чарта ${chart}${NC}"
		exit 1
	}
	
	local helm_cmd="helm ${action} ${chart} ${CHARTS_DIR}/${chart}"
	helm_cmd+=" --namespace ${namespace}"
	# Add --create-namespace flag only for install and upgrade actions
	if [ "$action" = "install" ] || [ "$action" = "upgrade" ]; then
		helm_cmd+=" --create-namespace"
	fi
	
	[ -n "$version" ] && helm_cmd+=" --version ${version}"
	[ -n "$values_file" ] && helm_cmd+=" -f ${values_file}"

	# Для cert-manager добавляем таймаут установки
	if [ "$chart" = "cert-manager" ]; then
		helm_cmd+=" --timeout 5m"
	fi

	
	echo -e "${CYAN}Выполняется ${action} чарта ${chart}...${NC}"
	eval $helm_cmd
	
	# Дополнительное ожидание готовности CRD для cert-manager
	if [ "$chart" = "cert-manager" ] && [ $? -eq 0 ]; then
		echo -e "${CYAN}Ожидание готовности CRD cert-manager...${NC}"
		sleep 30
	fi
	
	if [ $? -eq 0 ]; then
		# Проверяем эндпоинты только для install и upgrade
		if [ "$action" = "install" ] || [ "$action" = "upgrade" ]; then
			if ! check_chart_endpoints "$chart" "$namespace"; then
				echo -e "${RED}Ошибка при проверке эндпоинтов чарта ${chart}${NC}"
				exit 1
			fi
		fi

		echo -e "\n"
		if declare -F success_banner >/dev/null; then
			success_banner "Операция успешно выполнена"
		else
			echo -e "${GREEN}Успешно!${NC}"
		fi
		echo -e "\n${GREEN}${action^} чарта ${chart} успешно завершен${NC}"
	else
		echo -e "\n"
		if declare -F error_banner >/dev/null; then
			error_banner "Произошла ошибка при выполнении операции"
		else
			echo -e "${RED}Ошибка!${NC}"
		fi
		echo -e "\n${RED}Ошибка при выполнении ${action} чарта ${chart}${NC}"
		exit 1
	fi
}

# Функция переустановки ingress-контроллера
reinstall_ingress() {
	echo -e "${CYAN}Переустановка ingress-контроллера...${NC}"

	# Удаление существующего ingress-контроллера
	echo -e "${CYAN}Удаление существующего ingress-контроллера...${NC}"
	helm uninstall ingress-nginx -n ingress-nginx 2>/dev/null || true
	
	# Удаляем namespace и ждем его полного удаления
	echo -e "${CYAN}Удаление namespace ingress-nginx...${NC}"
	kubectl delete namespace ingress-nginx --timeout=60s 2>/dev/null || true
	
	# Ждем полного удаления namespace
	echo -e "${CYAN}Ожидание удаления namespace...${NC}"
	while kubectl get namespace ingress-nginx >/dev/null 2>&1; do
		echo -e "${YELLOW}Namespace все еще удаляется, ожидание...${NC}"
		sleep 5
	done

	# Дополнительная пауза для уверенности
	sleep 10

	# Создание нового namespace
	echo -e "${CYAN}Создание namespace ingress-nginx...${NC}"
	kubectl create namespace ingress-nginx

	# Добавление репозитория если его нет
	if ! helm repo list | grep -q "ingress-nginx"; then
		echo -e "${CYAN}Добавление репозитория ingress-nginx...${NC}"
		helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
		helm repo update
	fi

	# Установка ingress-контроллера с конфигурацией
	echo -e "${CYAN}Установка ingress-контроллера...${NC}"
	if ! helm upgrade --install ingress-nginx ingress-nginx \
		--repo https://kubernetes.github.io/ingress-nginx \
		--namespace ingress-nginx \
		--values "${K8S_KIND_SETUP_DIR}/setup-ingress/src/ingress-config.yaml" \
		--timeout 5m; then
		echo -e "${RED}Ошибка при установке ingress-контроллера${NC}"
		return 1
	fi

	# Улучшенная проверка готовности ingress-контроллера
	echo -e "${CYAN}Ожидание готовности ingress-контроллера...${NC}"
	local max_attempts=30
	local attempt=1
	local ready=false

	while [ $attempt -le $max_attempts ]; do
		echo -e "${CYAN}Проверка готовности (попытка $attempt/$max_attempts)...${NC}"
		
		# Проверка статуса пода
		if kubectl wait --namespace ingress-nginx \
			--for=condition=ready pod \
			--selector=app.kubernetes.io/component=controller \
			--timeout=30s >/dev/null 2>&1; then
			
			# Проверка доступности сервиса
			if kubectl get service ingress-nginx-controller -n ingress-nginx >/dev/null 2>&1; then
				# Проверка наличия endpoints
				if kubectl get endpoints ingress-nginx-controller -n ingress-nginx -o json | grep -q '"addresses":\[{'; then
					ready=true
					break
				fi
			fi
		fi

		attempt=$((attempt + 1))
		sleep 10
	done

	if [ "$ready" = true ]; then
		echo -e "${GREEN}Ingress-контроллер успешно установлен и готов${NC}"
		# Вывод информации о состоянии
		echo -e "${CYAN}Статус подов:${NC}"
		kubectl get pods -n ingress-nginx
		echo -e "${CYAN}Статус сервисов:${NC}"
		kubectl get svc -n ingress-nginx
		return 0
	else
		echo -e "${RED}Ошибка при переустановке ingress-контроллера${NC}"
		echo -e "${YELLOW}Проверка статуса подов:${NC}"
		kubectl get pods -n ingress-nginx
		echo -e "${YELLOW}Проверка сервисов:${NC}"
		kubectl get svc -n ingress-nginx
		echo -e "${YELLOW}Проверка событий в namespace:${NC}"
		kubectl get events -n ingress-nginx --sort-by=.metadata.creationTimestamp
		return 1
	fi
}

# Функция переустановки nvidia-device-plugin-daemonset
reinstall_nvidia_device_plugin() {
	echo -e "${CYAN}Переустановка NVIDIA Device Plugin...${NC}"
	
	# Удаление существующего DaemonSet
	kubectl delete daemonset nvidia-device-plugin-daemonset -n kube-system --ignore-not-found=true
	
	# Ожидание удаления
	echo -e "${CYAN}Ожидание удаления старого DaemonSet...${NC}"
	while kubectl get daemonset nvidia-device-plugin-daemonset -n kube-system &>/dev/null; do
		sleep 2
	done
	
	# Установка нового DaemonSet
	echo -e "${CYAN}Установка нового DaemonSet...${NC}"
	install_chart "install" "nvidia-device-plugin" "kube-system"
	
	echo -e "${GREEN}NVIDIA Device Plugin успешно переустановлен${NC}"
}

# Функция перезапуска подов чарта
restart_chart_pods() {
	local chart=$1
	local namespace=${2:-$NAMESPACE_PROD}
	
	echo -e "${CYAN}Перезапуск подов для чарта ${chart} в namespace ${namespace}...${NC}"
	
	case $chart in
		"ingress-nginx"|"ingress-controller")
			echo -e "${CYAN}Перезапуск ingress-controller...${NC}"
			kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx
			kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx
			;;
		"cert-manager")
			echo -e "${CYAN}Перезапуск cert-manager...${NC}"
			kubectl rollout restart deployment cert-manager -n cert-manager
			kubectl rollout restart deployment cert-manager-webhook -n cert-manager
			kubectl rollout restart deployment cert-manager-cainjector -n cert-manager
			kubectl rollout status deployment cert-manager -n cert-manager
			kubectl rollout status deployment cert-manager-webhook -n cert-manager
			kubectl rollout status deployment cert-manager-cainjector -n cert-manager
			;;
		"kubernetes-dashboard")
			echo -e "${CYAN}Перезапуск kubernetes-dashboard...${NC}"
			kubectl rollout restart deployment kubernetes-dashboard -n kubernetes-dashboard
			kubectl rollout status deployment kubernetes-dashboard -n kubernetes-dashboard
			;;
		"ollama")
			echo -e "${CYAN}Перезапуск ollama...${NC}"
			kubectl rollout restart deployment ollama -n $namespace
			kubectl rollout status deployment ollama -n $namespace
			;;
		"open-webui")
			echo -e "${CYAN}Перезапуск open-webui...${NC}"
			kubectl rollout restart deployment open-webui -n $namespace
			kubectl rollout status deployment open-webui -n $namespace
			;;
		"sidecar-injector")
			echo -e "${CYAN}Перезапуск sidecar-injector...${NC}"
			kubectl rollout restart deployment sidecar-injector -n $namespace
			kubectl rollout status deployment sidecar-injector -n $namespace
			;;
		"all")
			echo -e "${CYAN}Перезапуск всех подов...${NC}"
			# Перезапуск системных компонентов
			kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx
			kubectl rollout restart deployment cert-manager -n cert-manager
			kubectl rollout restart deployment cert-manager-webhook -n cert-manager
			kubectl rollout restart deployment cert-manager-cainjector -n cert-manager
			kubectl rollout restart deployment kubernetes-dashboard -n kubernetes-dashboard
			
			# Перезапуск пользовательских приложений
			kubectl rollout restart deployment ollama -n $namespace
			kubectl rollout restart deployment open-webui -n $namespace
			kubectl rollout restart deployment sidecar-injector -n $namespace
			
			# Проверка статуса
			kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx
			kubectl rollout status deployment cert-manager -n cert-manager
			kubectl rollout status deployment cert-manager-webhook -n cert-manager
			kubectl rollout status deployment cert-manager-cainjector -n cert-manager
			kubectl rollout status deployment kubernetes-dashboard -n kubernetes-dashboard
			kubectl rollout status deployment ollama -n $namespace
			kubectl rollout status deployment open-webui -n $namespace
			kubectl rollout status deployment sidecar-injector -n $namespace
			;;
		*)
			echo -e "${YELLOW}Попытка автоматического определения ресурсов для чарта ${chart}...${NC}"
			# Попытка найти все deployments с меткой чарта
			local deployments=$(kubectl get deployments -n $namespace -l "app.kubernetes.io/instance=${chart}" -o name 2>/dev/null)
			local daemonsets=$(kubectl get daemonsets -n $namespace -l "app.kubernetes.io/instance=${chart}" -o name 2>/dev/null)
			local statefulsets=$(kubectl get statefulsets -n $namespace -l "app.kubernetes.io/instance=${chart}" -o name 2>/dev/null)
			
			if [ -z "$deployments" ] && [ -z "$daemonsets" ] && [ -z "$statefulsets" ]; then
				echo -e "${RED}Не найдены ресурсы для перезапуска чарта ${chart}${NC}"
				return 1
			fi
			
			# Перезапуск найденных ресурсов
			for deployment in $deployments; do
				echo -e "${CYAN}Перезапуск $deployment...${NC}"
				kubectl rollout restart $deployment -n $namespace
				kubectl rollout status $deployment -n $namespace
			done
			
			for daemonset in $daemonsets; do
				echo -e "${CYAN}Перезапуск $daemonset...${NC}"
				kubectl rollout restart $daemonset -n $namespace
				kubectl rollout status $daemonset -n $namespace
			done
			
			for statefulset in $statefulsets; do
				echo -e "${CYAN}Перезапуск $statefulset...${NC}"
				kubectl rollout restart $statefulset -n $namespace
				kubectl rollout status $statefulset -n $namespace
			done
			;;
	esac
	
	echo -e "${GREEN}Перезапуск подов для чарта ${chart} завершен${NC}"
}

# Функция получения токена для доступа к dashboard
get_dashboard_token() {
	local namespace="kubernetes-dashboard"
	local account="admin-user"
	
	echo -e "${CYAN}Получение токена для доступа к dashboard...${NC}"
	
	# Проверяем установлен ли dashboard
	if ! helm status kubernetes-dashboard -n $namespace >/dev/null 2>&1; then
		if declare -F error_banner >/dev/null; then
			error_banner "kubernetes-dashboard не установлен"
		fi
		echo -e "${RED}Ошибка: kubernetes-dashboard не установлен${NC}"
		echo -e "${YELLOW}Для установки выполните:${NC}"
		echo -e "${CYAN}$0 install kubernetes-dashboard${NC}"
		return 1
	fi
	
	# Проверяем существование ServiceAccount
	if ! kubectl get serviceaccount $account -n $namespace >/dev/null 2>&1; then
		if declare -F error_banner >/dev/null; then
			error_banner "ServiceAccount ${account} не найден в namespace ${namespace}"
		fi
		echo -e "${RED}Ошибка: ServiceAccount $account не найден в namespace $namespace${NC}"
		echo -e "${YELLOW}Попробуйте переустановить kubernetes-dashboard:${NC}"
		echo -e "${CYAN}$0 install kubernetes-dashboard${NC}"
		return 1
	fi
	
	# Ждем создания ServiceAccount
	echo -e "${CYAN}Ожидание создания ServiceAccount...${NC}"
	sleep 5

	# Получаем токен
	local token=""
	if kubectl -n $namespace get serviceaccount admin-user >/dev/null 2>&1; then
		token=$(kubectl -n $namespace create token admin-user)
	fi
	
	if [ -n "$token" ]; then
		if declare -F success_banner >/dev/null; then
			success_banner "Токен для доступа к dashboard получен"
		fi
		echo -e "${GREEN}Токен для доступа к dashboard:${NC}"
		echo -e "${YELLOW}$token${NC}"
		echo -e "\n${CYAN}Доступ к dashboard: ${GREEN}https://dashboard.prod.local${NC}"
		return 0
	else
		if declare -F error_banner >/dev/null; then
			error_banner "Не удалось получить токен для dashboard"
		fi
		echo -e "${RED}Не удалось получить токен${NC}"
		return 1
	fi
}

# Функция проверки корректности команды
check_action() {
    local action=$1
    local valid_actions=("install" "upgrade" "uninstall" "list" "restart-dns" "dashboard-token" "reinstall-ingress")
    
    # Проверяем совпадение с известными командами
    for valid_action in "${valid_actions[@]}"; do
        if [ "$action" = "$valid_action" ]; then
            return 0
        fi
    done
    
    # Если команда похожа на известную, предлагаем правильный вариант
    for valid_action in "${valid_actions[@]}"; do
        if [[ "$valid_action" == *"${action}"* ]] || [[ "${action}" == *"${valid_action}"* ]]; then
            if declare -F error_banner >/dev/null; then
                error_banner
            fi
            echo -e "${RED}Ошибка: Неизвестное действие '${action}'${NC}"
            echo -e "${YELLOW}Возможно, вы имели в виду: ${GREEN}${valid_action}${NC}"
            usage
        fi
    done
    
    # Если команда совсем не похожа на известные
    if declare -F error_banner >/dev/null; then
        error_banner
    fi
    echo -e "${RED}Ошибка: Неизвестное действие '${action}'${NC}"
    echo -e "${YELLOW}Доступные действия: install, upgrade, uninstall, list, restart-dns, dashboard-token, reinstall-ingress${NC}"
    usage
}

# Функция вывода справки
usage() {
	local charts=($(get_charts))
	
	echo -e "${CYAN}Использование:${NC} $0 ${YELLOW}[опции]${NC} ${GREEN}<действие>${NC} ${GREEN}<чарт>${NC}"
	echo ""
	echo -e "${CYAN}Действия:${NC}"
	echo -e "${GREEN}  install        ${YELLOW}-${NC} Установить чарт"
	echo -e "${GREEN}  upgrade        ${YELLOW}-${NC} Обновить чарт"
	echo -e "${GREEN}  uninstall      ${YELLOW}-${NC} Удалить чарт"
	echo -e "${GREEN}  list           ${YELLOW}-${NC} Показать список установленных чартов"
	echo -e "${GREEN}  restart-dns    ${YELLOW}-${NC} Перезапустить CoreDNS"
	echo -e "${GREEN}  dashboard-token ${YELLOW}-${NC} Получить токен для доступа к dashboard"
	echo -e "${GREEN}  reinstall-ingress ${YELLOW}-${NC} Переустановить ingress-контроллер"
	echo -e "${GREEN}  reinstall-nvidia-device-plugin ${YELLOW}-${NC} Переустановить NVIDIA Device Plugin"
	echo -e "${GREEN}  restart        ${YELLOW}-${NC} Перезапустить поды чарта"
	echo ""
	generate_charts_menu "$(get_charts)"
	echo ""
	echo -e "${CYAN}Опции:${NC}"
	echo -e "${GREEN}  -n, --namespace ${YELLOW}<namespace>${NC}  - Использовать указанный namespace"
	echo -e "${GREEN}  -v, --version ${YELLOW}<version>${NC}      - Использовать указанную версию"
	echo -e "${GREEN}  -f, --values ${YELLOW}<file>${NC}          - Использовать дополнительный values файл"
	echo -e "${GREEN}  -h, --help${NC}                   - Показать эту справку"
	exit 1
}

# Загрузка баннеров с предотвращением автозапуска
if [ -f "${K8S_KIND_SETUP_DIR}/ascii-banners/src/ascii_banners.sh" ]; then
	# Ensure SKIP_BANNER_MAIN is set to prevent ascii_banners.sh from processing arguments
	export SKIP_BANNER_MAIN=1
	
	# Source the ascii_banners.sh script without passing arguments
	source "${K8S_KIND_SETUP_DIR}/ascii-banners/src/ascii_banners.sh"
	
	# Unset SKIP_BANNER_MAIN to allow banner functions to work normally
	unset SKIP_BANNER_MAIN
fi

# Показываем баннер charts только если нет аргументов
if [ $# -eq 0 ]; then
	if declare -F charts_banner >/dev/null; then
		charts_banner
		echo ""
	fi
	usage
	exit 1
fi

# Функция перезапуска CoreDNS

restart_coredns() {
	echo -e "${CYAN}Перезапуск CoreDNS...${NC}"

	# Проверка текущего состояния
	echo -e "${CYAN}Текущее состояние CoreDNS:${NC}"
	kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide
	kubectl describe deployment coredns -n kube-system

	# Применение обновленной конфигурации
	echo -e "${CYAN}Применение конфигурации CoreDNS...${NC}"
	# First check if the ConfigMap exists
	if kubectl get configmap coredns -n kube-system &>/dev/null; then
		# If it exists, get the current ConfigMap and save it to a temporary file
		kubectl get configmap coredns -n kube-system -o yaml > /tmp/coredns-current.yaml
		
		# Apply the new configuration with --force flag to replace the existing ConfigMap
		kubectl apply -f "${K8S_KIND_SETUP_DIR}/setup-dns/src/coredns-custom.yaml" --force
	else
		# If it doesn't exist, create it with --save-config to ensure the annotation is set
		kubectl apply -f "${K8S_KIND_SETUP_DIR}/setup-dns/src/coredns-custom.yaml" --save-config
	fi

	# Перезапуск CoreDNS
	kubectl rollout restart deployment/coredns -n kube-system
	
	# Ждем немного дольше для полной синхронизации
	echo -e "${CYAN}Ожидание перезапуска подов CoreDNS...${NC}"
	sleep 20

	echo -e "${CYAN}Ожидание готовности CoreDNS...${NC}"
	if ! kubectl rollout status deployment/coredns -n kube-system --timeout=300s; then
		echo -e "${RED}Ошибка при ожидании готовности CoreDNS${NC}"
		echo -e "${YELLOW}Проверка логов новых подов...${NC}"
		kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50 || true
		echo -e "${YELLOW}Описание подов...${NC}"
		kubectl describe pods -n kube-system -l k8s-app=kube-dns
		exit 1
	fi

	# Проверка резолвинга
	echo -e "${CYAN}Проверка DNS резолвинга...${NC}"
	if ! kubectl run -it --rm --restart=Never --image=busybox:1.28 dns-test -- nslookup dashboard.prod.local; then
		echo -e "${YELLOW}Предупреждение: Проблемы с резолвингом dashboard.prod.local${NC}"
	fi

	# Финальная проверка
	echo -e "${CYAN}Финальное состояние CoreDNS:${NC}"
	kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide

	echo -e "${GREEN}CoreDNS успешно перезапущен${NC}"
}


# Функция получения списка чартов
get_charts() {
	local charts=()
	for chart_dir in "${CHARTS_DIR}"/*; do
		if [ -f "${chart_dir}/Chart.yaml" ]; then
			charts+=("$(basename "${chart_dir}")")
		fi
	done
	echo "${charts[@]}"
}


# Функция генерации цветного меню чартов
generate_charts_menu() {
	local charts=($1)
	echo -e "${CYAN}Доступные чарты:${NC}"
	echo -e "${GREEN}  all          ${YELLOW}-${NC} Все чарты"
	for chart in "${charts[@]}"; do
		local description=""
		if [ -f "${CHARTS_DIR}/${chart}/Chart.yaml" ]; then
			description=$(grep "description:" "${CHARTS_DIR}/${chart}/Chart.yaml" | cut -d'"' -f2 || echo "")
		fi
		printf "${GREEN}  %-12s ${YELLOW}-${NC} %s\n" "$chart" "${description:-$chart}"
	done
}




# Функция установки/обновления чарта
install_chart() {
	local action=$1
	local chart=$2
	local namespace=${3:-$NAMESPACE_PROD}
	local version=$4
	local values_file=$5
	
	# Показываем баннер для соответствующего чарта
	case "$chart" in
		"nginx-ingress")
			if declare -F nginx_ingress_banner >/dev/null; then
				nginx_ingress_banner
			fi
			;;
		"prometheus")
			if declare -F prometheus_banner >/dev/null; then
				prometheus_banner
			fi
			;;
		"grafana")
			if declare -F grafana_banner >/dev/null; then
				grafana_banner
			fi
			;;
		"ingress")
			if declare -F ingress_banner >/dev/null; then
				ingress_banner
			fi
			;;
		"coredns")
			if declare -F coredns_banner >/dev/null; then
				coredns_banner
			fi
			;;
		"ollama")
			if declare -F ollama_banner >/dev/null; then
				ollama_banner
			fi
			;;
		"open-webui")
			if declare -F open_webui_banner >/dev/null; then
				open_webui_banner
			fi
			;;
		"sidecar-injector")
			if declare -F sidecar_injector_banner >/dev/null; then
				sidecar_injector_banner
			fi
			;;
	esac

	if [ ! -d "${CHARTS_DIR}/${chart}" ]; then
		echo -e "${RED}Ошибка: Чарт ${chart} не найден${NC}"
		exit 1
	fi

	# Удаляем существующий релиз только при install
	if [ "$action" = "install" ]; then
		echo -e "${CYAN}Проверка существующего релиза ${chart}...${NC}"
		helm uninstall ${chart} -n ${namespace} 2>/dev/null || true
		# Ждем удаления релиза
		sleep 5
	fi

	# Специальная обработка для local-ca
	if [ "$chart" = "local-ca" ] && [ "$action" = "install" ]; then
		echo -e "${CYAN}Подготовка к установке local-ca...${NC}"
		
		# Удаляем существующий релиз если он есть
		helm uninstall local-ca -n ${namespace} 2>/dev/null || true
		
		# Ждем удаления релиза
		sleep 5
		
		# Функция для проверки существования ресурса
		check_resource_exists() {
			local resource_type=$1
			local resource_name=$2
			kubectl get $resource_type $resource_name -n ${namespace} &>/dev/null
			return $?
		}
		
		# Функция для удаления сертификата с повторными попытками
		delete_certificate() {
			local cert_name=$1
			local max_attempts=5
			local attempt=1
			
			echo -e "${CYAN}Обработка сертификата ${cert_name}...${NC}"
			
			while [ $attempt -le $max_attempts ]; do
				# Проверяем существование сертификата
				if ! kubectl get certificate $cert_name -n ${namespace} >/dev/null 2>&1; then
					echo -e "${GREEN}Сертификат ${cert_name} не существует или уже удален${NC}"
					return 0
				fi
				
				# Удаляем финализаторы и аннотации
				kubectl patch certificate $cert_name -n ${namespace} --type=json -p='[
					{"op": "remove", "path": "/metadata/finalizers"},
					{"op": "remove", "path": "/metadata/annotations"}
				]' 2>/dev/null || true
				
				# Удаляем связанные CertificateRequest
				for cr in $(kubectl get certificaterequest -n ${namespace} -o name | grep "^certificaterequest/${cert_name}-" 2>/dev/null); do
					kubectl patch $cr -n ${namespace} --type=json -p='[
						{"op": "remove", "path": "/metadata/finalizers"}
					]' 2>/dev/null || true
					kubectl delete $cr -n ${namespace} --force --grace-period=0 2>/dev/null || true
				done
				
				# Принудительно удаляем сертификат
				kubectl delete certificate $cert_name -n ${namespace} --force --grace-period=0 2>/dev/null
				
				# Проверяем статус сертификата после удаления
				sleep 2
				if kubectl get certificate $cert_name -n ${namespace} >/dev/null 2>&1; then
					# Если сертификат существует, проверяем, не был ли он пересоздан cert-manager'ом
					local age=$(kubectl get certificate $cert_name -n ${namespace} -o jsonpath='{.metadata.creationTimestamp}')
					local current_time=$(date -u +%s)
					local cert_time=$(date -u -d "$age" +%s)
					local time_diff=$((current_time - cert_time))
					
					if [ $time_diff -lt 10 ]; then
						echo -e "${CYAN}Сертификат ${cert_name} был автоматически пересоздан cert-manager'ом, добавляем аннотации Helm...${NC}"
						# Добавляем аннотации Helm для интеграции с релизом
						kubectl annotate certificate $cert_name -n ${namespace} \
							meta.helm.sh/release-name=local-ca \
							meta.helm.sh/release-namespace=${namespace} \
							--overwrite || true
						
						# Добавляем метку для управления через Helm
						kubectl label certificate $cert_name -n ${namespace} \
							app.kubernetes.io/managed-by=Helm \
							--overwrite || true
							
						echo -e "${GREEN}Сертификат ${cert_name} был успешно удален, пересоздан и аннотирован для Helm${NC}"
						return 0
					fi
				else
					echo -e "${GREEN}Сертификат ${cert_name} успешно удален${NC}"
					return 0
				fi
				
				attempt=$((attempt + 1))
				sleep 2
			done
			
			echo -e "${RED}Не удалось удалить сертификат ${cert_name} после $max_attempts попыток${NC}"
			return 1
		}
		
		echo -e "${CYAN}Удаление существующих сертификатов и секретов...${NC}"
		
		# Удаляем все сертификаты
		for cert in $(kubectl get certificate -n ${namespace} -o name 2>/dev/null | cut -d/ -f2); do
			echo -e "${CYAN}Обработка сертификата ${cert}...${NC}"
			if ! delete_certificate $cert; then
				echo -e "${RED}Ошибка: Не удалось удалить сертификат ${cert}${NC}"
				exit 1
			fi
		done
		
		# Удаляем все связанные секреты
		for secret in ollama-tls kubernetes-dashboard-tls webui-tls; do
			if kubectl get secret -n ${namespace} $secret &>/dev/null; then
				echo -e "${CYAN}Удаление секрета ${secret}...${NC}"
				kubectl delete secret $secret -n ${namespace} --force --grace-period=0
				
				# Проверяем удаление секрета
				if check_resource_exists secret $secret; then
					echo -e "${RED}Ошибка: Не удалось удалить секрет ${secret}${NC}"
					exit 1
				fi
			fi
		done
		
		# Ждем полного удаления ресурсов
		echo -e "${CYAN}Ожидание удаления ресурсов...${NC}"
		sleep 10
		
		# Финальная проверка
		if kubectl get certificates -n ${namespace} 2>/dev/null | grep -q "ollama-tls"; then
			# Проверяем время создания сертификата
			local age=$(kubectl get certificate ollama-tls -n ${namespace} -o jsonpath='{.metadata.creationTimestamp}')
			local current_time=$(date -u +%s)
			local cert_time=$(date -u -d "$age" +%s)
			local time_diff=$((current_time - cert_time))
			
			if [ $time_diff -lt 30 ]; then
				echo -e "${CYAN}Сертификат ollama-tls был автоматически пересоздан cert-manager'ом, добавляем аннотации Helm...${NC}"
				# Добавляем аннотации Helm для интеграции с релизом
				kubectl annotate certificate ollama-tls -n ${namespace} \
					meta.helm.sh/release-name=local-ca \
					meta.helm.sh/release-namespace=${namespace} \
					--overwrite || true
				
				# Добавляем метку для управления через Helm
				kubectl label certificate ollama-tls -n ${namespace} \
					app.kubernetes.io/managed-by=Helm \
					--overwrite || true
					
				echo -e "${GREEN}Сертификат ollama-tls был успешно пересоздан и аннотирован для Helm${NC}"
			else
				echo -e "${RED}Ошибка: Сертификат ollama-tls все еще существует${NC}"
				exit 1
			fi
		fi
	fi

	# Специальная обработка для cert-manager
	if [ "$chart" = "cert-manager" ]; then
		echo -e "${CYAN}Подготовка к установке cert-manager...${NC}"
		
		# Проверяем существование релиза перед upgrade
		if [ "$action" = "upgrade" ] && ! helm status cert-manager -n cert-manager >/dev/null 2>&1; then
			echo -e "${YELLOW}Релиз cert-manager не найден, выполняем установку...${NC}"
			action="install"
		fi
		
		# Если это установка, выполняем полную очистку
		if [ "$action" = "install" ]; then
			# Удаляем существующий релиз cert-manager если он есть
			helm uninstall cert-manager -n cert-manager 2>/dev/null || true
			
			# Ждем удаления релиза
			sleep 10
			
			# Удаляем namespace если он существует
			kubectl delete namespace cert-manager --timeout=60s 2>/dev/null || true
			
			# Принудительно удаляем все CRD cert-manager
			for crd in $(kubectl get crd -o name | grep cert-manager 2>/dev/null || true); do
				kubectl patch $crd -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
				kubectl delete $crd --timeout=60s --force --grace-period=0 2>/dev/null || true
			done
			
			# Ждем полного удаления ресурсов
			sleep 10
		fi
		
		# Проверяем наличие репозитория jetstack
		if ! helm repo list | grep -q "jetstack"; then
			echo -e "${CYAN}Добавление репозитория cert-manager...${NC}"
			helm repo add jetstack https://charts.jetstack.io
			helm repo update
		fi

		# Устанавливаем в правильный namespace
		namespace="cert-manager"

		# Устанавливаем CRD напрямую из репозитория
		echo -e "${CYAN}Установка CRD для cert-manager...${NC}"
		kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml || {
			echo -e "${RED}Ошибка при установке CRD для cert-manager${NC}"
			exit 1
		}

		# Добавляем метки и аннотации Helm для CRD
		for crd in $(kubectl get crd -o name | grep cert-manager 2>/dev/null || true); do
			echo -e "${CYAN}Настройка меток и аннотаций для ${crd}...${NC}"
			kubectl patch $crd -p '{
				"metadata": {
					"labels": {
						"app.kubernetes.io/managed-by": "Helm"
					},
					"annotations": {
						"meta.helm.sh/release-name": "cert-manager",
						"meta.helm.sh/release-namespace": "cert-manager"
					}
				}
			}' --type=merge || true
		done

		# Ждем готовности CRD с проверкой их наличия
		echo -e "${CYAN}Ожидание готовности CRD cert-manager...${NC}"
		local crds=(
			"certificates.cert-manager.io"
			"challenges.acme.cert-manager.io"
			"clusterissuers.cert-manager.io"
			"issuers.cert-manager.io"
			"orders.acme.cert-manager.io"
			"certificaterequests.cert-manager.io"
		)
		
		for crd in "${crds[@]}"; do
			echo -e "${CYAN}Ожидание готовности CRD ${crd}...${NC}"
			local retries=0
			while [ $retries -lt 30 ]; do
				if kubectl get crd $crd >/dev/null 2>&1; then
					if kubectl wait --for=condition=established --timeout=10s crd/$crd >/dev/null 2>&1; then
						echo -e "${GREEN}CRD ${crd} готов${NC}"
						break
					fi
				fi
				retries=$((retries + 1))
				sleep 2
			done
			if [ $retries -eq 30 ]; then
				echo -e "${RED}Превышено время ожидания готовности CRD ${crd}${NC}"
				exit 1
			fi
		done
	fi

	# Проверяем наличие репозитория kubernetes-dashboard для чарта kubernetes-dashboard
	if [ "$chart" = "kubernetes-dashboard" ] && ! helm repo list | grep -q "kubernetes-dashboard"; then
		echo -e "${CYAN}Добавление репозитория kubernetes-dashboard...${NC}"
		helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
		helm repo update
	fi

	# Специальная обработка для kubernetes-dashboard
	if [ "$chart" = "kubernetes-dashboard" ]; then
		echo -e "${CYAN}Подготовка к установке kubernetes-dashboard...${NC}"
		
		# Показываем баннер dashboard
		if declare -F dashboard_banner >/dev/null; then
			dashboard_banner
		fi
		
		# Проверяем существование релиза перед upgrade
		if [ "$action" = "upgrade" ] && ! helm status kubernetes-dashboard -n kubernetes-dashboard >/dev/null 2>&1; then
			echo -e "${YELLOW}Релиз kubernetes-dashboard не найден, выполняем установку...${NC}"
			action="install"
		fi
		
		# Если это установка, выполняем полную очистку
		if [ "$action" = "install" ]; then
			# Удаляем существующий релиз если он есть
			helm uninstall kubernetes-dashboard -n kubernetes-dashboard 2>/dev/null || true
			
			# Ждем удаления релиза
			sleep 10
			
			# Удаляем namespace если он существует
			kubectl delete namespace kubernetes-dashboard --timeout=60s 2>/dev/null || true
			
			# Ждем полного удаления ресурсов
			sleep 10
			
			# Создаем namespace
			echo -e "${CYAN}Создание namespace kubernetes-dashboard...${NC}"
			kubectl create namespace kubernetes-dashboard
			
			# Создаем ServiceAccount для доступа к дашборду
			echo -e "${CYAN}Создание ServiceAccount для доступа к dashboard...${NC}"
			kubectl create serviceaccount -n kubernetes-dashboard admin-user
			
			# Проверка и обновление ClusterRoleBinding
			echo -e "${CYAN}Проверка и обновление ClusterRoleBinding для admin-user...${NC}"
			if kubectl get clusterrolebinding admin-user &> /dev/null; then
				echo -e "${CYAN}Удаление существующего ClusterRoleBinding...${NC}"
				kubectl delete clusterrolebinding admin-user
			fi

			echo -e "${CYAN}Создание нового ClusterRoleBinding для admin-user...${NC}"
			kubectl create clusterrolebinding admin-user \
				--clusterrole=cluster-admin \
				--serviceaccount=kubernetes-dashboard:admin-user
		fi

		# Устанавливаем в правильный namespace
		namespace="kubernetes-dashboard"

		# Добавляем сборку зависимостей перед установкой
		echo -e "${CYAN}Проверка и сборка зависимостей чарта ${chart}...${NC}"
		helm dependency build "${CHARTS_DIR}/${chart}" || {
			echo -e "${RED}Ошибка при сборке зависимостей чарта ${chart}${NC}"
			exit 1
		}

		# Выполняем установку чарта
		local helm_cmd="helm ${action} ${chart} ${CHARTS_DIR}/${chart}"
		helm_cmd+=" --namespace ${namespace} --create-namespace"
		
		[ -n "$version" ] && helm_cmd+=" --version ${version}"
		[ -n "$values_file" ] && helm_cmd+=" -f ${values_file}"
		
		echo -e "${CYAN}Выполняется ${action} чарта ${chart}...${NC}"
		eval $helm_cmd
		
		# После установки чарта ждем готовности сервиса
		if [ "$action" = "install" ]; then
			echo -e "${CYAN}Проверка готовности сервиса dashboard...${NC}"
			local MAX_ATTEMPTS=10
			local ATTEMPT=1
			while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
				if kubectl get pods -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard | grep -q "Running"; then
					echo -e "${GREEN}Сервис dashboard готов к использованию${NC}"
					echo -e "${CYAN}Доступ: ${GREEN}https://dashboard.prod.local${NC}"
					break
				fi
				echo -e "${YELLOW}Ожидание готовности сервиса... (попытка $ATTEMPT/$MAX_ATTEMPTS)${NC}"
				ATTEMPT=$((ATTEMPT+1))
				sleep 3
			done

			if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
				echo -e "${YELLOW}Предупреждение: Превышено время ожидания, но установка завершена${NC}"
				echo -e "${CYAN}Проверьте статус сервиса: ${GREEN}kubectl get pods -n kubernetes-dashboard${NC}"
				echo -e "${CYAN}Доступ: ${GREEN}https://dashboard.prod.local${NC}"
			fi
		fi
		
		# Включаем валидационный вебхук ingress-nginx после установки dashboard
		if type toggle_ingress_webhook &>/dev/null; then
			echo -e "${CYAN}Включение валидационного вебхука ingress-nginx после установки dashboard...${NC}"
			
			# Check if ingress-nginx is installed
			if kubectl get deployment ingress-nginx-controller -n ingress-nginx &>/dev/null; then
				toggle_ingress_webhook "enable" || {
					echo -e "${YELLOW}Предупреждение: Не удалось включить вебхук${NC}"
				}
			else
				echo -e "${YELLOW}Предупреждение: ingress-nginx не установлен, пропускаем включение вебхука${NC}"
				echo -e "${YELLOW}Для полной функциональности установите ingress-nginx:${NC}"
				echo -e "${CYAN}$0 install ingress-nginx${NC}"
			fi
		else
			echo -e "${YELLOW}Функция toggle_ingress_webhook не найдена, пропускаем включение вебхука${NC}"
		fi
		
		return
	fi

	# Добавляем сборку зависимостей перед установкой
	echo -e "${CYAN}Проверка и сборка зависимостей чарта ${chart}...${NC}"
	helm dependency build "${CHARTS_DIR}/${chart}" || {
		echo -e "${RED}Ошибка при сборке зависимостей чарта ${chart}${NC}"
		exit 1
	}
	
	local helm_cmd="helm ${action} ${chart} ${CHARTS_DIR}/${chart}"
	helm_cmd+=" --namespace ${namespace}"
	# Add --create-namespace flag only for install and upgrade actions
	if [ "$action" = "install" ] || [ "$action" = "upgrade" ]; then
		helm_cmd+=" --create-namespace"
	fi
	
	[ -n "$version" ] && helm_cmd+=" --version ${version}"
	[ -n "$values_file" ] && helm_cmd+=" -f ${values_file}"

	# Для cert-manager добавляем таймаут установки
	if [ "$chart" = "cert-manager" ]; then
		helm_cmd+=" --timeout 5m"
	fi

	
	echo -e "${CYAN}Выполняется ${action} чарта ${chart}...${NC}"
	eval $helm_cmd
	
	# Дополнительное ожидание готовности CRD для cert-manager
	if [ "$chart" = "cert-manager" ] && [ $? -eq 0 ]; then
		echo -e "${CYAN}Ожидание готовности CRD cert-manager...${NC}"
		sleep 30
	fi
	
	if [ $? -eq 0 ]; then
		echo -e "\n"
		if declare -F success_banner >/dev/null; then
			success_banner "${action^} чарта ${chart} успешно завершен"
		else
			echo -e "${GREEN}Успешно!${NC}"
		fi
		echo -e "\n${GREEN}${action^} чарта ${chart} успешно завершен${NC}"
	else
		echo -e "\n"
		if declare -F error_banner >/dev/null; then
			error_banner "Ошибка при выполнении ${action} чарта ${chart}"
		else
			echo -e "${RED}Ошибка!${NC}"
		fi
		echo -e "\n${RED}Ошибка при выполнении ${action} чарта ${chart}${NC}"
		exit 1
	fi
}

# Функция проверки корректности команды
check_action() {
	local action=$1
	local valid_actions=("install" "upgrade" "uninstall" "list" "restart-dns" "dashboard-token" "reinstall-ingress" "reinstall-nvidia-device-plugin" "restart")
	
	# Проверяем совпадение с известными командами
	for valid_action in "${valid_actions[@]}"; do
		if [ "$action" = "$valid_action" ]; then
			return 0
		fi
	done
	
	# Если команда похожа на известную, предлагаем правильный вариант
	for valid_action in "${valid_actions[@]}"; do
		if [[ "$valid_action" == *"${action}"* ]] || [[ "${action}" == *"${valid_action}"* ]]; then
			if declare -F error_banner >/dev/null; then
				error_banner "Неизвестное действие '${action}'. Возможно, вы имели в виду: ${valid_action}"
			fi
			echo -e "${RED}Ошибка: Неизвестное действие '${action}'${NC}"
			echo -e "${YELLOW}Возможно, вы имели в виду: ${GREEN}${valid_action}${NC}"
			usage
		fi
	done
	
	# Если команда совсем не похожа на известные
	if declare -F error_banner >/dev/null; then
		error_banner "Неизвестное действие '${action}'"
	fi
	echo -e "${RED}Ошибка: Неизвестное действие '${action}'${NC}"
	echo -e "${YELLOW}Доступные действия: install, upgrade, uninstall, list, restart-dns, dashboard-token, reinstall-ingress${NC}"
	usage
}

# Функция получения токена для доступа к dashboard
get_dashboard_token() {
	local namespace="kubernetes-dashboard"
	local account="admin-user"
	
	echo -e "${CYAN}Получение токена для доступа к dashboard...${NC}"
	
	# Проверяем установлен ли dashboard
	if ! helm status kubernetes-dashboard -n $namespace >/dev/null 2>&1; then
		if declare -F error_banner >/dev/null; then
			error_banner "kubernetes-dashboard не установлен"
		fi
		echo -e "${RED}Ошибка: kubernetes-dashboard не установлен${NC}"
		echo -e "${YELLOW}Для установки выполните:${NC}"
		echo -e "${CYAN}$0 install kubernetes-dashboard${NC}"
		return 1
	fi
	
	# Создаем ServiceAccount если он не существует
	if ! kubectl get serviceaccount $account -n $namespace >/dev/null 2>&1; then
		echo -e "${CYAN}Создание ServiceAccount для доступа к dashboard...${NC}"
		kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $account
  namespace: $namespace
EOF
	fi
	
	# Проверка и обновление ClusterRoleBinding
	echo -e "${CYAN}Проверка и обновление ClusterRoleBinding для admin-user...${NC}"
	if kubectl get clusterrolebinding admin-user &> /dev/null; then
		echo -e "${CYAN}Удаление существующего ClusterRoleBinding...${NC}"
		kubectl delete clusterrolebinding admin-user
	fi

	echo -e "${CYAN}Создание нового ClusterRoleBinding для admin-user...${NC}"
	kubectl create clusterrolebinding admin-user \
		--clusterrole=cluster-admin \
		--serviceaccount=${namespace}:${account}

	
	# Ждем создания ServiceAccount
	echo -e "${CYAN}Ожидание готовности ServiceAccount...${NC}"
	sleep 5
	
	# Получаем токен
	local token=""
	if kubectl -n $namespace get serviceaccount $account >/dev/null 2>&1; then
		token=$(kubectl -n $namespace create token $account)
	fi
	
	if [ -n "$token" ]; then
		if declare -F success_banner >/dev/null; then
			success_banner "Токен для доступа к dashboard получен"
		fi
		echo -e "${GREEN}Токен для доступа к dashboard:${NC}"
		echo -e "${YELLOW}$token${NC}"
		echo -e "\n${CYAN}Доступ к dashboard: ${GREEN}https://dashboard.prod.local${NC}"
		return 0
	else
		if declare -F error_banner >/dev/null; then
			error_banner "Не удалось получить токен для dashboard"
		fi
		echo -e "${RED}Не удалось получить токен${NC}"
		return 1
	fi
}

# Обработка параметров командной строки
namespace=""
version=""
values_file=""

while [[ $# -gt 0 ]]; do
	case $1 in
		-h|--help)
			usage
			;;
		-n|--namespace)
			namespace="$2"
			shift 2
			;;
		-v|--version)
			version="$2"
			shift 2
			;;
		-f|--values)
			values_file="$2"
			shift 2
			;;
		*)
			break
			;;
	esac
done

if [ $# -lt 1 ]; then
	usage
fi

action=$1
chart=$2

# Проверяем корректность команды
check_action "$action"

# Проверяем количество аргументов для команд, требующих указания чарта
if [ "$action" != "list" ] && [ "$action" != "restart-dns" ] && \
   [ "$action" != "dashboard-token" ] && [ "$action" != "reinstall-ingress" ] && \
   [ $# -lt 2 ]; then
	if declare -F error_banner >/dev/null; then
		error_banner "Не указан чарт для действия ${action}"
	fi
	echo -e "${RED}Ошибка: Не указан чарт для действия ${action}${NC}"
	usage
fi

case $action in
	install|upgrade|uninstall)
		if [ "$chart" = "all" ]; then
			# Disable ingress-nginx admission webhook before upgrading all charts
			if [ "$action" = "upgrade" ] && type toggle_ingress_webhook &>/dev/null; then
				echo -e "${CYAN}Отключение валидационного вебхука ingress-nginx перед обновлением всех чартов...${NC}"
				toggle_ingress_webhook "disable" || {
					echo -e "${YELLOW}Предупреждение: Не удалось отключить вебхук, продолжаем установку...${NC}"
				}
			fi
			
			# Define the order of installation to handle dependencies
			ordered_charts=("cert-manager" "ingress-nginx" "kubernetes-dashboard")
			
			# Get all available charts
			all_charts=($(get_charts))
			
			# Install charts in the specified order first
			for c in "${ordered_charts[@]}"; do
				if [[ " ${all_charts[*]} " =~ " ${c} " ]]; then
					echo -e "${CYAN}Installing ${c} (ordered installation)...${NC}"
					install_chart $action $c "$namespace" "$version" "$values_file"
					# Remove from all_charts to avoid installing twice
					all_charts=(${all_charts[@]/$c/})
				fi
			done
			
			# Install remaining charts
			for c in "${all_charts[@]}"; do
				if [ -n "$c" ]; then  # Skip empty entries
					echo -e "${CYAN}Installing ${c}...${NC}"
					install_chart $action $c "$namespace" "$version" "$values_file"
				fi
			done
			
			# Re-enable ingress-nginx admission webhook after upgrading all charts
			if [ "$action" = "upgrade" ] && type toggle_ingress_webhook &>/dev/null; then
				echo -e "${CYAN}Включение валидационного вебхука ingress-nginx после обновления всех чартов...${NC}"
				toggle_ingress_webhook "enable" || {
					echo -e "${YELLOW}Предупреждение: Не удалось включить вебхук...${NC}"
				}
			fi
		else
			install_chart $action $chart "$namespace" "$version" "$values_file"
		fi
		;;
	list)
		if [ -n "$namespace" ]; then
			echo -e "${CYAN}Установленные чарты в namespace ${namespace}:${NC}"
			helm list -n "$namespace"
		else
			echo -e "${CYAN}Установленные чарты во всех namespace:${NC}"
			helm list -A
		fi
		exit 0
		;;
	restart-dns)
		restart_coredns
		;;
	dashboard-token)
		get_dashboard_token
		;;
	reinstall-ingress)
		reinstall_ingress
		;;
	reinstall-nvidia-device-plugin)
		reinstall_nvidia_device_plugin
		;;
	restart)
		restart_chart_pods "$chart" "$namespace"
		;;
esac