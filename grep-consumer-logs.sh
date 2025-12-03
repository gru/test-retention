#!/usr/bin/env bash

# Скрипт: grep-consumer-logs.sh
# Назначение: искать строки в логах consumer контейнера
#
# Использование:
#   ./grep-consumer-logs.sh "<pattern>"
#
# Примеры:
#   ./grep-consumer-logs.sh "Committed offset"
#   ./grep-consumer-logs.sh "Offset out of range"
#   ./grep-consumer-logs.sh ERROR

set -e

if [[ -z "$1" ]]; then
  echo "Usage: $0 <pattern>"
  exit 1
fi

PATTERN=$1

# Ищем consumer-контейнер по имени
# Docker Compose создаёт его как: <project>_consumer_1
CONSUMER_CONTAINER=$(docker ps -qf "name=consumer")

if [[ -z "$CONSUMER_CONTAINER" ]]; then
  echo "Error: consumer container not found (filter: name=consumer)"
  exit 1
fi

echo "Searching logs of consumer container: $CONSUMER_CONTAINER"
echo "Pattern: \"$PATTERN\""
echo "---------------------------------------------"

# Потоковое grep-ирование логов
docker logs -f "$CONSUMER_CONTAINER" 2>&1 \
  | grep --line-buffered -n --color=always "$PATTERN" || true
