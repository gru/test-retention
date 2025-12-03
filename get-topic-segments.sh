#!/usr/bin/env bash

# Скрипт: get-topic-segments.sh
# Показывает размеры сегментов Kafka-топика, совместимо с cp-kafka (нет "find").

set -e

if [[ -z "$1" ]]; then
  echo "Usage: $0 <topic>"
  exit 1
fi

TOPIC="$1"

KAFKA_CONTAINER=$(docker ps -qf "name=kafka")

if [[ -z "$KAFKA_CONTAINER" ]]; then
  echo "Error: Kafka container not found"
  exit 1
fi

echo "Kafka container: $KAFKA_CONTAINER"
echo "Topic: $TOPIC"
echo "----------------------------------------"

# Путь к логам Kafka в confluent images
LOG_DIR="/var/lib/kafka/data"

docker exec -i "$KAFKA_CONTAINER" bash -c "
  set -e

  # Ищем каталоги партиций (только через ls/grep)
  PARTITIONS=\$(ls -1 $LOG_DIR | grep '^${TOPIC}-')

  if [[ -z \"\$PARTITIONS\" ]]; then
    echo 'Topic directories not found'
    exit 0
  fi

  for p in \$PARTITIONS; do
    PART_PATH=\"$LOG_DIR/\$p\"
    echo \"Partition directory: \$PART_PATH\" 

    echo \"Segment files:\"
    ls -lh \"\$PART_PATH\"/*.log 2>/dev/null || echo '  (no .log files found)'

    echo -n \"Total size: \"
    # stat работает, даже если нет find
    TOTAL=0
    for f in \"\$PART_PATH\"/*.log; do
      if [[ -f \"\$f\" ]]; then
        SZ=\$(stat -c%s \"\$f\")
        TOTAL=\$((TOTAL + SZ))
      fi
    done
    echo \"\$TOTAL bytes\"
    echo
  done
"
