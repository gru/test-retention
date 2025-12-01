#!/usr/bin/env bash

# Скрипт: reset-kafka.sh
# Назначение: полностью очистить Kafka/Zookeeper контейнеры и их данные.

set -e

COMPOSE_FILE="docker-compose.yaml"

echo "----------------------------------------"
echo "Stopping Kafka + Zookeeper containers..."
echo "----------------------------------------"
docker compose -f "$COMPOSE_FILE" down --remove-orphans || true

echo
echo "----------------------------------------"
echo "Removing docker volumes created by compose..."
echo "----------------------------------------"
docker compose -f "$COMPOSE_FILE" down -v || true

echo
echo "----------------------------------------"
echo "Pruning unused Docker volumes..."
echo "----------------------------------------"
docker volume prune -f || true

echo
echo "----------------------------------------"
echo "Done!"
echo "Kafka environment fully reset (containers + data removed)."
echo "----------------------------------------"
