#!/usr/bin/env bash

set -e

if [[ -z "$1" ]]; then
  echo "Usage: $0 <topic> [messages_per_second] [broker]"
  echo ""
  echo "  <topic>                — Kafka topic to consume"
  echo "  [messages_per_second]  — -1 = no pauses (default), or read N messages then sleep 1s"
  echo "  [broker]               — Kafka broker (default: localhost:9092)"
  exit 1
fi

TOPIC=$1
MSG_PER_SEC=${2:--1}           # второй параметр
BROKER=${3:-localhost:9092}    # третий параметр

echo "Consuming messages from topic '${TOPIC}'..."
echo "Broker: ${BROKER}"
echo "Messages per second limit: ${MSG_PER_SEC}"
echo

TOTAL_BYTES=0
CONSUMED_MESSAGES=0
CURRENT_BATCH=0   # messages read during this 1-second window

consume_line() {
    local line="$1"

    # Size including newline
    local BYTES=$(printf "%s\n" "$line" | wc -c)

    TOTAL_BYTES=$((TOTAL_BYTES + BYTES))
    CONSUMED_MESSAGES=$((CONSUMED_MESSAGES + 1))

    # 🔥 Логирование на каждой итерации:
    echo "Read total ${TOTAL_BYTES} bytes"

    # throttling if MSG_PER_SEC != -1
    if [[ "$MSG_PER_SEC" -ne -1 ]]; then
        CURRENT_BATCH=$((CURRENT_BATCH + 1))
        if [[ "$CURRENT_BATCH" -ge "$MSG_PER_SEC" ]]; then
            CURRENT_BATCH=0
            sleep 1
        fi
    fi
}

# Read messages from Kafka
while IFS= read -r line; do
    consume_line "$line"
done < <(
  docker exec -i $(docker ps -qf "name=kafka") \
    kafka-console-consumer \
      --bootstrap-server "$BROKER" \
      --topic "$TOPIC" \
      --from-beginning \
      --timeout-ms 5000
)

TOTAL_MB=$(awk "BEGIN { printf \"%.2f\", $TOTAL_BYTES / (1024 * 1024) }")

echo
echo "Messages consumed: ${CONSUMED_MESSAGES}"
echo "Total bytes consumed: ${TOTAL_BYTES} bytes"
echo "Total size: ${TOTAL_MB} MB"
