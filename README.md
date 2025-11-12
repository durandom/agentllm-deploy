# AgentLLM Deployment

Production-ready deployment configurations for AgentLLM with plugin support.

## Quick Start

### Docker/Podman

```bash
# Copy environment template
cp .env.example .env
# Edit .env with your configuration
vim .env

# Build container
docker build -t agentllm:latest .
# or with Podman
podman build -t agentllm:latest .

# Run container
docker run -p 8890:8890 --env-file .env agentllm:latest
```

### Docker Compose

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Kubernetes

```bash
# Create secrets
kubectl create secret generic agentllm-secrets \
  --from-literal=gemini-api-key=your_key \
  --from-literal=litellm-master-key=your_key \
  --from-literal=gdrive-client-id=your_id \
  --from-literal=gdrive-client-secret=your_secret

# Create configmap
kubectl create configmap agentllm-config \
  --from-literal=jira-server-url=https://your-jira.atlassian.net

# Deploy
kubectl apply -f kubernetes/deployment.yaml
```

## Build Arguments

Customize agent versions at build time:

```bash
docker build \
  --build-arg CORE_VERSION=0.2.0 \
  --build-arg RHDH_VERSION=1.1.0 \
  --build-arg INSTALL_DEMO=false \
  -t agentllm:prod .
```

## Configuration

See `.env.example` for all configuration options.

## License

MIT License
