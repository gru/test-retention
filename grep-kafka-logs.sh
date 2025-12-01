#!/usr/bin/env bash

# Скрипт: grep-kafka-logs.sh
# Назначение: грепать логи Kafka через "docker logs", без доступа к файлам контейнера.
#
# Использование:
#   ./grep-kafka-logs.sh <pattern>
#
# Примеры:
#   ./grep-kafka-logs.sh "Deleted segment"
#   ./grep-kafka-logs.sh LogCleaner
#   ./grep-kafka-logs.sh OffsetOutOfRange

set -e

if [[ -z "$1" ]]; then
  echo "Usage: $0 <pattern>"
  exit 1
fi

PATTERN=$1

# Находим Kafka контейнер по имени
KAFKA_CONTAINER=$(docker ps -qf "name=kafka")

if [[ -z "$KAFKA_CONTAINER" ]]; then
  echo "Error: Kafka container not found (filter: name=kafka)"
  exit 1
fi

echo "Searching logs of container: $KAFKA_CONTAINER"
echo "Pattern: \"$PATTERN\""
echo "---------------------------------------------"

# Грепаем через docker logs
docker logs "$KAFKA_CONTAINER" 2>&1 | grep -n --color=always "$PATTERN" || true
