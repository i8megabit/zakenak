#!/bin/bash

# Исправление прав доступа для git репозитория
sudo chown -R $(whoami):$(whoami) /home/i8meg/gitops
sudo chmod -R u+rwX /home/i8meg/gitops
sudo chmod -R g+rwX /home/i8meg/gitops
sudo chmod -R o-rwx /home/i8meg/gitops

# Исправление прав для .git директории
sudo chmod -R 775 /home/i8meg/gitops/.git
sudo chown -R $(whoami):$(whoami) /home/i8meg/gitops/.git/objects

# Убедимся, что скрипты исполняемые
find /home/i8meg/gitops -type f -name "*.sh" -exec chmod +x {} \;

echo "Права доступа успешно обновлены"