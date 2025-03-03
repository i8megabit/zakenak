#!/usr/bin/bash

# Script to help users update Windows hosts file from WSL

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if running in WSL
if ! grep -q "microsoft" /proc/version && ! grep -q "WSL" /proc/version; then
    echo -e "${RED}This script must be run in WSL. It's designed to help update the Windows hosts file.${NC}"
    exit 1
fi

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS_SCRIPT="${SCRIPT_DIR}/update-windows-hosts.ps1"

# Check if PowerShell script exists
if [ ! -f "$PS_SCRIPT" ]; then
    echo -e "${RED}PowerShell script not found at: ${PS_SCRIPT}${NC}"
    exit 1
fi

# Get Windows username
WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
if [ -z "$WIN_USER" ]; then
    echo -e "${YELLOW}Could not determine Windows username. Using 'User' as fallback.${NC}"
    WIN_USER="User"
fi

# Copy PowerShell script to Windows temp directory
WIN_TEMP="/mnt/c/Users/${WIN_USER}/AppData/Local/Temp"
if [ ! -d "$WIN_TEMP" ]; then
    echo -e "${YELLOW}Windows temp directory not found at: ${WIN_TEMP}${NC}"
    echo -e "${YELLOW}Trying alternative location...${NC}"
    WIN_TEMP="/mnt/c/Windows/Temp"
    if [ ! -d "$WIN_TEMP" ]; then
        echo -e "${RED}Could not find Windows temp directory. Please run the PowerShell script manually.${NC}"
        echo -e "${CYAN}PowerShell script location: ${PS_SCRIPT}${NC}"
        exit 1
    fi
fi

# Copy the script
WIN_PS_SCRIPT="${WIN_TEMP}/update-windows-hosts.ps1"
cp "$PS_SCRIPT" "$WIN_PS_SCRIPT" 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to copy PowerShell script to Windows temp directory.${NC}"
    echo -e "${CYAN}Please run the PowerShell script manually from: ${PS_SCRIPT}${NC}"
    exit 1
fi

# Convert path to Windows format
WIN_PS_SCRIPT_PATH=$(wslpath -w "$WIN_PS_SCRIPT" 2>/dev/null)
if [ -z "$WIN_PS_SCRIPT_PATH" ]; then
    WIN_PS_SCRIPT_PATH="C:\\Users\\${WIN_USER}\\AppData\\Local\\Temp\\update-windows-hosts.ps1"
fi

echo -e "${GREEN}PowerShell script copied to: ${WIN_PS_SCRIPT_PATH}${NC}"
echo -e "\n${CYAN}To update your Windows hosts file, please:${NC}"
echo -e "${YELLOW}1. Open PowerShell as Administrator in Windows${NC}"
echo -e "${YELLOW}2. Run the following command:${NC}"
echo -e "${CYAN}   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; ${WIN_PS_SCRIPT_PATH}${NC}"

# Try to run the script directly if possible
echo -e "\n${CYAN}Attempting to run the script directly (this may prompt for administrator privileges):${NC}"
powershell.exe -Command "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File \"${WIN_PS_SCRIPT_PATH}\"' -Verb RunAs" 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}PowerShell script launched. Please complete the administrator prompt in Windows.${NC}"
else
    echo -e "${YELLOW}Could not launch PowerShell with administrator privileges automatically.${NC}"
    echo -e "${YELLOW}Please follow the manual steps above.${NC}"
fi

echo -e "\n${CYAN}After running the script, you should be able to access:${NC}"
echo -e "${GREEN}- https://dashboard.prod.local${NC}"
echo -e "${GREEN}- https://ollama.prod.local${NC}"
echo -e "${GREEN}- https://webui.prod.local${NC}"