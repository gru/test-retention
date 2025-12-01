#!/usr/bin/env bash

# Скрипт: produce-messages.sh
# Использование:
#   ./produce-messages.sh <MB> <topic> [message_size_bytes] [broker]
#
# Примеры:
#   ./produce-messages.sh 10 test-ret-bytes
#   ./produce-messages.sh 5 test-ret-bytes 2048
#   ./produce-messages.sh 5 test-ret-bytes 2048 localhost:9092

set -e

if [[ -z "$1" || -z "$2" ]]; then
  echo "Usage: $0 <MB> <topic> [message_size_bytes] [broker]"
  exit 1
fi

MB=$1
TOPIC=$2
MSG_SIZE=${3:-1024}       # "размер сообщения" в байтах (примерно, без учёта \n)
BROKER=${4:-localhost:9092}

# Переводим MB → байты
TARGET_BYTES=$((MB * 1024 * 1024))

# Сколько сообщений нужно отправить
MSG_COUNT=$((TARGET_BYTES / MSG_SIZE))

echo "Producing ~${MB}MB of data to topic '${TOPIC}'..."
echo "Approx message size (without newline): ${MSG_SIZE} bytes"
echo "Messages to send: ${MSG_COUNT}"
echo "Broker: ${BROKER}"
echo

# Находим контейнер с Kafka один раз
KAFKA_CONTAINER=$(docker ps -qf "name=kafka")

if [[ -z "$KAFKA_CONTAINER" ]]; then
  echo "Error: Kafka container not found (name filter: 'kafka')."
  exit 1
fi

# Один docker exec, один kafka-console-producer
docker exec -i "$KAFKA_CONTAINER" bash -c "
  MSG_COUNT=$MSG_COUNT
  MSG_SIZE=$MSG_SIZE
  TOPIC='$TOPIC'
  BROKER='$BROKER'

  echo \"[inside container] Generating \$MSG_COUNT messages...\"

  # Генерим сообщения и сразу отправляем в kafka-console-producer
  for ((i=1; i<=MSG_COUNT; i++)); do
    PREFIX=\"msg-\$i \"
    PREFIX_LEN=\${#PREFIX}

    # Сколько символов 'X' добавить, чтобы payload был примерно MSG_SIZE байт.
    # Newline добавляет ещё 1 байт сверху — для нашей задачи ОК.
    FILL_SIZE=\$((MSG_SIZE - PREFIX_LEN))
    if (( FILL_SIZE < 0 )); then
      echo \"Error: message_size_bytes=\$MSG_SIZE too small, must be >= \$PREFIX_LEN\" >&2
      exit 1
    fi

    FILL=\$(head -c \"\$FILL_SIZE\" < /dev/zero | tr '\\0' 'X')
    printf '%s%s\n' \"\$PREFIX\" \"\$FILL\"
  done | kafka-console-producer --broker-list \"\$BROKER\" --topic \"\$TOPIC\" 1>/dev/null
"

echo "Done!"
