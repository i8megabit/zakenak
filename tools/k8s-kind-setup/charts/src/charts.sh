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

# Загрузка баннеров с предотвращением автозапуска
if [ -f "${K8S_KIND_SETUP_DIR}/ascii-banners/src/ascii_banners.sh" ]; then
	export SKIP_BANNER_MAIN=1
	source "${K8S_KIND_SETUP_DIR}/ascii-banners/src/ascii_banners.sh"
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
			description=$(grep "description:" "${CHARTS_DIR}/${chart}/Chart.yaml" | cut -d: -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || echo "")
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
	kubectl apply -f "${K8S_KIND_SETUP_DIR}/setup-dns/src/coredns-custom.yaml"

	# Перезапуск CoreDNS
	kubectl rollout restart deployment/coredns -n kube-system
	sleep 10

	echo -e "${CYAN}Ожидание готовности CoreDNS...${NC}"
	if ! kubectl rollout status deployment/coredns -n kube-system --timeout=300s; then
		echo -e "${RED}Ошибка при ожидании готовности CoreDNS${NC}"
		echo -e "${YELLOW}Проверка логов новых подов...${NC}"
		kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50 || true
		echo -e "${YELLOW}Описание подов...${NC}"
		kubectl describe pods -n kube-system -l k8s-app=kube-dns
		exit 1
	fi

	# Финальная проверка
	echo -e "${CYAN}Финальное состояние CoreDNS:${NC}"
	kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide

	echo -e "${GREEN}CoreDNS успешно перезапущен${NC}"
}

# Функция установки/обновления чарта
install_chart() {
	local action=$1
	local chart=$2
	local namespace=${3:-$NAMESPACE_PROD}
	local version=$4
	local values_file=$5
	
	# Обработка алиасов чартов
	case "$chart" in
		"dashboard")
			chart="kubernetes-dashboard"
			;;
		"coredns")
			chart="coredns"
			restart_coredns
			;;
		*)
			;;
	esac
	
	if [ ! -d "${CHARTS_DIR}/${chart}" ]; then
		if declare -F error_banner >/dev/null; then
			error_banner
		fi
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
		fi

		# Устанавливаем в правильный namespace
		namespace="kubernetes-dashboard"
		
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
	helm_cmd+=" --namespace ${namespace} --create-namespace"
	
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
			success_banner
		else
			echo -e "${GREEN}Успешно!${NC}"
		fi
		echo -e "\n${GREEN}${action^} чарта ${chart} успешно завершен${NC}"
	else
		echo -e "\n"
		if declare -F error_banner >/dev/null; then
			error_banner
		else
			echo -e "${RED}Ошибка!${NC}"
		fi
		echo -e "\n${RED}Ошибка при выполнении ${action} чарта ${chart}${NC}"
		exit 1
	fi
}

# Функция получения токена для доступа к dashboard
get_dashboard_token() {
	local namespace="kubernetes-dashboard"
	local account="admin-user"
	
	echo -e "${CYAN}Получение токена для доступа к dashboard...${NC}"
	
	# Проверяем установлен ли dashboard
	if ! helm status kubernetes-dashboard -n $namespace >/dev/null 2>&1; then
		if declare -F error_banner >/dev/null; then
			error_banner
		fi
		echo -e "${RED}Ошибка: kubernetes-dashboard не установлен${NC}"
		echo -e "${YELLOW}Для установки выполните:${NC}"
		echo -e "${CYAN}$0 install kubernetes-dashboard${NC}"
		return 1
	fi
	
	# Проверяем существование ServiceAccount
	if ! kubectl get serviceaccount $account -n $namespace >/dev/null 2>&1; then
		if declare -F error_banner >/dev/null; then
			error_banner
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
			success_banner
		fi
		echo -e "${GREEN}Токен для доступа к dashboard:${NC}"
		echo -e "${YELLOW}$token${NC}"
		echo -e "\n${CYAN}Доступ к dashboard: ${GREEN}https://dashboard.prod.local${NC}"
		return 0
	else
		if declare -F error_banner >/dev/null; then
			error_banner
		fi
		echo -e "${RED}Не удалось получить токен${NC}"
		return 1
	fi
}

# Функция проверки корректности команды
check_action() {
	local action=$1
	local valid_actions=("install" "upgrade" "uninstall" "list" "restart-dns" "dashboard-token")
	
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
	echo -e "${YELLOW}Доступные действия: install, upgrade, uninstall, list, restart-dns${NC}"
	usage
}

# Определение пути к директории скрипта и корню репозитория
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
K8S_KIND_SETUP_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CHARTS_DIR="${TOOLS_DIR}/../helm-charts"

# Загрузка общих переменных
source "${K8S_KIND_SETUP_DIR}/env/src/env.sh"

# Загрузка баннеров с предотвращением автозапуска
if [ -f "${K8S_KIND_SETUP_DIR}/ascii-banners/src/ascii_banners.sh" ]; then
	export SKIP_BANNER_MAIN=1
	source "${K8S_KIND_SETUP_DIR}/ascii-banners/src/ascii_banners.sh"
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

# Функция вывода справки
usage() {
	local charts
	charts=($(get_charts))
	
	echo -e "${CYAN}Использование:${NC} $0 ${YELLOW}[опции]${NC} ${GREEN}<действие>${NC} ${GREEN}<чарт>${NC}"
	echo ""
	echo -e "${CYAN}Действия:${NC}"
	echo -e "${GREEN}  install        ${YELLOW}-${NC} Установить чарт"
	echo -e "${GREEN}  upgrade        ${YELLOW}-${NC} Обновить чарт"
	echo -e "${GREEN}  uninstall      ${YELLOW}-${NC} Удалить чарт"
	echo -e "${GREEN}  list           ${YELLOW}-${NC} Показать список установленных чартов"
	echo -e "${GREEN}  restart-dns    ${YELLOW}-${NC} Перезапустить CoreDNS"
	echo -e "${GREEN}  dashboard-token ${YELLOW}-${NC} Получить токен для доступа к dashboard"
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

# Функция перезапуска CoreDNS

restart_coredns() {
	echo -e "${CYAN}Перезапуск CoreDNS...${NC}"

	# Проверка текущего состояния
	echo -e "${CYAN}Текущее состояние CoreDNS:${NC}"
	kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide
	kubectl describe deployment coredns -n kube-system

	# Применение обновленной конфигурации
	echo -e "${CYAN}Применение конфигурации CoreDNS...${NC}"
	kubectl apply -f "${K8S_KIND_SETUP_DIR}/setup-dns/src/coredns-custom.yaml"

	# Перезапуск CoreDNS
	kubectl rollout restart deployment/coredns -n kube-system
	sleep 10

	echo -e "${CYAN}Ожидание готовности CoreDNS...${NC}"
	if ! kubectl rollout status deployment/coredns -n kube-system --timeout=300s; then
		echo -e "${RED}Ошибка при ожидании готовности CoreDNS${NC}"
		echo -e "${YELLOW}Проверка логов новых подов...${NC}"
		kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50 || true
		echo -e "${YELLOW}Описание подов...${NC}"
		kubectl describe pods -n kube-system -l k8s-app=kube-dns
		exit 1
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
		
		# Создаем ServiceAccount и ClusterRoleBinding для доступа к дашборду
		if [ "$action" = "install" ]; then
			echo -e "${CYAN}Создание ServiceAccount для доступа к dashboard...${NC}"
			kubectl create serviceaccount -n kubernetes-dashboard admin-user 2>/dev/null || true
			
			echo -e "${CYAN}Создание ClusterRoleBinding для admin-user...${NC}"
			kubectl create clusterrolebinding admin-user \
				--clusterrole=cluster-admin \
				--serviceaccount=kubernetes-dashboard:admin-user 2>/dev/null || true
		fi
	fi

	# Добавляем сборку зависимостей перед установкой
	echo -e "${CYAN}Проверка и сборка зависимостей чарта ${chart}...${NC}"
	helm dependency build "${CHARTS_DIR}/${chart}" || {
		echo -e "${RED}Ошибка при сборке зависимостей чарта ${chart}${NC}"
		exit 1
	}
	
	local helm_cmd="helm ${action} ${chart} ${CHARTS_DIR}/${chart}"
	helm_cmd+=" --namespace ${namespace} --create-namespace"
	
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
			success_banner
		else
			echo -e "${GREEN}Успешно!${NC}"
		fi
		echo -e "\n${GREEN}${action^} чарта ${chart} успешно завершен${NC}"
	else
		echo -e "\n"
		if declare -F error_banner >/dev/null; then
			error_banner
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
	local valid_actions=("install" "upgrade" "uninstall" "list" "restart-dns" "dashboard-token")
	
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
	echo -e "${YELLOW}Доступные действия: install, upgrade, uninstall, list, restart-dns${NC}"
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
			error_banner
		fi
		echo -e "${RED}Ошибка: kubernetes-dashboard не установлен${NC}"
		echo -e "${YELLOW}Для установки выполните:${NC}"
		echo -e "${CYAN}$0 install kubernetes-dashboard${NC}"
		return 1
	fi
	
	# Создаем ServiceAccount если он не существует
	if ! kubectl get serviceaccount $account -n $namespace >/dev/null 2>&1; then
		echo -e "${CYAN}Создание ServiceAccount для доступа к dashboard...${NC}"
		kubectl create serviceaccount -n $namespace $account || {
			if declare -F error_banner >/dev/null; then
				error_banner
			fi
			echo -e "${RED}Ошибка при создании ServiceAccount${NC}"
			return 1
		}
	fi
	
	# Создаем ClusterRoleBinding если он не существует
	if ! kubectl get clusterrolebinding admin-user >/dev/null 2>&1; then
		echo -e "${CYAN}Создание ClusterRoleBinding для admin-user...${NC}"
		kubectl create clusterrolebinding admin-user \
			--clusterrole=cluster-admin \
			--serviceaccount=$namespace:$account || {
			if declare -F error_banner >/dev/null; then
				error_banner
			fi
			echo -e "${RED}Ошибка при создании ClusterRoleBinding${NC}"
			return 1
		}
	fi
	
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
			success_banner
		fi
		echo -e "${GREEN}Токен для доступа к dashboard:${NC}"
		echo -e "${YELLOW}$token${NC}"
		echo -e "\n${CYAN}Доступ к dashboard: ${GREEN}https://dashboard.local${NC}"
		return 0
	else
		if declare -F error_banner >/dev/null; then
			error_banner
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
if [ "$action" != "list" ] && [ "$action" != "restart-dns" ] && [ "$action" != "dashboard-token" ] && [ $# -lt 2 ]; then
	if declare -F error_banner >/dev/null; then
		error_banner
	fi
	echo -e "${RED}Ошибка: Не указан чарт для действия ${action}${NC}"
	usage
fi

case $action in
	install|upgrade|uninstall)
		if [ "$chart" = "all" ]; then
			charts=($(get_charts))
			for c in "${charts[@]}"; do
				install_chart $action $c "$namespace" "$version" "$values_file"
			done
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
esac
