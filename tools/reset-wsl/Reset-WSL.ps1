function Reset-WSL {
	Write-Host "Начинаем процесс полного сброса WSL..." -ForegroundColor Yellow
	
	# Останавливаем все процессы WSL
	Write-Host "Останавливаем WSL..." -ForegroundColor Cyan
	wsl --shutdown
	
	# Завершаем процессы LxssManager
	Write-Host "Завершаем процессы LxssManager..." -ForegroundColor Cyan
	Get-Process -Name "LxssManager" -ErrorAction SilentlyContinue | Stop-Process -Force
	
	# Удаляем все дистрибутивы
	Write-Host "Удаляем все дистрибутивы WSL..." -ForegroundColor Cyan
	wsl --unregister Ubuntu 2>$null
	wsl --unregister Debian 2>$null
	wsl --unregister kali-linux 2>$null
	wsl --unregister openSUSE-42 2>$null
	wsl --unregister SLES-12 2>$null
	wsl --unregister Ubuntu-18.04 2>$null
	wsl --unregister Ubuntu-20.04 2>$null
	wsl --unregister docker-desktop 2>$null
	wsl --unregister docker-desktop-data 2>$null
	
	# Отключаем компонент Windows
	Write-Host "Отключаем компонент Windows Subsystem for Linux..." -ForegroundColor Cyan
	Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
	
	# Включаем компонент Windows обратно
	Write-Host "Включаем компонент Windows Subsystem for Linux..." -ForegroundColor Cyan
	Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
	
	# Устанавливаем WSL2
	Write-Host "Устанавливаем WSL2..." -ForegroundColor Cyan
	wsl --set-default-version 2
	
	# Устанавливаем Ubuntu (можно изменить на другой дистрибутив)
	Write-Host "Устанавливаем Ubuntu..." -ForegroundColor Cyan
	wsl --install -d Ubuntu
	
	Write-Host "Процесс сброса WSL завершен. Система готова к использованию." -ForegroundColor Green
	Write-Host "Примечание: Может потребоваться перезагрузка компьютера для применения всех изменений." -ForegroundColor Yellow
}

# Запускаем функцию
Reset-WSL