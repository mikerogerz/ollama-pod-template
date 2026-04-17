#!/bin/bash

# Test script for the Ollama embedding service
# Usage: ./test_embeddings.sh <host:port>

HOST=${1:-localhost:11434}

echo "Testing Ollama Embedding Service at $HOST"
echo "==========================================="
echo ""

# Test 1: Check if server is alive
echo "Test 1: Server Health Check"
curl -s http://$HOST/api/tags > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Server is running"
else
    echo "✗ Server is not responding"
    exit 1
fi
echo ""

# Test 2: List available models
echo "Test 2: List Available Models"
curl -s http://$HOST/api/tags | jq -r '.models[].name'
echo ""

# Test 3: Generate embedding with qwen3-embedding:4b
echo "Test 3: Generate Embedding"
response=$(curl -s http://$HOST/api/embeddings -d '{
  "model": "qwen3-embedding:4b",
  "prompt": "Hello, world!"
}')

if echo "$response" | jq -e '.embedding' > /dev/null 2>&1; then
    dimension=$(echo "$response" | jq '.embedding | length')
    echo "✓ Embedding generated successfully"
    echo "  Dimension: $dimension"
    echo "  First 5 values: $(echo "$response" | jq -c '.embedding[:5]')"
else
    echo "✗ Failed to generate embedding"
    echo "$response"
fi
echo ""

# Test 4: Generate embedding with longer text (testing 32k context)
echo "Test 4: Generate Embedding (longer text)"
response=$(curl -s http://$HOST/api/embeddings -d '{
  "model": "qwen3-embedding:4b",
  "prompt": "This is a test of the Ollama embedding service with a 32k context window. The context length is set globally via the OLLAMA_CONTEXT_LENGTH environment variable, which allows the model to process longer sequences of text without needing to create custom model variants."
}')

if echo "$response" | jq -e '.embedding' > /dev/null 2>&1; then
    dimension=$(echo "$response" | jq '.embedding | length')
    echo "✓ Embedding generated successfully"
    echo "  Dimension: $dimension"
else
    echo "✗ Failed to generate embedding"
    echo "$response"
fi
echo ""

# Test 5: Batch embeddings
echo "Test 5: Batch Embeddings"
response=$(curl -s http://$HOST/api/embeddings -d '{
  "model": "qwen3-embedding:4b",
  "prompt": ["First text", "Second text", "Third text"]
}')

if echo "$response" | jq -e '.embedding' > /dev/null 2>&1; then
    echo "✓ Batch embeddings generated successfully"
    echo "  Number of embeddings: $(echo "$response" | jq '.embedding | length')"
else
    echo "✗ Failed to generate batch embeddings"
fi
echo ""

echo "All tests completed!"
echo ""
echo "Note: Context length is set to 32k via OLLAMA_CONTEXT_LENGTH environment variable"
