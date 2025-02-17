# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# 
# This file is part of Ƶakenak™® project.
# https://github.com/i8megabit/zakenak
#
# This program is free software and is released under the terms of the MIT License.
# See LICENSE.md file in the project root for full license information.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#
# TRADEMARK NOTICE:
# Ƶakenak™® and the Ƶakenak logo are registered trademarks of Mikhail Eberil.
# All rights reserved. The Ƶakenak trademark and brand may not be used in any way 
# without express written permission from the trademark owner.


# GitHub Actions Secrets Setup

```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```
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