# Настройка KUBECONFIG для Zakenak

```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\
```

## Навигация
- [Главная страница](../README.md)
- Документация
  - [Руководство по развертыванию](DEPLOYMENT.md)
  - [GitOps подход](GITOPS.md)
  - [API Reference](api.md)
  - [Устранение неполадок](troubleshooting.md)
  - [GPU в WSL2](GPU-WSL.md)
  - [Использование Docker](DOCKER-USAGE.md)
  - [Настройка KUBECONFIG](KUBECONFIG.md) (текущий документ)
  - [Мониторинг](MONITORING.md)
  - [Настройка сети](NETWORK-CONFIGURATION.md)
  - [Миграция и настройка WSL и Docker](WSL-DOCKER-MIGRATION.md)
- [Примеры](../examples/README.md)

## GitHub Actions Secrets

### Обязательные секреты
| Секрет | Описание | Автоматическое создание |
|--------|-----------|------------------------|
| `GITHUB_TOKEN` | Токен для доступа к GitHub API | ✅ |
| `PAT_TOKEN` | Personal Access Token с расширенными правами | ❌ |
| `KUBECONFIG` | Конфигурация доступа к Kubernetes кластеру | ❌ |

### Дополнительные секреты
| Секрет | Описание | Обязательность |
|--------|-----------|----------------|
| `REGISTRY_TOKEN` | Токен для доступа к Container Registry | Опционально |
| `GPU_CONFIG` | Конфигурация NVIDIA GPU | Опционально |
| `CERT_MANAGER_TOKEN` | Токен для cert-manager | Опционально |

## Генерация KUBECONFIG

### 1. Подготовка окружения
```bash
# Проверка доступа к кластеру
kubectl cluster-info

# Проверка прав
kubectl auth can-i create serviceaccount --all-namespaces
kubectl auth can-i create clusterrolebinding
```

### 2. Создание Service Account
```bash
# Создание Service Account для CI/CD
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: github-actions
  namespace: prod
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: github-actions-admin
subjects:
- kind: ServiceAccount
  name: github-actions
  namespace: prod
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF

# Получение токена
kubectl -n prod create token github-actions --duration=8760h
```

### 3. Генерация KUBECONFIG
```bash
# Запуск скрипта генерации
./tools/zakenak/scripts/generate-kubeconfig.sh \
    --service-account github-actions \
    --namespace prod \
    --duration 8760h \
    --output kubeconfig.yaml

# Проверка конфигурации
KUBECONFIG=kubeconfig.yaml kubectl get nodes
```

## Настройка GitHub Actions

### 1. Добавление секретов
1. Перейдите в `Settings` → `Secrets and variables` → `Actions`
2. Нажмите `New repository secret`
3. Добавьте следующие секреты:
   - Имя: `KUBECONFIG`
   - Значение: содержимое `kubeconfig.yaml`
   - Область видимости: Repository

### 2. Проверка настройки
```yaml
name: Verify KUBECONFIG
on: [workflow_dispatch]
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test Kubernetes connection
        env:
          KUBECONFIG: ${{ secrets.KUBECONFIG }}
        run: |
          echo "$KUBECONFIG" > /tmp/kubeconfig.yaml
          export KUBECONFIG=/tmp/kubeconfig.yaml
          kubectl cluster-info
```

## Безопасность

### Рекомендации
1. Используйте Service Account с минимально необходимыми правами
2. Регулярно ротируйте токены (рекомендуется каждые 90 дней)
3. Используйте Network Policies для ограничения доступа
4. Мониторируйте использование Service Account
5. Настройте аудит всех действий в кластере

### Ротация токенов
```bash
# Удаление старого токена
kubectl -n prod delete secret \
    $(kubectl -n prod get secret | grep github-actions-token | awk '{print $1}')

# Создание нового токена
kubectl -n prod create token github-actions --duration=2160h

# Обновление секрета в GitHub Actions
# Обновите KUBECONFIG в настройках репозитория
```

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: github-actions-policy
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/managed-by: github-actions
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: prod
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: prod
```

## Мониторинг и аудит

### Логирование действий
```bash
# Просмотр действий Service Account
kubectl get events --field-selector involvedObject.name=github-actions -n prod

# Аудит использования токена
kubectl get apiservice -o yaml | grep audit
```

### Алертинг
Настройте оповещения для:
- Неудачных попыток аутентификации
- Необычной активности Service Account
- Истечения срока действия токена
- Изменений в RBAC конфигурации

## Устранение неполадок

### Проблемы с аутентификацией
1. Проверьте срок действия токена
2. Убедитесь в правильности RBAC настроек
3. Проверьте Network Policies
4. Проверьте логи kube-apiserver

### Проблемы с правами доступа
1. Проверьте ClusterRoleBinding
2. Проверьте namespace restrictions
3. Проверьте Pod Security Policies
4. Проверьте логи аудита

```plain text
Copyright (c) 2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. 
See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT.
```