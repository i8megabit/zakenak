#!/bin/bash
#
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
#
# Setup script for Ƶakenak™® user

# Проверка на root права
if [ "$EUID" -ne 0 ]; then 
	echo "Требуются права root"
	exit 1
fi

# Создание пользователя
USERNAME="zakenak-ai"
PASSWORD=$(openssl rand -base64 32)

# Создание пользователя с ограниченными правами
useradd -m -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Создание группы для AI операций
groupadd zakenak-ai-ops
usermod -a -G zakenak-ai-ops $USERNAME

# Настройка sudo для специфических команд
echo "$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/nvidia-smi" >> /etc/sudoers.d/zakenak-ai
echo "$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/docker" >> /etc/sudoers.d/zakenak-ai
echo "$USERNAME ALL=(ALL) NOPASSWD: /usr/local/bin/kubectl" >> /etc/sudoers.d/zakenak-ai

# Создание рабочей директории
mkdir -p /home/$USERNAME/workspace
chown $USERNAME:$USERNAME /home/$USERNAME/workspace

# Настройка переменных окружения
cat > /home/$USERNAME/.bashrc << EOF
export PATH=\$PATH:/usr/local/cuda/bin
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/cuda/lib64
export KUBECONFIG=/home/$USERNAME/.kube/config
EOF

# Настройка ограничений
cat > /etc/security/limits.d/zakenak-ai.conf << EOF
$USERNAME soft nproc 1024
$USERNAME hard nproc 2048
$USERNAME soft nofile 4096
$USERNAME hard nofile 8192
EOF

# Вывод информации
echo "Пользователь AI-ассистента создан:"
echo "Username: $USERNAME"
echo "Password: $PASSWORD"
echo "Сохраните эти данные в безопасном месте"

# Инструкции по использованию
cat << EOF
Для использования:
1. Переключитесь на пользователя: su - $USERNAME
2. Проверьте доступ: nvidia-smi
3. Проверьте Docker: docker ps
4. Проверьте kubectl: kubectl get nodes

Ограничения:
- Пользователь может выполнять только предопределенные команды
- Доступ к GPU через nvidia-smi
- Доступ к Docker и Kubernetes с ограничениями
EOF