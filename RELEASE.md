# Релизы Ƶakӗnak™®
```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```

## Версии

### [1.0.0] - 2025-01-20

#### 🎉 Первый стабильный релиз
Представляем первый стабильный релиз Ƶakӗnak™® — профессионального инструмента GitOps для эффективной оркестрации Kubernetes-кластеров с поддержкой GPU через Helm.

#### ✨ Ключевые компоненты

##### Core Services
- 🔐 Полная интеграция cert-manager для TLS
- 📜 Встроенный local-ca центр сертификации
- 🔄 Система инжекции TLS прокси

##### AI/GPU Services
- 🧠 Интеграция Ollama с GPU-ускорением
- 🎮 Поддержка open-webui для LLM
- ⚡ Оптимизированная работа с NVIDIA в WSL2

##### Infrastructure
- 🎯 NVIDIA device plugin
- 🌐 Оптимизированный CoreDNS
- 🚪 Ingress с TLS по умолчанию

##### Security
- 🛡️ Network Policies из коробки
- 👥 Предустановленный RBAC
- 🔒 Безопасное хранение секретов

#### 🔧 Требования
- Go 1.21+
- WSL2 (Ubuntu 22.04 LTS)
- Docker + NVIDIA Runtime
- NVIDIA GPU (драйверы 535.104.05+)
- CUDA Toolkit 12.8
- Kind v0.20.0+
- Helm 3.0+

#### 📝 Изменения

##### Добавлено
- 📦 Единый самодостаточный бинарный файл
- 🔄 Встроенный GitOps и конвергенция
- 🐳 Интеграция с container registry
- 🖥️ Нативная поддержка WSL2/GPU
- 📋 Система шаблонизации
- 📚 Полная документация

##### Безопасность
- 🔑 RBAC из коробки
- 🗄️ Безопасное хранение креденшелов
- ✅ Валидация конфигураций
- 🔒 TLS везде по умолчанию

#### ⚠️ Известные ограничения
- WSL2: может потребоваться ручная настройка NVIDIA
- GPU: ограничения shared-режима для multiple GPU

#### 📚 Документация
- [Руководство пользователя](docs/)
- [Примеры конфигураций](examples/)
- [API Reference](docs/api.md)

[1.0.0]: https://github.com/i8megabit/zakenak/releases/tag/v1.0.0

```plain text
Copyright (c) 2025 Mikhail Eberil

This file is part of Zakenak project and is released under the terms of the MIT License. 
See LICENSE file in the project root for full license information.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT.

The name "Zakenak" and associated branding are trademarks of @eberil and may not be 
used without express written permission.
```