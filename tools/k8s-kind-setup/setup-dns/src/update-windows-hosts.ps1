# update-windows-hosts.ps1
# Скрипт обновляет файл hosts Windows, добавляя записи для сервисов Kubernetes

# Проверяем, запущен ли скрипт от имени администратора
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Скрипт должен быть запущен от имени администратора. Перезапустите PowerShell и попробуйте снова." -ForegroundColor Red
    exit 1
}

# Путь к файлу hosts
$hostsFile = "$env:windir\System32\drivers\etc\hosts"

# Домены, которые нужно добавить
$domains = @(
    "dashboard.prod.local",
    "ollama.prod.local",
    "webui.prod.local"
)

# Получаем IP адрес WSL2
try {
    $wslIP = (wsl hostname -I).Trim()
    
    # Если вернулось несколько IP, берем первый
    if ($wslIP -match " ") {
        $wslIP = $wslIP.Split(" ")[0]
    }
    
    if (-not $wslIP) {
        throw "Не удалось определить IP адрес WSL2"
    }
    
    Write-Host "Обнаружен IP WSL2: $wslIP" -ForegroundColor Green
} catch {
    Write-Host "Ошибка при определении IP WSL2: $_" -ForegroundColor Red
    Write-Host "Использую localhost (127.0.0.1)" -ForegroundColor Yellow
    $wslIP = "127.0.0.1"
}

# Читаем текущий hosts
$hostsContent = Get-Content -Path $hostsFile

# Создаем резервную копию hosts
$backupFile = "$env:TEMP\hosts.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item -Path $hostsFile -Destination $backupFile
Write-Host "Резервная копия hosts создана: $backupFile" -ForegroundColor Green

# Обрабатываем каждый домен
foreach ($domain in $domains) {
    # Проверяем, есть ли уже домен в hosts
    $existingEntry = $hostsContent | Where-Object { $_ -match "^\s*\d+\.\d+\.\d+\.\d+\s+$domain\s*$" }
    
    if ($existingEntry) {
        # Обновляем существующую запись
        Write-Host "Обновляю запись для $domain" -ForegroundColor Yellow
        $hostsContent = $hostsContent -replace "^\s*\d+\.\d+\.\d+\.\d+\s+$domain\s*$", "$wslIP $domain"
    } else {
        # Добавляем новую запись
        Write-Host "Добавляю запись для $domain" -ForegroundColor Green
        $hostsContent += "`n$wslIP $domain"
    }
}

# Записываем изменения в hosts
try {
    $hostsContent | Set-Content -Path $hostsFile -Force
    Write-Host "Файл hosts успешно обновлен" -ForegroundColor Green
} catch {
    Write-Host "Ошибка при обновлении hosts: $_" -ForegroundColor Red
    Write-Host "Проверьте, не заблокирован ли файл и хватает ли прав" -ForegroundColor Red
    exit 1
}

# Сброс кэша DNS
try {
    Write-Host "Сбрасываю DNS кэш..." -ForegroundColor Yellow
    Clear-DnsClientCache
    Write-Host "DNS кэш успешно сброшен" -ForegroundColor Green
} catch {
    Write-Host "Ошибка при сбросе DNS кэша: $_" -ForegroundColor Red
}

Write-Host "`nНастройка завершена" -ForegroundColor Green
Write-Host "Теперь доступны:" -ForegroundColor Cyan
Write-Host "- https://dashboard.prod.local" -ForegroundColor Cyan
Write-Host "- https://ollama.prod.local" -ForegroundColor Cyan
Write-Host "- https://webui.prod.local" -ForegroundColor Cyan