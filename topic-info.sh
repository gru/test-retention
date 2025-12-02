#!/usr/bin/env bash

set -e

if [[ -z "$1" ]]; then
  echo "Usage: $0 <topic> [broker]"
  echo "Example: $0 test-ret-bytes"
  exit 1
fi

TOPIC=$1
BROKER=${2:-localhost:9092}

KAFKA_CONTAINER=$(docker ps -qf "name=kafka")

if [[ -z "$KAFKA_CONTAINER" ]]; then
  echo "Error: Kafka container not found (filter: name=kafka)"
  exit 1
fi

echo "Fetching topic description for '${TOPIC}'..."
echo "Broker: $BROKER"
echo

docker exec -it "$KAFKA_CONTAINER" \
  kafka-topics --bootstrap-server localhost:9092 \
    --describe --topic test-ret-bytes
