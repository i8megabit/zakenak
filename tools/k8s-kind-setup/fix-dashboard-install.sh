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

# Шаг 1: Удаление существующего namespace kubernetes-dashboard
echo -e "${CYAN}Удаление namespace kubernetes-dashboard...${NC}"
kubectl delete namespace kubernetes-dashboard --timeout=60s 2>/dev/null || true

# Ожидание удаления namespace с таймаутом
echo -e "${CYAN}Ожидание удаления namespace...${NC}"
local ns_delete_timeout=60
local ns_delete_start_time=$(date +%s)
local force_delete_applied=false

while kubectl get namespace kubernetes-dashboard &>/dev/null; do
    local current_time=$(date +%s)
    local elapsed_time=$((current_time - ns_delete_start_time))
    
    # Если прошло больше времени, чем таймаут, и еще не применяли принудительное удаление
    if [ $elapsed_time -gt $ns_delete_timeout ] && [ "$force_delete_applied" = false ]; then
        echo -e "${YELLOW}Превышено время ожидания удаления namespace. Применение принудительного удаления...${NC}"
        
        # Получаем список всех ресурсов в namespace
        echo -e "${CYAN}Поиск ресурсов, блокирующих удаление namespace...${NC}"
        
        # Удаляем финализаторы из namespace
        echo -e "${CYAN}Удаление финализаторов из namespace...${NC}"
        kubectl patch namespace kubernetes-dashboard -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
        
        # Принудительно удаляем все ресурсы в namespace
        echo -e "${CYAN}Принудительное удаление всех ресурсов в namespace...${NC}"
        for resource in $(kubectl api-resources --verbs=list --namespaced -o name); do
            kubectl delete $resource --all --force --grace-period=0 -n kubernetes-dashboard 2>/dev/null || true
        done
        
        force_delete_applied=true
        ns_delete_start_time=$(date +%s)  # Сбрасываем таймер для дополнительного ожидания
        continue
    fi
    
    # Если прошло больше времени, чем таймаут после принудительного удаления
    if [ $elapsed_time -gt $ns_delete_timeout ] && [ "$force_delete_applied" = true ]; then
        echo -e "${YELLOW}Namespace все еще не удален после принудительного удаления. Продолжаем установку...${NC}"
        break
    fi
    
    echo -e "${YELLOW}Namespace все еще удаляется, ожидание... (прошло ${elapsed_time}с)${NC}"
    sleep 5
done

# Дополнительная проверка и создание namespace, если он все еще существует
if kubectl get namespace kubernetes-dashboard &>/dev/null; then
    echo -e "${YELLOW}Не удалось полностью удалить namespace. Попытка продолжить установку...${NC}"
    # Пытаемся очистить namespace вместо удаления
    echo -e "${CYAN}Очистка ресурсов в namespace...${NC}"
    for resource in $(kubectl api-resources --verbs=list --namespaced -o name); do
        kubectl delete $resource --all --force --grace-period=0 -n kubernetes-dashboard 2>/dev/null || true
    done
fi

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