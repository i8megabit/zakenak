# GitOps Tools

Версия: 1.3.0
## Инструменты

### [Reset-WSL](./tools/reset-wsl)
Инструмент для полного сброса и переустановки WSL. Подробная документация находится в директории инструмента.

### [K8s-Kind-Setup](./tools/k8s-kind-setup)
Инструмент для автоматической установки и настройки локального Kubernetes кластера с использованием Kind в WSL2. Включает настройку Kubernetes Dashboard и все необходимые компоненты.

### [Helm Deployer](./tools/helm-deployer)
Универсальный инструмент для деплоя Helm чартов с поддержкой различных конфигураций и окружений.

#### Автоматический деплой всех чартов
```bash
# Базовое использование
./deploy-chart.sh

# Деплой с указанием окружения
./deploy-chart.sh -e prod

# Деплой с отладкой
./deploy-chart.sh --debug
```

### [Helm Setup](./tools/helm-setup)
Инструмент для автоматической установки и настройки Helm в Linux-системах. Включает установку Helm и добавление популярных репозиториев.

### [K8s Dashboard Token](./tools/k8s-dashboard-token)
Инструмент для автоматического получения токена доступа к Kubernetes Dashboard с поддержкой различных версий Kubernetes.

### [Sidecar Injector](./helm-charts/sidecar-injector)
Helm чарт для инжекции TLS сайдкаров.
Исправлены проблемы с генерацией TLS сертификатов.

### [Open WebUI](./helm-charts/open-webui)
Helm чарт для развертывания Open WebUI - веб-интерфейса для различных LLM бэкендов.
Доступ через: http://localhost/open-webui

### [Ollama](./helm-charts/ollama)
Helm чарт для развертывания Ollama - сервера LLM моделей.
Доступ через: http://ollama.local

Для доступа к интерфейсам:
1. Добавьте записи в /etc/hosts:
```bash
127.0.0.1 ollama.local
```