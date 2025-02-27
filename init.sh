#!/bin/bash

# Get the absolute path of the repository root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Adding repository directories to PATH..."

# Find all directories in the repository and add them to PATH
export PATH="$PATH:$(find "$REPO_ROOT" -type d | tr '\n' ':')"

echo "Repository directories added to PATH."
echo "You can now use scripts like deploy-all.sh and charts.sh from anywhere in this session."
echo "Repository root: $REPO_ROOT"

# List some of the available scripts for reference
echo -e "\nAvailable scripts:"
find "$REPO_ROOT" -name "*.sh" -type f -executable | sort | while read -r script; do
    echo "- $(basename "$script")"
done

echo -e "\nTo use a script, simply type its name (e.g., 'charts.sh' or 'deploy-all.sh')"