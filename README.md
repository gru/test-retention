# Тест Kafka Retention / Offset Out-of-Range

## 1. Назначение теста

Этот стенд воспроизводит ситуацию, когда Kafka удаляет старые сегменты из-за очень маленького `retention`, а медленный consumer продолжает читать старые оффсеты.  
Цель теста — получить ошибки вида:

```
OFFSET|... Broker: Offset out of range
```

Это означает, что consumer запросил оффсет, который уже удалён брокером.

---

## 2. Последовательность запуска

### Шаг 1 — Запуск контейнеров Kafka и медленного consumer

```
./start-containers.sh
```

Скрипт:

- останавливает предыдущие контейнеры
- удаляет volumes Kafka
- пересобирает consumer
- запускает Kafka
- создаёт тестовый топик `test-ret-bytes`
- запускает consumer в профиле `slow-consumer`

Consumer читает медленно, что создаёт условия для удаления старых сегментов.

---

### Шаг 2 — Отправка ~100MB сообщений в Kafka

```
./produce-messages.sh 100
```

Скрипт генерирует поток данных, который:

- быстро заполняет Kafka-сегменты,
- вызывает их удаление из‑за `retention_bytes = 1MB`,
- создаёт ситуацию, когда consumer остается "позади" и запрашивает недоступные оффсеты.

---

### Шаг 3 — Поиск ошибок в логах Kafka

```
./grep-kafka-logs.sh "Offset out of range"
```

Скрипт ищет ошибки вида:

```
offset reset ... fetch failed ... Broker: Offset out of range
```

Это ключевой признак того, что retention удалил сегменты, которые читает медленный consumer.

---

## 3. Где смотреть логи

### Логи consumer

```
docker compose --profile slow-consumer logs -f consumer
```

### Логи Kafka

```
docker compose logs -f kafka
```

---

## 4. Настройки consumer

Consumer управляется через переменные окружения в `docker-compose.yaml`:

- `BOOTSTRAP_SERVERS` — адрес брокера
- `KAFKA_TOPIC` — имя топика
- `KAFKA_GROUP_ID` — consumer group
- `BATCH_SIZE` — размер батча
- `SLEEP_MS` — задержка между батчами

Эти параметры позволяют легко регулировать скорость потребления и условия теста.

---

## 6. Цель теста

Если всё работает корректно, в логах Kafka должны появиться строки:

```
Broker: Offset out of range
```

![errors.png](errors.png)

Это означает, что Kafka удалила сегменты быстрее, чем consumer успел их прочитать — ожидаемое поведение для тестирования retention.
