#!/bin/bash

# Версия приложения
VERSION=${1:-"dev"}

# Создаем директорию для бинарных файлов
mkdir -p build

# Список целевых платформ
PLATFORMS=(
	"linux/amd64"
	"linux/arm64"
	"windows/amd64"
	"darwin/amd64"
	"darwin/arm64"
)

# Компиляция для каждой платформы
for PLATFORM in "${PLATFORMS[@]}"; do
	# Разделяем OS и ARCH
	OS=${PLATFORM%/*}
	ARCH=${PLATFORM#*/}
	
	echo "Building for $OS/$ARCH..."
	
	# Формируем имя выходного файла
	OUTPUT="build/zakenak-$OS-$ARCH"
	if [ "$OS" = "windows" ]; then
		OUTPUT="${OUTPUT}.exe"
	fi
	
	# Компилируем
	GOOS=$OS GOARCH=$ARCH go build \
		-o "$OUTPUT" \
		-ldflags="-X main.Version=$VERSION" \
		./tools/zakenak/cmd/zakenak
	
	if [ $? -eq 0 ]; then
		echo "✓ Successfully built $OUTPUT"
	else
		echo "✗ Failed to build for $OS/$ARCH"
		exit 1
	fi
done

echo "All builds completed!"