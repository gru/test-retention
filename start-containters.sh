#!/usr/bin/env bash
set -e

COMPOSE_FILE="docker-compose.yaml"
BROKER="localhost:9092"
TOPIC="test-ret-bytes"

echo "Stopping environment..."
docker compose -f "$COMPOSE_FILE"  --profile slow-consumer down --remove-orphans || true
docker compose -f "$COMPOSE_FILE"  --profile slow-consumer down -v || true
docker volume prune -f || true

echo ""
echo "Rebuilding slow-consumer..."
docker compose --profile slow-consumer build --no-cache

echo ""
echo "Starting base services..."
docker compose up -d

# Determine Kafka container id
KAFKA_CONTAINER=$(docker compose ps -q kafka)
if [[ -z "$KAFKA_CONTAINER" ]]; then
  echo "Kafka container not found"
  exit 1
fi

echo ""
echo "Waiting for Kafka..."
sleep 5

echo ""
echo "Creating topic $TOPIC..."
docker exec -i "$KAFKA_CONTAINER" \
  kafka-topics --create \
  --topic "$TOPIC" \
  --bootstrap-server "$BROKER" \
  --partitions 1 \
  --replication-factor 1 \
  || echo "Topic may already exist"

echo ""
echo "Describing topic..."
docker exec -i "$KAFKA_CONTAINER" \
  kafka-topics --bootstrap-server "$BROKER" \
    --describe --topic "$TOPIC"

echo ""
echo "Starting slow-consumer..."
docker compose --profile slow-consumer up -d

sleep 5

echo ""
echo "Consumer started."
echo "Consumer Logs:"
docker compose --profile slow-consumer logs consumer

