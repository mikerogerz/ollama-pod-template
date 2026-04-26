#!/bin/bash

# Start base image services (Jupyter/SSH) in background
/start.sh &

# Wait for services to start
sleep 2

# Display startup banner
echo "========================================"
echo "Starting Ollama Embedding Service"
echo "========================================"
echo ""

# Check if API_KEY environment variable is set
if [ -z "$API_KEY" ]; then
    echo "❌ ERROR: API_KEY environment variable is not set!"
    echo ""
    echo "You must set API_KEY in your RunPod template."
    echo ""
    echo "Example in RunPod template environment variables:"
    echo "  API_KEY=sk-your-secret-token-here"
    echo ""
    echo "To generate secure API keys, run:"
    echo "  openssl rand -hex 32"
    echo "  # or with prefix:"
    echo "  echo \"sk-\$(openssl rand -hex 24)\""
    echo ""
    echo "Container will exit in 10 seconds..."
    sleep 10
    exit 1
fi

# Display API key info (first 10 chars only for security)
echo "✓ API key configured"
echo "  Key: ${API_KEY:0:10}..."
echo ""

# Generate Caddyfile with Bearer token authentication
echo "Generating Caddyfile with Bearer token authentication..."
cat > /etc/caddy/Caddyfile.generated <<EOF
:8080 {
    # Health check endpoint (no auth)
    @health path /health
    handle @health {
        respond \`{"status":"healthy","service":"ollama-caddy"}\` 200
        header Content-Type application/json
    }
    
    # All other endpoints require Bearer token authentication
    handle {
        # Check if Authorization header exists
        @no_auth {
            not header Authorization *
        }
        handle @no_auth {
            respond \`{"error":"Unauthorized","message":"Missing Authorization header. Use: Authorization: Bearer YOUR_TOKEN"}\` 401
            header Content-Type application/json
        }
        
        # Check for valid Bearer token
        @valid_token header Authorization "Bearer $API_KEY"
        handle @valid_token {
            reverse_proxy 127.0.0.1:11434 {
                header_up Host {host}
                header_up X-Real-IP {remote_host}
            }
        }
        
        # Invalid token
        respond \`{"error":"Forbidden","message":"Invalid API token"}\` 403
        header Content-Type application/json
    }
    
    # Security headers
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection "1; mode=block"
        -Server
    }
    
    log {
        output stdout
        format console
    }
}
EOF

echo "✓ Caddyfile generated with Bearer token authentication"
echo ""

# Start Caddy proxy in the background
echo "Starting Caddy reverse proxy on :8080..."
caddy run --config /etc/caddy/Caddyfile.generated --adapter caddyfile &
CADDY_PID=$!

# Give Caddy a moment to start
sleep 2

# Verify Caddy started successfully
if ! kill -0 $CADDY_PID 2>/dev/null; then
    echo "❌ ERROR: Caddy failed to start"
    echo "Check Caddyfile syntax:"
    cat /etc/caddy/Caddyfile.generated
    exit 1
fi
echo "✓ Caddy started successfully"
echo ""

# Start Ollama server in the background (localhost only)
echo "Starting Ollama server on 127.0.0.1:11434..."
ollama serve > ollama.log 2>&1 &
OLLAMA_PID=$!

# Wait for Ollama to be ready
echo "Waiting for Ollama server to start..."
for i in {1..30}; do
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "✓ Ollama server is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ ERROR: Ollama failed to start within 60 seconds"
        exit 1
    fi
    sleep 1
done

echo ""

echo "Pulling qwen3-embedding:4b model..."
ollama pull qwen3-embedding:4b

# Verify the model is available
echo ""
echo "Verifying model installation..."
ollama list

echo ""
echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo "Public API endpoint: http://0.0.0.0:8080"
echo "Backend (internal): http://127.0.0.1:11434"
echo ""
echo "Model: qwen3-embedding:4b"
echo "Context length: 32768 tokens"
echo "Keep alive: -1 (always loaded)"
echo ""
echo "Authentication: X-API-Key header"
echo "Number of valid API keys: ${#KEYS[@]}"
echo "Health check: http://0.0.0.0:8080/health (no auth)"
echo ""
echo "Example authenticated request:"
echo "curl http://YOUR_POD_IP:8080/api/embeddings \\"
echo "  -H 'X-API-Key: YOUR_KEY' \\"
echo "  -d '{\"model\": \"qwen3-embedding:4b\", \"prompt\": \"Hello\"}'"
echo "========================================"
echo ""

# Function to handle shutdown gracefully
cleanup() {
    echo ""
    echo "Shutting down services..."
    kill $CADDY_PID $OLLAMA_PID 2>/dev/null
    exit 0
}

trap cleanup SIGTERM SIGINT

# Keep container running and wait for both processes
wait