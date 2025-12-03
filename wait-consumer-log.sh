wait_for_consumer_log() {
    local pattern="$1"
    echo "Waiting for consumer log entry: \"$pattern\""

    while IFS= read -r line; do
        echo "$line"
        if [[ "$line" == *"$pattern"* ]]; then
            echo "Matched: $pattern"
            return 0
        fi
    done < <(docker compose --profile slow-consumer logs -f consumer)
}