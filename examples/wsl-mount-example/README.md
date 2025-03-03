# OpenWebUI WSL Mount Example

Этот пример демонстрирует, как настроить OpenWebUI для использования физического диска, проброшенного из Windows в WSL.

## Описание

В данном примере показано, как:
1. Использовать hostPath вместо PVC для хранения данных OpenWebUI
2. Монтировать директорию `/mnt/u` из WSL в контейнер OpenWebUI
3. Настроить Kubernetes для работы с физическими дисками Windows

## Подготовка WSL

1. Убедитесь, что директория `/mnt/u` доступна в WSL:
   ```bash
   ls -la /mnt/u
   ```

2. Если директория не существует или не содержит нужных файлов, настройте монтирование в WSL:
   ```bash
   # В Windows PowerShell (от администратора)
   wsl --mount \\.\PhysicalDrive1 --partition 1 --type ntfs --name u
   
   # Проверка в WSL
   ls -la /mnt/u
   ```

## Применение конфигурации

1. Примените конфигурацию с помощью Helm:
   ```bash
   helm upgrade --install open-webui ./helm-charts/open-webui -f ./examples/wsl-mount-example/values.yaml -n prod
   ```

2. Проверьте, что под успешно запустился:
   ```bash
   kubectl get pods -n prod -l app=open-webui
   ```

3. Проверьте монтирование:
   ```bash
   kubectl exec -it -n prod $(kubectl get pods -n prod -l app=open-webui -o name) -- ls -la /app/backend/data
   ```

## Примечания

- Убедитесь, что у пользователя, от имени которого запущен Kubernetes, есть права на доступ к директории `/mnt/u`
- При использовании hostPath данные будут доступны только на том узле, где запущен под OpenWebUI
- Для многоузлового кластера рекомендуется использовать nodeSelector или nodeAffinity для запуска пода на конкретном узле