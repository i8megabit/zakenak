# Reset-WSL
```ascii
 ______     _                      _    
|___  /    | |                    | |   
   / / __ _| |  _ _   ___     ___ | |  _
  / / / _` | |/ / _`||  _ \ / _` || |/ /
 / /_| (_| |  < by_Eberil| | (_| ||   < 
/_____\__,_|_|\_\__,||_| |_|\__,_||_|\_\

Should Harbour?	No.
```
Версия: 1.0.2

Инструмент для полного сброса и переустановки Windows Subsystem for Linux (WSL).

## Описание
Скрипт автоматизирует процесс полного сброса WSL, включая удаление существующих дистрибутивов и переустановку компонентов.

## Возможности
- Автоматическое завершение всех процессов WSL
- Удаление всех существующих дистрибутивов
- Переустановка компонента Windows Subsystem for Linux
- Установка WSL2 и Ubuntu по умолчанию

## Требования
- Windows 10/11
- Права администратора
- PowerShell 5.1 или выше

## Использование
1. Запустите PowerShell от имени администратора
2. Перейдите в директорию со скриптом
3. Выполните команду: 
```powershell
.\Reset-WSL.ps1 
```
4. По окончанию работ, выполните команду запуска нового дистра WSL в терминале powershell
```
wsl.exe -d Ubuntu
```
## Примечания
- После выполнения может потребоваться перезагрузка системы
- По умолчанию устанавливается Ubuntu, но можно изменить на другой дистрибутив в коде скрипта

### Пример выполнения
Начинаем процесс полного сброса WSL...                                                                                                                                                 Останавливаем WSL...                                                                                                                                                                   
Завершаем процессы LxssManager...
Удаляем все дистрибутивы WSL...

Отсутствует распределение с указанным именем.
Error code: Wsl/Service/WSL_E_DISTRO_NOT_FOUND
Отсутствует распределение с указанным именем.
Error code: Wsl/Service/WSL_E_DISTRO_NOT_FOUND
Отсутствует распределение с указанным именем.
Error code: Wsl/Service/WSL_E_DISTRO_NOT_FOUND
Отсутствует распределение с указанным именем.
Error code: Wsl/Service/WSL_E_DISTRO_NOT_FOUND
Отсутствует распределение с указанным именем.
Error code: Wsl/Service/WSL_E_DISTRO_NOT_FOUND
Отсутствует распределение с указанным именем.
Error code: Wsl/Service/WSL_E_DISTRO_NOT_FOUND
Отсутствует распределение с указанным именем.
Error code: Wsl/Service/WSL_E_DISTRO_NOT_FOUND
Отсутствует распределение с указанным именем.
Error code: Wsl/Service/WSL_E_DISTRO_NOT_FOUND
Отсутствует распределение с указанным именем.
Error code: Wsl/Service/WSL_E_DISTRO_NOT_FOUND
Отключаем компонент Windows Subsystem for Linux...
ПРЕДУПРЕЖДЕНИЕ: Перезапуск подавлен, так как задан параметр NoRestart.


Path          :
Online        : True
RestartNeeded : True

Включаем компонент Windows Subsystem for Linux...
ПРЕДУПРЕЖДЕНИЕ: Перезапуск подавлен, так как задан параметр NoRestart.
Path          :
Online        : True
RestartNeeded : True

Устанавливаем WSL2...
Для получения сведений о ключевых различиях с WSL 2 перейдите на страницу https://aka.ms/wsl2

Операция успешно завершена.
Устанавливаем Ubuntu...
Скачивание: Ubuntu
[======                    10,9%                           ]

## Ошибки при выполнении скрипта
Если имеет место быть ограничение политики выполнения, решается элегантно:
1. Откройте powershell ISE от имени администратора
2. Вставьте код из Reset-WSL.ps1 в белое поле выполнения
3. Выполнение скрипта предложит сохранить этот скрипт куда-нибудь. Просто перезапишите Reset-WSL.ps1. После этого, выполнение скрипта будет проходить беспрепятственно IDE

```plain text
Copyright (c) 2023-2025 Mikhail Eberil (@eberil)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```