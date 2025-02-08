# GitOps Tools

Версия: 1.1.2

## Инструменты

### [Reset-WSL](./tools/reset-wsl)
Инструмент для полного сброса и переустановки WSL. Подробная документация находится в директории инструмента.

### [K8s-Kind-Setup](./tools/k8s-kind-setup)
Инструмент для автоматической установки и настройки локального Kubernetes кластера с использованием Kind в WSL2. Включает настройку Kubernetes Dashboard и все необходимые компоненты.

### [Helm Deployer](./tools/helm-deployer)
Универсальный инструмент для деплоя Helm чартов с поддержкой различных конфигураций и окружений.

#### Автоматический деплой всех чартов
```bash
./tools/helm-deployer/deploy-chart.sh
```

### [Helm Setup](./tools/helm-setup)
Инструмент для автоматической установки и настройки Helm в Linux-системах. Включает установку Helm и добавление популярных репозиториев.

### [K8s Dashboard Token](./tools/k8s-dashboard-token)
Инструмент для автоматического получения токена доступа к Kubernetes Dashboard с поддержкой различных версий Kubernetes.