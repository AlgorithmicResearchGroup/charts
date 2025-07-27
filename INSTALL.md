# ProspectML Helm Chart Installation Guide

## Prerequisites

Before installing ProspectML, ensure you have:

1. **Kubernetes cluster** (1.19+)
   - Local options: Docker Desktop, Minikube, or Kind
   - Cloud options: GKE, EKS, AKS

2. **Helm 3** installed
   ```bash
   helm version
   ```

3. **kubectl** configured to access your cluster
   ```bash
   kubectl cluster-info
   ```

## Quick Start

### Option 1: Install from GitHub Release

```bash
# Download the chart from GitHub releases
wget https://github.com/AlgorithmicResearchGroup/Coding-Agent-For-Deployment/releases/download/v0.1.0/prospectml-0.1.0.tgz

# Install the chart
helm install my-prospectml ./prospectml-0.1.0.tgz

# Or install with custom values
helm install my-prospectml ./prospectml-0.1.0.tgz -f values.yaml
```

### Option 2: Install from Repository (if hosted)

```bash
# Add the repository
helm repo add prospectml https://algorithmicresearchgroup.github.io/Coding-Agent-For-Deployment/charts
helm repo update

# Install the chart
helm install my-prospectml prospectml/prospectml
```

## Configuration

### Minimal Configuration

Create a `values.yaml` file with your specific configuration:

```yaml
# values.yaml
image:
  repository: algorithmicresearch/prospectml
  tag: "0.1.0"
  pullPolicy: IfNotPresent

# PostgreSQL settings (using included PostgreSQL)
postgresql:
  enabled: true
  auth:
    username: prospectml
    password: changeme123  # CHANGE THIS!
    database: prospectml

# API Keys for AI providers (at least one required)
aiProvider:
  anthropic:
    apiKey: "your-anthropic-api-key"  # Required for Claude
  # openai:
  #   apiKey: "your-openai-api-key"   # Optional
  # google:
  #   apiKey: "your-google-api-key"   # Optional

# Service configuration
service:
  type: NodePort  # or LoadBalancer for cloud environments
  port: 80
  nodePort: 31577  # Only for NodePort type
```

Install with your values:
```bash
helm install my-prospectml ./prospectml-0.1.0.tgz -f values.yaml
```

### Production Configuration

For production deployments, consider these additional settings:

```yaml
# production-values.yaml

# Use external PostgreSQL
postgresql:
  enabled: false

database:
  external:
    host: "your-postgres-host"
    port: 5432
    username: "prospectml"
    password: "strong-password"
    database: "prospectml"

# Enable ingress for HTTPS
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: prospectml.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: prospectml-tls
      hosts:
        - prospectml.yourdomain.com

# Resource limits
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "4Gi"
    cpu: "2"

# Enable persistent storage
storage:
  outputs:
    enabled: true
    size: 50Gi
  sharedTmp:
    enabled: true
    size: 20Gi

# Agent configuration
agent:
  maxConcurrentRuns: 5
  defaultModel: "claude-3-5-sonnet-20241022"
  defaultMaxIterations: 500
```

## Post-Installation

### 1. Check Deployment Status

```bash
# Check if pods are running
kubectl get pods -l app.kubernetes.io/name=prospectml

# Check services
kubectl get svc -l app.kubernetes.io/name=prospectml

# View logs
kubectl logs -l app.kubernetes.io/name=prospectml
```

### 2. Access the Application

#### For NodePort (default):
```bash
# Get the NodePort
kubectl get svc my-prospectml-prospectml -o jsonpath='{.spec.ports[0].nodePort}'

# Access at: http://localhost:31577
```

#### For LoadBalancer:
```bash
# Get the external IP
kubectl get svc my-prospectml-prospectml

# Access at: http://EXTERNAL-IP
```

#### For Ingress:
Access at the configured host (e.g., https://prospectml.yourdomain.com)

### 3. Create Initial User

Access the application and register a new user through the web interface.

### 4. Run Database Migrations (if needed)

```bash
# Get pod name
POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=prospectml -o jsonpath='{.items[0].metadata.name}')

# Run migrations
kubectl exec $POD_NAME -- python -c "from web.app import db; db.create_all()"
```

## Common Configurations

### Using AWS S3 for Storage

```yaml
agent:
  enableStorage: true
  storageProvider: "s3"
  storageBucket: "my-prospectml-bucket"

aws:
  accessKeyId: "your-access-key"
  secretAccessKey: "your-secret-key"
  region: "us-east-1"
```

### Using Google Cloud Storage

```yaml
agent:
  enableStorage: true
  storageProvider: "gcs"
  storageBucket: "my-prospectml-bucket"

gcp:
  projectId: "my-project"
  serviceAccountKey: |
    {
      "type": "service_account",
      "project_id": "my-project",
      ...
    }
```

### Enable WandB Integration

```yaml
wandb:
  apiKey: "your-wandb-api-key"
  project: "prospectml-runs"
```

## Troubleshooting

### Pod Stuck in Pending State

Check for PVC issues:
```bash
kubectl describe pod -l app.kubernetes.io/name=prospectml
kubectl get pvc
```

### Database Connection Failed

1. Check PostgreSQL pod:
```bash
kubectl get pods -l app.kubernetes.io/name=postgresql
kubectl logs -l app.kubernetes.io/name=postgresql
```

2. Verify credentials:
```bash
kubectl get secret my-prospectml-prospectml -o yaml
```

### Cannot Access Web Interface

1. Check service type and ports:
```bash
kubectl get svc my-prospectml-prospectml -o yaml
```

2. For NodePort, ensure you're using the correct port:
```bash
kubectl get svc my-prospectml-prospectml -o jsonpath='{.spec.ports[0].nodePort}'
```

### Agent Jobs Failing

1. Check agent pod logs:
```bash
kubectl logs -l app=ml-agent
```

2. Verify API keys are set:
```bash
kubectl get secret my-prospectml-prospectml -o jsonpath='{.data.anthropic-api-key}' | base64 -d
```

## Upgrade

To upgrade to a new version:

```bash
# Download new chart version
wget https://github.com/AlgorithmicResearchGroup/Coding-Agent-For-Deployment/releases/download/v0.2.0/prospectml-0.2.0.tgz

# Upgrade release
helm upgrade my-prospectml ./prospectml-0.2.0.tgz -f values.yaml
```

## Uninstall

To remove ProspectML:

```bash
helm uninstall my-prospectml

# Clean up PVCs (if you want to delete data)
kubectl delete pvc -l app.kubernetes.io/name=prospectml
```

## Security Considerations

1. **Change default passwords**: Always change the default PostgreSQL password
2. **Use secrets**: Store API keys in Kubernetes secrets, not in values files
3. **Enable RBAC**: The chart includes RBAC resources for secure operation
4. **Use HTTPS**: Enable ingress with TLS for production deployments
5. **Resource limits**: Set appropriate resource limits to prevent resource exhaustion

## Support

- **GitHub Issues**: https://github.com/AlgorithmicResearchGroup/Coding-Agent-For-Deployment/issues
- **Documentation**: https://github.com/AlgorithmicResearchGroup/Coding-Agent-For-Deployment
- **Email**: info@algorithmicresearchgroup.com