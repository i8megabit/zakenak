#!/bin/bash
set -e

echo "Начало обновления резюме на hh.ru"
echo "Время запуска: $(date)"

# Проверка наличия переменных окружения
if [ -z "$HH_API_TOKEN" ]; then
  echo "Ошибка: Переменная окружения HH_API_TOKEN не установлена"
  exit 1
fi

if [ -z "$HH_RESUME_ID" ]; then
  echo "Ошибка: Переменная окружения HH_RESUME_ID не установлена"
  exit 1
fi

# Обновление резюме через API
echo "Обновление резюме с ID: $HH_RESUME_ID"

# Запрос к API для обновления резюме
RESPONSE=$(curl -s -X PUT \
  -H "Authorization: Bearer $HH_API_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.hh.ru/resumes/$HH_RESUME_ID/publish")

# Проверка результата
if echo "$RESPONSE" | grep -q "error"; then
  echo "Ошибка при обновлении резюме: $RESPONSE"
  exit 1
else
  echo "Резюме успешно обновлено"
  echo "Результат: $RESPONSE"
  
  # Сохранение информации об обновлении
  echo "$(date) - Успешное обновление" >> /app/resume/update-history.log
fi

echo "Обновление завершено: $(date)"