# GitHub Actions Secrets Setup

```ascii
     ______     _                      _    
    |___  /    | |                    | |   
       / / __ _| |  _ _   ___     ___ | |  _
      / / / _` | |/ / _`||  _ \ / _` || |/ /
     / /_| (_| |  < by_Eberil| | (_| ||   < 
    /_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\
  
    Should Harbour?	No.

## Обязательные секреты
1. `GITHUB_TOKEN` - автоматически предоставляется GitHub
2. `PAT_TOKEN` - Personal Access Token (настроен)
3. `KUBECONFIG` - конфигурация доступа к Kubernetes кластеру

## Настройка KUBECONFIG
1. Сгенерируйте kubeconfig:
```bash
./tools/zakenak/scripts/generate-kubeconfig.sh
```

2. Добавьте содержимое kubeconfig.yaml в секреты:
   - Перейдите в Settings -> Secrets -> Actions
   - Создайте новый секрет с именем KUBECONFIG
   - Вставьте содержимое файла kubeconfig.yaml

3. Проверьте настройку:
   - Запустите workflow вручную
   - Убедитесь, что этап деплоя успешно подключается к кластеру

## Безопасность
- Не коммитьте kubeconfig.yaml в репозиторий
- Регулярно обновляйте сертификаты
- Используйте минимально необходимые права доступа

