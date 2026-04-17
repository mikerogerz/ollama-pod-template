# RunPod Ollama Embedding Service

This Docker image provides a ready-to-use Ollama server optimized for generating embeddings with the `qwen3-embedding:4b` model and 32k context window.

## Features

- ✅ Built on RunPod's PyTorch base image
- ✅ Ollama pre-installed and configured
- ✅ Automatic model pulling on startup
- ✅ qwen3-embedding:4b model with 32k context (via OLLAMA_CONTEXT_LENGTH)
- ✅ HTTP API ready for embedding requests
- ✅ Health checks enabled
- ✅ RunPod optimized

## Build and Push to Docker Hub

### 1. Build the Docker image

```bash
docker build -t your-dockerhub-username/runpod-ollama-embeddings:latest .
```

### 2. Test locally (optional)

```bash
docker run -p 11434:11434 your-dockerhub-username/runpod-ollama-embeddings:latest
```

Wait for the model to download (this happens on first run), then test:

```bash
curl http://localhost:11434/api/embeddings -d '{
  "model": "qwen3-embedding:4b",
  "prompt": "The sky is blue because of Rayleigh scattering"
}'
```

### 3. Push to Docker Hub

```bash
# Login to Docker Hub
docker login

# Push the image
docker push your-dockerhub-username/runpod-ollama-embeddings:latest
```

## Deploy on RunPod

### Method 1: Create a Template (Recommended)

1. Go to [RunPod Templates](https://www.runpod.io/console/user/templates)
2. Click "New Template"
3. Fill in the details:
   - **Template Name**: `Ollama Embedding Service`
   - **Container Image**: `your-dockerhub-username/runpod-ollama-embeddings:latest`
   - **Container Disk**: `20 GB` (minimum for the model)
   - **Expose HTTP Ports**: `11434`
   - **Expose TCP Ports**: Leave empty
   - **Environment Variables** (optional overrides):
     - `OLLAMA_CONTEXT_LENGTH`: `32768` (default, can be changed)
     - `OLLAMA_NUM_PARALLEL`: `4` (number of parallel requests)
     - `OLLAMA_MAX_LOADED_MODELS`: `1` (memory optimization)

4. Click "Save Template"

### Method 2: Direct Pod Deployment

1. Go to [RunPod Pods](https://www.runpod.io/console/pods)
2. Click "Deploy"
3. Choose your GPU (or CPU if using CPU-only pod)
4. Under "Select a Template" → "Custom"
5. Enter your Docker image: `your-dockerhub-username/runpod-ollama-embeddings:latest`
6. Set Container Disk to at least 20 GB
7. Expose port `11434`
8. Deploy!

## Usage

Once your pod is running, get the pod's connection information:

### Get Pod IP/URL

In RunPod console:
- Click on your pod
- Find the "TCP Port Mappings" or "Connect" section
- Note the external IP and port for port 11434

### Generate Embeddings

**Basic usage:**

```bash
curl http://YOUR_POD_IP:PORT/api/embeddings -d '{
  "model": "qwen3-embedding:4b",
  "prompt": "Your text to embed here"
}'
```

The model automatically uses the 32k context length set via `OLLAMA_CONTEXT_LENGTH`.

### Python Example

```python
import requests
import json

url = "http://YOUR_POD_IP:PORT/api/embeddings"
payload = {
    "model": "qwen3-embedding:4b",
    "prompt": "Machine learning is a subset of artificial intelligence"
}

response = requests.post(url, json=payload)
embedding = response.json()['embedding']
print(f"Embedding dimension: {len(embedding)}")
print(f"First 5 values: {embedding[:5]}")
```

### Batch Embeddings

```bash
curl http://YOUR_POD_IP:PORT/api/embeddings -d '{
  "model": "qwen3-embedding:4b",
  "prompt": ["First text", "Second text", "Third text"]
}'
```

## API Endpoints

- **Generate Embeddings**: `POST /api/embeddings`
- **List Models**: `GET /api/tags`
- **Model Info**: `POST /api/show` (with model name in body)

## Configuration

### Environment Variables

You can override these in your RunPod template:

- `OLLAMA_CONTEXT_LENGTH`: Context window size (default: `32768`)
- `OLLAMA_NUM_PARALLEL`: Number of parallel requests (default: `4`)
- `OLLAMA_MAX_LOADED_MODELS`: Maximum models in memory (default: `1`)
- `OLLAMA_HOST`: Server bind address (default: `0.0.0.0:11434`)

Example in RunPod template:
```
OLLAMA_CONTEXT_LENGTH=65536
OLLAMA_NUM_PARALLEL=8
```

## Troubleshooting

### Check if Ollama is running

```bash
curl http://YOUR_POD_IP:PORT/api/tags
```

### View available models

```bash
curl http://YOUR_POD_IP:PORT/api/tags
```

Should return `qwen3-embedding:4b`

### Check pod logs in RunPod console

Look for:
- "Ollama server is ready!"
- "Pulling qwen3-embedding:4b model..."
- "Model setup complete!"
- "Context length: 32768 tokens"

### Verify context length

The context length is set globally via the `OLLAMA_CONTEXT_LENGTH` environment variable and applies to all models.

## Specifications

- **Base Image**: runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404
- **Model**: qwen3-embedding:4b
- **Context Length**: 32,768 tokens (configurable via env var)
- **Embedding Dimension**: 4096 (typical for this model)
- **Port**: 11434
- **Minimum Disk**: 20 GB

## Cost Optimization

- Use CPU pods for lower cost (embeddings don't require GPU)
- Enable auto-scaling to 0 replicas when idle
- Use spot instances for non-critical workloads
- Adjust `OLLAMA_NUM_PARALLEL` based on your workload

## Notes

- First startup will take longer as the model downloads (~2.4 GB)
- The model persists in the container, so subsequent restarts are faster
- For production, consider using a persistent volume for the model cache
- The 32k context is set globally via `OLLAMA_CONTEXT_LENGTH` environment variable

## License

This setup uses:
- RunPod PyTorch base image
- Ollama: Apache 2.0
- qwen3-embedding model: Check Alibaba's Qwen license
