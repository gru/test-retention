docker exec -it $(docker ps -qf "name=kafka") \
  kafka-topics --create \
  --topic test-ret-bytes \
  --bootstrap-server localhost:9092 \
  --partitions 1 \
  --replication-factor 1 \
  --config retention.bytes=1048576
