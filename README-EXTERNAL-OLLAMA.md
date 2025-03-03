# Внешний Ollama с поддержкой GPU для Kubernetes

Это руководство объясняет, как настроить Ollama с поддержкой GPU в Docker-контейнере вне Kubernetes и сконфигурировать ваш кластер Kubernetes для использования этого внешнего экземпляра Ollama.

## Обзор

Вместо запуска Ollama с ресурсами GPU непосредственно в подах Kubernetes, эта настройка:

1. Запускает Ollama в Docker-контейнере с доступом к GPU, используя Docker Compose
2. Создает сервис Kubernetes, который указывает на внешний контейнер Ollama
3. Поддерживает интеграцию с Open WebUI в кластере Kubernetes

Этот подход позволяет вам:
- Более эффективно использовать ресурсы GPU
- Упростить управление ресурсами Kubernetes (не требуются ресурсы GPU в K8s)
- Сохранить тот же пользовательский опыт с Open WebUI

## Инструкции по настройке

### Автоматическая настройка (Рекомендуется)

Самый простой способ настроить эту конфигурацию — использовать предоставленный скрипт настройки:

```bash
./setup-external-ollama.sh
```

Этот скрипт:
1. Проверит наличие необходимых зависимостей (Docker, Docker Compose, kubectl, Helm, драйверы NVIDIA)
2. Установит NVIDIA Container Toolkit, если необходимо
3. Запустит контейнер Ollama с поддержкой GPU, используя Docker Compose
4. Создаст сервис Kubernetes, который указывает на внешний контейнер Ollama
5. Развернет чарт Helm для Open WebUI с соответствующей конфигурацией
6. Дождется готовности пода Open WebUI (может занять до 30 минут)

### Ручная настройка

Если вы предпочитаете настраивать компоненты вручную:

#### 1. Настройка Ollama в Docker

Перейдите в директорию `docker-compose` и запустите Ollama с поддержкой GPU:

```bash
cd docker-compose
docker compose up -d
```

#### 2. Создание сервиса Kubernetes для внешнего Ollama

Создайте сервис Kubernetes, который указывает на внешний контейнер Ollama:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ollama
  namespace: prod
  labels:
    app: ollama
spec:
  type: ExternalName
  externalName: host.docker.internal
  ports:
    - port: 11434
      targetPort: 11434
      protocol: TCP
      name: http
EOF
```

#### 3. Развертывание Open WebUI

Разверните чарт Helm для Open WebUI с отключенной конфигурацией GPU:

```bash
helm upgrade --install open-webui ./helm-charts/open-webui -n prod --set deployment.gpuConfig=false
```

## Устранение неполадок

Если Open WebUI не может подключиться к Ollama, проверьте следующее:

1. Убедитесь, что контейнер Ollama запущен в Docker:
   ```bash
   docker ps | grep ollama
   docker logs ollama
   ```

2. Проверьте, что сервис Ollama в Kubernetes правильно настроен:
   ```bash
   kubectl get svc -n prod ollama
   ```

3. Проверьте соединение изнутри кластера Kubernetes:
   ```bash
   kubectl run -it --rm debug --image=curlimages/curl -- curl http://host.docker.internal:11434/api/tags
   ```

4. Проверьте логи пода Open WebUI:
   ```bash
   kubectl logs -n prod -l app=open-webui
   ```

5. Проверьте статус пода Open WebUI:
   ```bash
   kubectl describe pod -n prod -l app=open-webui
   ```

6. Если вы используете имя хоста, отличное от `host.docker.internal`, убедитесь, что оно правильно указано в сервисе Kubernetes.

7. При ошибках сегментации (код выхода 139) попробуйте увеличить лимиты памяти в чарте Helm для Open WebUI:
   ```bash
   helm upgrade --install open-webui ./helm-charts/open-webui -n prod --set deployment.gpuConfig=false --set deployment.resources.limits.memory=4Gi
   ```

## Сетевая конфигурация

Для работы этой настройки ваш кластер Kubernetes должен иметь возможность взаимодействовать с хостом Docker. Если вы используете Kind или Minikube на том же компьютере, это должно работать автоматически с использованием `host.docker.internal` в качестве имени хоста.

Если вы используете другую настройку, возможно, вам потребуется изменить имя хоста в сервисе Kubernetes, чтобы оно указывало на правильный IP-адрес вашего хоста Docker.

## Время запуска

Запуск пода Open WebUI может занять до 30 минут. Проба запуска настроена с расширенными таймаутами, чтобы обеспечить достаточно времени для готовности контейнера. Если под все еще не готов по истечении этого времени, проверьте логи на наличие ошибок.

Процесс запуска включает:
- Инициализацию базы данных и миграции
- Загрузку моделей и ресурсов
- Установление соединения с Ollama

В течение этого времени под будет отображаться как "Running" (Запущен), но не "Ready" (Готов), пока не пройдут все проверки работоспособности.