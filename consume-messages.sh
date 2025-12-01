#!/usr/bin/env bash

set -e

if [[ -z "$1" ]]; then
  echo "Usage: $0 <topic> [broker]"
  exit 1
fi

TOPIC=$1
BROKER=${2:-localhost:9092}

echo "Consuming all messages from topic '${TOPIC}'..."
echo "Broker: ${BROKER}"
echo

TOTAL_BYTES=0
CONSUMED_MESSAGES=0

# Читаем все сообщения (таймаут 5 сек без данных)
while IFS= read -r line; do
    BYTES=$(printf "%s\n" "$line" | wc -c)
    TOTAL_BYTES=$((TOTAL_BYTES + BYTES))
    CONSUMED_MESSAGES=$((CONSUMED_MESSAGES + 1))
done < <(
  docker exec -i $(docker ps -qf "name=kafka") \
    kafka-console-consumer \
      --bootstrap-server "$BROKER" \
      --topic "$TOPIC" \
      --from-beginning \
      --timeout-ms 5000
)

# Форматируем в MB (1 MB = 1024 * 1024 bytes)
TOTAL_MB=$(awk "BEGIN { printf \"%.2f\", $TOTAL_BYTES / (1024 * 1024) }")

echo "Messages consumed: ${CONSUMED_MESSAGES}"
echo "Total bytes consumed: ${TOTAL_BYTES} bytes"
echo "Total size: ${TOTAL_MB} MB"
