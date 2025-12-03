#!/usr/bin/env bash

set -e

if [[ -z "$1" || -z "$2" ]]; then
  echo "Usage: $0 <group-id> <topic> [broker]"
  echo "Example: $0 test-group test-topic"
  exit 1
fi

GROUP=$1
TOPIC=$2
BROKER=${3:-localhost:9092}

echo "Consumer Group Offsets:"
echo "  Group: $GROUP"
echo "  Topic: $TOPIC"
echo "  Broker: $BROKER"
echo

KAFKA_CONTAINER=$(docker ps -qf "name=kafka")
if [[ -z "$KAFKA_CONTAINER" ]]; then
  echo "Kafka container not found!"
  exit 1
fi

echo "=== Group Offsets (kafka-consumer-groups) ==="
docker exec -it "$KAFKA_CONTAINER" \
  kafka-consumer-groups \
    --bootstrap-server "$BROKER" \
    --group "$GROUP" \
    --describe

echo
echo "=== Topic Earliest Offset ==="
docker exec -it "$KAFKA_CONTAINER" \
  kafka-run-class kafka.tools.GetOffsetShell \
    --broker-list "$BROKER" \
    --topic "$TOPIC" \
    --time -2

echo
echo "=== Topic Latest Offset ==="
docker exec -it "$KAFKA_CONTAINER" \
  kafka-run-class kafka.tools.GetOffsetShell \
    --broker-list "$BROKER" \
    --topic "$TOPIC" \
    --time -1

echo
echo "Done."
