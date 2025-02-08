# Kind Kubernetes Cluster Setup

Версия: 1.0.0

Инструмент для автоматической установки локального Kubernetes кластера с помощью Kind в WSL2.

## Описание
Скрипт автоматизирует процесс установки и настройки локального Kubernetes кластера в WSL2 с использованием Kind. Включает установку всех необходимых компонентов и настройку Kubernetes Dashboard.

## Возможности
- Автоматическая установка Docker (если не установлен)
- Автоматическая установка kubectl (если не установлен)
- Автоматическая установка Kind (если не установлен)
- Создание кластера Kubernetes с настроенными портами
- Установка и настройка Kubernetes Dashboard
- Создание административного аккаунта для доступа к Dashboard

## Требования
- Windows 10/11 с WSL2
- Ubuntu в WSL2
- Доступ к интернету
- Права sudo в WSL

## Установка и использование
1. Убедитесь, что WSL2 с Ubuntu установлен и работает
2. Скопируйте скрипт в вашу домашнюю директорию в WSL
3. Сделайте скрипт исполняемым:
```bash
chmod +x install-kind-cluster.sh
```
4. Запустите скрипт
```bash
./install-kind-cluster.sh
```
5. Доступ к Kubernetes Dashboard
6. После установки запустите прокси:
```bash
kubectl proxy
```
7. Откройте в браузере:
```bash
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```
8. Используйте токен, который был выведен в конце установки

## Проверка работоспособности

Проверка работающих подов:
```bash
kubectl get pods --all-namespaces
```

## Устранение неполадок

Docker не запускается
```bash
Если Docker не запускается, выполните:
sudo service docker start
```
Проблемы с правами Docker
```bash
Если возникают проблемы с правами Docker, выполните:

sudo usermod -aG docker $USER
newgrp docker
```

Очистка
```bash
Для удаления кластера выполните:

kind delete cluster
```