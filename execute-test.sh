#!/usr/bin/env bash

source ./wait-consumer-log.sh

# Отправляем данные в Kafka
echo "Producing 10MB of messages"
./produce-messages.sh 10

# Ждём удаления сегментов 15 секунд при настроенных 5 секундах для KAFKA_LOG_RETENTION_CHECK_INTERVAL_MS: 5000
echo ""
echo "Waiting for Kafka to delete segments"
sleep 15

# Перезапускаем consumer, чтобы очистить внутренний кеш librdkafka, так как она читает данные пачками: 
# fetch.min.bytes — минимальное количество байт в пачке,
# fetch.max.bytes — максимальное количество байт в пачке,
# но не менее чем message.max.bytes (настройка сервера, по умолчанию 1MB). В итоге она может закешировать все данные внутри.
# Restart consumer сбрасывает внутренний кеш librdkafka.
echo ""
echo "Restarting consumer"
docker compose restart consumer

wait_for_consumer_log "Consumer started."

# Ждём ошибок о том, что Offset out of range. Видим по логам, что чтение продолжилось с нового offset,
# часть сообщений пропала.
echo ""
echo "Waiting for 'Offset out of range' in consumer logs. Press Ctrl+C to cancel"
wait_for_consumer_log "Offset out of range"


