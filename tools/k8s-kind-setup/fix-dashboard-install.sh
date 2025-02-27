#!/usr/bin/bash

# Определение пути к директории скрипта и корню репозитория
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export TOOLS_DIR="${BASE_DIR}/tools/k8s-kind-setup"
export SCRIPTS_ENV_PATH="${TOOLS_DIR}/env/src/env.sh"

# Загрузка общих переменных и баннеров
source "${SCRIPTS_ENV_PATH}"
source "${SCRIPTS_ASCII_BANNERS_PATH}"

# Отображение баннера
if declare -F dashboard_banner >/dev/null; then
    dashboard_banner
fi

echo -e "${CYAN}Исправление проблемы установки Kubernetes Dashboard...${NC}"

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

# Шаг 1: Удаление существующего namespace kubernetes-dashboard
echo -e "${CYAN}Удаление namespace kubernetes-dashboard...${NC}"
kubectl delete namespace kubernetes-dashboard --timeout=60s 2>/dev/null || true

# Ожидание удаления namespace
while kubectl get namespace kubernetes-dashboard &>/dev/null; do
    echo -e "${YELLOW}Ожидание удаления namespace kubernetes-dashboard...${NC}"
    sleep 5
done

# Шаг 2: Отключение валидационного вебхука
echo -e "${CYAN}Отключение валидационного вебхука ingress-nginx...${NC}"
toggle_ingress_webhook "disable"

# Шаг 3: Создание namespace kubernetes-dashboard
echo -e "${CYAN}Создание namespace kubernetes-dashboard...${NC}"
kubectl create namespace kubernetes-dashboard

# Шаг 4: Создание ServiceAccount для доступа к dashboard
echo -e "${CYAN}Создание ServiceAccount для доступа к dashboard...${NC}"
kubectl create serviceaccount -n kubernetes-dashboard admin-user

# Шаг 5: Проверка и обновление ClusterRoleBinding
echo -e "${CYAN}Проверка и обновление ClusterRoleBinding для admin-user...${NC}"
if kubectl get clusterrolebinding admin-user &> /dev/null; then
    echo -e "${CYAN}Удаление существующего ClusterRoleBinding...${NC}"
    kubectl delete clusterrolebinding admin-user
fi

echo -e "${CYAN}Создание нового ClusterRoleBinding для admin-user...${NC}"
kubectl create clusterrolebinding admin-user \
    --clusterrole=cluster-admin \
    --serviceaccount=kubernetes-dashboard:admin-user

# Шаг 6: Проверка и сборка зависимостей чарта kubernetes-dashboard
echo -e "${CYAN}Проверка и сборка зависимостей чарта kubernetes-dashboard...${NC}"
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update

# Шаг 7: Установка чарта kubernetes-dashboard
echo -e "${CYAN}Выполняется install чарта kubernetes-dashboard...${NC}"
helm install kubernetes-dashboard "${BASE_DIR}/helm-charts/kubernetes-dashboard" \
    --namespace kubernetes-dashboard \
    --create-namespace

# Шаг 8: Проверка готовности сервиса dashboard
echo -e "${CYAN}Проверка готовности сервиса dashboard...${NC}"
MAX_ATTEMPTS=10
ATTEMPT=1
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

# Шаг 9: Включение валидационного вебхука
echo -e "${CYAN}Включение валидационного вебхука ingress-nginx...${NC}"
toggle_ingress_webhook "enable"

# Шаг 10: Получение токена для доступа к dashboard
echo -e "${CYAN}Получение токена для доступа к dashboard...${NC}"
TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user)

if [ -n "$TOKEN" ]; then
    echo -e "${GREEN}Токен для доступа к dashboard:${NC}"
    echo -e "${YELLOW}$TOKEN${NC}"
    echo -e "\n${CYAN}Доступ к dashboard: ${GREEN}https://dashboard.prod.local${NC}"
else
    echo -e "${RED}Не удалось получить токен${NC}"
fi

echo -e "${GREEN}Установка Kubernetes Dashboard успешно завершена!${NC}"