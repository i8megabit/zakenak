#!/bin/bash
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# 
# This file is part of Zakenak project.
# https://github.com/i8megabit/zakenak
#
# This program is free software and is released under the terms of the MIT License.
# See LICENSE.md file in the project root for full license information.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Шаблоны заголовков
GO_HEADER='/*
 * Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
 * 
 * This file is part of Zakenak project.
 * https://github.com/i8megabit/zakenak
 *
 * This program is free software and is released under the terms of the MIT License.
 * See LICENSE.md file in the project root for full license information.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 */\n\n'

MD_HEADER='# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# 
# This file is part of Zakenak project.
# https://github.com/i8megabit/zakenak
#
# This program is free software and is released under the terms of the MIT License.
# See LICENSE.md file in the project root for full license information.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

SH_HEADER='#!/bin/bash
#
# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# 
# This file is part of Zakenak project.
# https://github.com/i8megabit/zakenak
#
# This program is free software and is released under the terms of the MIT License.
# See LICENSE.md file in the project root for full license information.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.\n\n'

YAML_HEADER='# Copyright (c) 2023-2025 Mikhail Eberil (@eberil)
# 
# This file is part of Zakenak project.
# https://github.com/i8megabit/zakenak
#
# This program is free software and is released under the terms of the MIT License.
# See LICENSE.md file in the project root for full license information.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

update_file() {
	local file=$1
	local temp_file=$(mktemp)
	local ext="${file##*.}"
	local header

	case "$ext" in
		go)
			header="$GO_HEADER"
			;;
		md|markdown)
			header="$MD_HEADER"
			;;
		sh)
			header="$SH_HEADER"
			;;
		yaml|yml)
			header="$YAML_HEADER"
			;;
		*)
			echo -e "${RED}Неподдерживаемое расширение файла: $ext${NC}"
			return 1
			;;
	esac

	# Удаляем существующий заголовок, если он есть
	if [[ "$ext" == "sh" ]]; then
		# Сохраняем shebang
		head -n 1 "$file" > "$temp_file"
		echo -e "$header" >> "$temp_file"
		tail -n +2 "$file" | sed '/^#.*Copyright/,/^#.*owner.$/d' >> "$temp_file"
	else
		echo -e "$header" > "$temp_file"
		sed '/^[/#].*Copyright/,/^[/#].*owner.$/d' "$file" >> "$temp_file"
	fi

	mv "$temp_file" "$file"
	echo -e "${GREEN}Обновлен заголовок в файле: $file${NC}"
}

# Обновление всех файлов в репозитории
find . -type f \( -name "*.go" -o -name "*.md" -o -name "*.sh" -o -name "*.yaml" -o -name "*.yml" \) -not -path "*/\.*" -not -path "*/vendor/*" | while read -r file; do
	update_file "$file"
done

echo -e "${GREEN}Все файлы обновлены!${NC}"