#r "nuget: Confluent.Kafka, 2.4.0"

using System;
using System.Collections.Generic;
using System.Text;
using System.Threading;
using Confluent.Kafka;

string bootstrapServers =
    Environment.GetEnvironmentVariable("BOOTSTRAP_SERVERS")
    ?? "kafka:9092";

string topicName =
    Environment.GetEnvironmentVariable("KAFKA_TOPIC")
    ?? "my-topic";

string groupId =
    Environment.GetEnvironmentVariable("KAFKA_GROUP_ID")
    ?? "my-consumer-group";

int batchSize =
    int.TryParse(Environment.GetEnvironmentVariable("BATCH_SIZE"), out var bs)
    ? bs
    : 100;

int sleepMs =
    int.TryParse(Environment.GetEnvironmentVariable("SLEEP_MS"), out var sm)
    ? sm
    : 1000;

var config = new ConsumerConfig
{
    BootstrapServers = bootstrapServers,
    GroupId = groupId,
    EnableAutoCommit = false,
    AutoOffsetReset = AutoOffsetReset.Earliest
};

Console.WriteLine($"BOOTSTRAP_SERVERS = {bootstrapServers}");
Console.WriteLine($"KAFKA_TOPIC       = {topicName}");
Console.WriteLine($"KAFKA_GROUP_ID    = {groupId}");
Console.WriteLine($"BATCH_SIZE        = {batchSize}");
Console.WriteLine($"SLEEP_MS          = {sleepMs}");

using (var consumer = new ConsumerBuilder<Ignore, string>(config).Build())
{
    consumer.Subscribe(topicName);
    Console.WriteLine("Consumer started. Press Ctrl+C to exit.");

    long totalMessages = 0;
    long totalBytes = 0;

    var cts = new CancellationTokenSource();
    Console.CancelKeyPress += (_, e) =>
    {
        e.Cancel = true;
        cts.Cancel();
    };

    try
    {
        while (!cts.IsCancellationRequested)
        {
            var batch = new List<ConsumeResult<Ignore, string>>(batchSize);

            long batchBytes = 0;

            while (batch.Count < batchSize && !cts.IsCancellationRequested)
            {
                try
                {
                    var cr = consumer.Consume(cts.Token);
                    if (cr != null)
                    {
                        batch.Add(cr);

                        if (cr.Message?.Value != null)
                        {
                            int msgBytes = Encoding.UTF8.GetByteCount(cr.Message.Value);
                            batchBytes += msgBytes;
                            totalBytes += msgBytes;
                        }
                    }
                }
                catch (OperationCanceledException)
                {
                    break;
                }
            }

            totalMessages += batch.Count;

            if (batch.Count > 0)
            {
                var last = batch[^1];
                consumer.Commit(last);

                Console.WriteLine(
                    $"[BATCH] messages={batch.Count}, batchBytes={batchBytes}, totalMessages={totalMessages}, totalBytes={totalBytes}, committed={last.TopicPartitionOffset}"
                );
            }
            else
            {
                Console.WriteLine("[BATCH] empty batch — no messages");
            }

            Thread.Sleep(sleepMs);
        }
    }
    finally
    {
        consumer.Close();
        Console.WriteLine("Consumer closed.");
    }
}
