#!/usr/bin/bash

# Определение пути к директории скрипта и корню репозитория
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
export TOOLS_DIR="${BASE_DIR}/tools/k8s-kind-setup"
export SCRIPTS_ENV_PATH="${TOOLS_DIR}/env/src/env.sh"

# Загрузка общих переменных и баннеров
source "${SCRIPTS_ENV_PATH}"
source "${SCRIPTS_ASCII_BANNERS_PATH}"

# Отображение баннера
ingress_banner

echo -e "${CYAN}Установка Ingress NGINX Controller...${NC}"

# Добавление репозитория ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Установка ingress-nginx с использованием конфигурационного файла
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
	--namespace "${NAMESPACE_INGRESS}" \
	--create-namespace \
	--values "$(dirname "${BASH_SOURCE[0]}")/ingress-config.yaml"

check_error "Ошибка установки Ingress NGINX Controller"

# Ожидание готовности ingress-controller
echo -e "${CYAN}Ожидание готовности Ingress Controller...${NC}"
if ! wait_for_pods "${NAMESPACE_INGRESS}" "app.kubernetes.io/component=controller" 900 5; then
	echo -e "${RED}Ошибка при ожидании готовности Ingress Controller${NC}"
	exit 1
fi


echo -e "${GREEN}Ingress NGINX Controller успешно установлен!${NC}"

# Функция для отключения/включения валидационного вебхука ingress-nginx
toggle_ingress_webhook() {
	local action=$1  # "disable" или "enable"
	
	if [ "$action" = "disable" ]; then
		echo -e "${CYAN}Временное отключение валидационного вебхука ingress-nginx...${NC}"
		
		# Check if the webhook exists before trying to disable it
		if ! kubectl get validatingwebhookconfiguration ingress-nginx-admission &>/dev/null; then
			echo -e "${YELLOW}ValidatingWebhookConfiguration не найден, пропускаем отключение${NC}"
			return 0
		fi
		
		# Сохраняем текущую конфигурацию ValidatingWebhookConfiguration
		kubectl get validatingwebhookconfiguration ingress-nginx-admission -o yaml > /tmp/ingress-webhook-backup.yaml 2>/dev/null || true
		
		# Отключаем вебхук, устанавливая failurePolicy в Ignore
		kubectl patch validatingwebhookconfiguration ingress-nginx-admission --type='json' -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Ignore"}]' 2>/dev/null || true
		
		# Удаление ValidatingWebhookConfiguration
		echo -e "${CYAN}Удаление ValidatingWebhookConfiguration...${NC}"
		kubectl delete validatingwebhookconfiguration ingress-nginx-admission --timeout=30s --wait=true
		
		# Verify the webhook is actually gone
		local max_attempts=10
		local attempt=1
		while kubectl get validatingwebhookconfiguration ingress-nginx-admission &>/dev/null; do
			if [ $attempt -ge $max_attempts ]; then
				echo -e "${YELLOW}Не удалось удалить ValidatingWebhookConfiguration после $max_attempts попыток, продолжаем...${NC}"
				break
			fi
			echo -e "${YELLOW}Ожидание удаления ValidatingWebhookConfiguration (попытка $attempt/$max_attempts)...${NC}"
			sleep 2
			attempt=$((attempt + 1))
		done
		
		echo -e "${GREEN}Валидационный вебхук ingress-nginx успешно отключен${NC}"
	elif [ "$action" = "enable" ]; then
		echo -e "${CYAN}Включение валидационного вебхука ingress-nginx...${NC}"
		
		# Check if ingress-nginx controller is running
		if ! kubectl get deployment ingress-nginx-controller -n "${NAMESPACE_INGRESS}" &>/dev/null; then
			echo -e "${YELLOW}Предупреждение: ingress-nginx не установлен, пропускаем включение вебхука${NC}"
			echo -e "${YELLOW}Для полной функциональности установите ingress-nginx:${NC}"
			echo -e "${CYAN}./tools/k8s-kind-setup/charts/src/charts.sh install ingress-nginx${NC}"
			return 0
		fi
		
		# Ensure the controller is ready before enabling the webhook
		echo -e "${CYAN}Проверка готовности ingress-controller...${NC}"
		if ! kubectl rollout status deployment ingress-nginx-controller -n "${NAMESPACE_INGRESS}" --timeout=60s &>/dev/null; then
			echo -e "${YELLOW}Ingress controller не готов, перезапуск...${NC}"
			kubectl rollout restart deployment ingress-nginx-controller -n "${NAMESPACE_INGRESS}"
			sleep 10
			if ! kubectl rollout status deployment ingress-nginx-controller -n "${NAMESPACE_INGRESS}" --timeout=120s &>/dev/null; then
				echo -e "${RED}Ingress controller не готов после перезапуска, пропускаем включение вебхука${NC}"
				return 1
			fi
		fi
		
		# Check if the webhook already exists
		if kubectl get validatingwebhookconfiguration ingress-nginx-admission &>/dev/null; then
			echo -e "${YELLOW}ValidatingWebhookConfiguration уже существует, пропускаем восстановление${NC}"
			return 0
		fi
		
		# Проверяем наличие бэкапа конфигурации
		if [ -f "/tmp/ingress-webhook-backup.yaml" ]; then
			echo -e "${CYAN}Восстановление конфигурации вебхука из бэкапа...${NC}"
			
			# Apply the backup configuration
			kubectl apply -f /tmp/ingress-webhook-backup.yaml || {
				echo -e "${YELLOW}Ошибка при применении бэкапа, пересоздаем вебхук...${NC}"
				rm -f /tmp/ingress-webhook-backup.yaml
				kubectl rollout restart deployment ingress-nginx-controller -n "${NAMESPACE_INGRESS}"
				kubectl rollout status deployment ingress-nginx-controller -n "${NAMESPACE_INGRESS}" --timeout=120s
				return 0
			}
			
			# Clean up the backup file
			rm -f /tmp/ingress-webhook-backup.yaml
		else
			echo -e "${YELLOW}Бэкап конфигурации не найден, пересоздаем вебхук...${NC}"
			
			# Перезапуск пода контроллера для пересоздания вебхука
			echo -e "${CYAN}Перезапуск ingress-controller для пересоздания вебхука...${NC}"
			kubectl rollout restart deployment ingress-nginx-controller -n "${NAMESPACE_INGRESS}"
			
			# Ожидание готовности контроллера
			echo -e "${CYAN}Ожидание готовности ingress-controller...${NC}"
			kubectl rollout status deployment ingress-nginx-controller -n "${NAMESPACE_INGRESS}" --timeout=120s
		fi
		
		# Verify the webhook is properly configured and the admission service is ready
		local max_attempts=10
		local attempt=1
		local webhook_ready=false
		
		while [ $attempt -le $max_attempts ]; do
			echo -e "${CYAN}Проверка готовности вебхука (попытка $attempt/$max_attempts)...${NC}"
			
			# Check if the webhook exists
			if kubectl get validatingwebhookconfiguration ingress-nginx-admission &>/dev/null; then
				# Check if the admission service is ready
				if kubectl get service ingress-nginx-controller-admission -n "${NAMESPACE_INGRESS}" &>/dev/null; then
					# Check if endpoints exist for the service
					if [ -n "$(kubectl get endpoints ingress-nginx-controller-admission -n "${NAMESPACE_INGRESS}" -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)" ]; then
						webhook_ready=true
						break
					fi
				fi
			fi
			
			sleep 5
			attempt=$((attempt + 1))
		done
		
		if [ "$webhook_ready" = true ]; then
			echo -e "${GREEN}Валидационный вебхук ingress-nginx успешно включен${NC}"
		else
			echo -e "${YELLOW}Предупреждение: Не удалось проверить готовность вебхука после $max_attempts попыток${NC}"
			echo -e "${YELLOW}Если возникнут проблемы с валидацией Ingress, выполните:${NC}"
			echo -e "${CYAN}kubectl rollout restart deployment ingress-nginx-controller -n ${NAMESPACE_INGRESS}${NC}"
		fi
	else
		echo -e "${RED}Ошибка: Неизвестное действие для toggle_ingress_webhook: ${action}${NC}"
		return 1
	fi
	
	return 0
}

# Экспортируем функцию для использования в других скриптах
export -f toggle_ingress_webhook