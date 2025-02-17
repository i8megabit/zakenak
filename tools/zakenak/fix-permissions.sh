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

# Исправление прав доступа для git репозитория
sudo chown -R $(whoami):$(whoami) /home/i8megabit/gitops
sudo chmod -R u+rwX /home/i8megabit/gitops
sudo chmod -R g+rwX /home/i8megabit/gitops
sudo chmod -R o-rwx /home/i8megabit/gitops

# Исправление прав для .git директории
sudo chmod -R 775 /home/i8megabit/gitops/.git
sudo chown -R $(whoami):$(whoami) /home/i8megabit/gitops/.git/objects

# Убедимся, что скрипты исполняемые
find /home/i8megabit/gitops -type f -name "*.sh" -exec chmod +x {} \;

echo "Права доступа успешно обновлены"