#!/bin/bash
ollama serve > ollama.log 2>&1 &

until curl -s http://localhost:11434/api/tags > /dev/null 2>&1; do
    sleep 1
done

ollama pull qwen3-embedding:4b

wait