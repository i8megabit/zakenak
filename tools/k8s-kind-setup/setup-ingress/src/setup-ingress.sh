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
		
		# Сохраняем текущую конфигурацию ValidatingWebhookConfiguration
		kubectl get validatingwebhookconfiguration ingress-nginx-admission -o yaml > /tmp/ingress-webhook-backup.yaml 2>/dev/null || true
		
		# Отключаем вебхук, устанавливая failurePolicy в Ignore
		kubectl patch validatingwebhookconfiguration ingress-nginx-admission --type='json' -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value":"Ignore"}]' 2>/dev/null || true
		
		# Альтернативный подход - удаление ValidatingWebhookConfiguration
		if ! kubectl get validatingwebhookconfiguration ingress-nginx-admission &>/dev/null; then
			echo -e "${YELLOW}ValidatingWebhookConfiguration не найден, пропускаем отключение${NC}"
		else
			echo -e "${CYAN}Удаление ValidatingWebhookConfiguration...${NC}"
			kubectl delete validatingwebhookconfiguration ingress-nginx-admission --timeout=30s
		fi
		
		echo -e "${GREEN}Валидационный вебхук ingress-nginx успешно отключен${NC}"
	elif [ "$action" = "enable" ]; then
		echo -e "${CYAN}Включение валидационного вебхука ingress-nginx...${NC}"
		
		# Проверяем наличие бэкапа конфигурации
		if [ -f "/tmp/ingress-webhook-backup.yaml" ]; then
			echo -e "${CYAN}Восстановление конфигурации вебхука из бэкапа...${NC}"
			kubectl apply -f /tmp/ingress-webhook-backup.yaml
			rm -f /tmp/ingress-webhook-backup.yaml
		else
			echo -e "${YELLOW}Бэкап конфигурации не найден, пропускаем восстановление${NC}"
			
			# Перезапуск пода контроллера для пересоздания вебхука
			echo -e "${CYAN}Перезапуск ingress-controller для пересоздания вебхука...${NC}"
			kubectl rollout restart deployment ingress-nginx-controller -n "${NAMESPACE_INGRESS}"
			
			# Ожидание готовности контроллера
			echo -e "${CYAN}Ожидание готовности ingress-controller...${NC}"
			kubectl rollout status deployment ingress-nginx-controller -n "${NAMESPACE_INGRESS}" --timeout=300s
		fi
		
		echo -e "${GREEN}Валидационный вебхук ingress-nginx успешно включен${NC}"
	else
		echo -e "${RED}Ошибка: Неизвестное действие для toggle_ingress_webhook: ${action}${NC}"
		return 1
	fi
	
	return 0
}

# Экспортируем функцию для использования в других скриптах
export -f toggle_ingress_webhook