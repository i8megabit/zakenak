# update-windows-hosts.ps1
# Script to update Windows hosts file with entries for Kubernetes services

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator. Please restart PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

# Define the hosts file path
$hostsFile = "$env:windir\System32\drivers\etc\hosts"

# Define the domains to add
$domains = @(
    "dashboard.prod.local",
    "ollama.prod.local",
    "webui.prod.local"
)

# Get the WSL2 IP address
try {
    $wslIP = (wsl hostname -I).Trim()
    
    # If multiple IPs are returned, take the first one
    if ($wslIP -match " ") {
        $wslIP = $wslIP.Split(" ")[0]
    }
    
    if (-not $wslIP) {
        throw "Could not determine WSL2 IP address"
    }
    
    Write-Host "Detected WSL2 IP: $wslIP" -ForegroundColor Green
} catch {
    Write-Host "Error detecting WSL2 IP address: $_" -ForegroundColor Red
    Write-Host "Using localhost (127.0.0.1) as fallback" -ForegroundColor Yellow
    $wslIP = "127.0.0.1"
}

# Read the current hosts file
$hostsContent = Get-Content -Path $hostsFile

# Create a backup of the hosts file
$backupFile = "$env:TEMP\hosts.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item -Path $hostsFile -Destination $backupFile
Write-Host "Hosts file backup created at: $backupFile" -ForegroundColor Green

# Process each domain
foreach ($domain in $domains) {
    # Check if the domain already exists in the hosts file
    $existingEntry = $hostsContent | Where-Object { $_ -match "^\s*\d+\.\d+\.\d+\.\d+\s+$domain\s*$" }
    
    if ($existingEntry) {
        # Update the existing entry
        Write-Host "Updating existing entry for $domain" -ForegroundColor Yellow
        $hostsContent = $hostsContent -replace "^\s*\d+\.\d+\.\d+\.\d+\s+$domain\s*$", "$wslIP $domain"
    } else {
        # Add a new entry
        Write-Host "Adding new entry for $domain" -ForegroundColor Green
        $hostsContent += "`n$wslIP $domain"
    }
}

# Write the updated content back to the hosts file
try {
    $hostsContent | Set-Content -Path $hostsFile -Force
    Write-Host "Hosts file updated successfully" -ForegroundColor Green
} catch {
    Write-Host "Error updating hosts file: $_" -ForegroundColor Red
    Write-Host "Please check if the file is locked or if you have sufficient permissions" -ForegroundColor Red
    exit 1
}

# Flush the DNS cache
try {
    Write-Host "Flushing DNS cache..." -ForegroundColor Yellow
    Clear-DnsClientCache
    Write-Host "DNS cache flushed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error flushing DNS cache: $_" -ForegroundColor Red
}

Write-Host "`nSetup completed successfully!" -ForegroundColor Green
Write-Host "You should now be able to access:" -ForegroundColor Cyan
Write-Host "- https://dashboard.prod.local" -ForegroundColor Cyan
Write-Host "- https://ollama.prod.local" -ForegroundColor Cyan
Write-Host "- https://webui.prod.local" -ForegroundColor Cyan