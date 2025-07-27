# ProspectML Helm Chart

This Helm chart deploys ProspectML - an AI-powered coding agent with web interface - on a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure (for persistent storage)
- A storage class that supports ReadWriteMany access mode (NFS, EFS, Azurefile, etc.)

## Installation

## TL;DR

```console
helm repo add prospectml https://algorithmicresearchgroup.github.io/charts/
helm repo update
helm upgrade prospectml prospectml/prospectml --create-namespace --install --namespace <your-namespace> --values ./values.yaml
```

### Install from local directory

```bash
# From the helm directory
helm install my-prospectML ./prospectML

# With custom values
helm install my-prospectML ./prospectML -f custom-values.yaml
```

## Configuration

### Essential Configuration

Before deploying, you must configure:

1. **API Keys** - At least one AI provider API key:
   ```yaml
   aiProviders:
     anthropic:
       apiKey: "your-anthropic-api-key"
     openai:
       apiKey: "your-openai-api-key"
   ```

2. **Storage Class** - For shared filesystem:
   ```yaml
   storage:
     shared-tmp:
       storageClass: "nfs-client"  # or your RWX storage class
   ```

3. **Database** - Either use built-in PostgreSQL or external:
   ```yaml
   # Built-in PostgreSQL (default)
   postgresql:
     enabled: true
     auth:
       password: "secure-password-here"
   
   # OR External database
   postgresql:
     enabled: false
   database:
     external:
       enabled: true
       host: "your-postgres-host"
       password: "your-password"
   ```

### Common Configuration Examples

#### Minimal configuration with Anthropic

```yaml
# values-minimal.yaml
aiProviders:
  anthropic:
    apiKey: "sk-ant-..."

ingress:
  enabled: true
  hosts:
    - host: prospectML.example.com
      paths:
        - path: /
          pathType: Prefix
```

#### Production configuration

```yaml
# values-production.yaml
replicaCount: 1  # Keep at 1 for Phase 1

image:
  repository: your-registry.com/prospectML/combined
  tag: "v1.0.0"

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: prospectML.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: prospectML-tls
      hosts:
        - prospectML.yourdomain.com

storage:
  sharedTmp:
    storageClass: "aws-efs"
    size: 50Gi
  outputs:
    storageClass: "aws-efs"
    size: 500Gi

postgresql:
  enabled: false
database:
  external:
    enabled: true
    host: "postgres.rds.amazonaws.com"
    username: "prospectML"
    password: "super-secure-password"
    database: "prospectML_prod"

resources:
  requests:
    memory: 8Gi
    cpu: 4
  limits:
    memory: 32Gi
    cpu: 16

flask:
  secretKey: "generate-a-secure-secret-key-here"
```

#### Configuration with all AI providers

```yaml
# values-all-providers.yaml
aiProviders:
  anthropic:
    apiKey: "sk-ant-..."
  openai:
    apiKey: "sk-..."
  google:
    apiKey: "AIza..."

agent:
  defaultModel: "gpt-4"
  maxConcurrentRuns: 8
```

## Upgrading

```bash
# Upgrade to a new version
helm upgrade my-prospectML prospectML/prospectML

# Upgrade with new values
helm upgrade my-prospectML prospectML/prospectML -f values.yaml
```

## Uninstalling

```bash
# Uninstall the release
helm uninstall my-prospectML

# Note: PVCs are not automatically deleted
kubectl delete pvc -l app.kubernetes.io/instance=my-prospectML
```

## Persistence

The chart creates several PersistentVolumeClaims:

- **shared-tmp**: For journal files and inter-process communication
- **outputs**: For agent outputs and results
- **data**: For uploaded datasets and files

**Important**: These PVCs must support ReadWriteMany (RWX) access mode since the web app and agent processes need concurrent access.

## Troubleshooting

### Pod fails to start

Check if PVCs are bound:
```bash
kubectl get pvc -n <namespace>
```

Check pod events:
```bash
kubectl describe pod -l app.kubernetes.io/name=prospectML -n <namespace>
```

### Storage issues

Ensure your storage class supports RWX:
```bash
kubectl get storageclass
```

### Database connection issues

Test database connectivity:
```bash
kubectl exec -it <pod-name> -n <namespace> -- psql -h <host> -U <user> -d <database>
```

### View logs

```bash
# Web application logs
kubectl logs -l app.kubernetes.io/name=prospectML -n <namespace> -f

# All container logs
kubectl logs <pod-name> -n <namespace> --all-containers=true
```

## Parameters

### Deployment Parameters

This section is used to configure the prospectml deployment

| Name               | Description                                                                                    | Value                            |
| ------------------ | ---------------------------------------------------------------------------------------------- | -------------------------------- |
| `replicaCount`     | The replicaCount used for deployment manifests.                                                | `1`                              |
| `image.repository` | Override chart default image                                                                   | `algorithmicresearch/prospectml` |
| `image.tag`        | Override chart default image                                                                   | `latest`                         |
| `image.pullPolicy` | The image pullPolicy for [CronJob, Deployment, Job, RayCluster, RayService, Testing]           | `Always`                         |
| `flask.env`        | The flask configuration to set the environment                                                 | `Production`                     |
| `flask.secretKey`  | The flask secretKey used for cryptographic signing of session cookies and other sensitive data | `changeme`                       |

### Logging Configuration

| Name             | Description                                | Value  |
| ---------------- | ------------------------------------------ | ------ |
| `logging.level`  | The minimum logging level to be outputted. | `INFO` |
| `logging.format` | The format for the log output.             | `json` |

### Application Resources

| Name                        | Description                                                                              | Value |
| --------------------------- | ---------------------------------------------------------------------------------------- | ----- |
| `resources.requests.memory` | Amount of memory (e.g., 256Mi, 2Gi) to request for the application container.            | `2Gi` |
| `resources.requests.cpu`    | Amount of CPU (e.g., 100m, 1) to request for the application container.                  | `1`   |
| `resources.limits.memory`   | Maximum amount of memory (e.g., 512Mi, 4Gi) the application container is allowed to use. | `4Gi` |
| `resources.limits.cpu`      | Maximum amount of CPU (e.g., 200m, 2) the application container is allowed to use.       | `2`   |

### Application Configuration (configmap)

| Name                      | Description                                                                                     | Value                                            |
| ------------------------- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| `config.PYTHONPATH`       | The value for the PYTHONPATH environment variable.                                              | `/app`                                           |
| `config.PYTHONUNBUFFERED` | The value for the PYTHONUNBUFFERED environment variable.                                        | `1`                                              |
| `config.SECRET_KEY`       | The secret key used by the application for cryptographic operations (e.g., session management). | `changeme`                                       |
| `config.K8S_NAMESPACE`    | The Kubernetes namespace where the application is deployed.                                     | `prospectml`                                     |
| `config.STORAGE_TYPE`     | The type of storage backend used by the application.                                            | `hostpath`                                       |
| `config.MINIO_ENDPOINT`   | The endpoint URL for the MinIO service.                                                         | `localdev-minio:9000`                            |
| `config.MINIO_ACCESS_KEY` | The access key for connecting to the MinIO service.                                             | `minioadmin`                                     |
| `config.MINIO_SECRET_KEY` | The secret key for connecting to the MinIO service.                                             | `changeme`                                       |
| `config.WEB_SERVICE_URL`  | The base URL for the web service.                                                               | `http://prospectml`                              |
| `config.AGENT_IMAGE`      | The Docker image to use for agents.                                                             | `algorithmicresearch/prospectml:latest`          |
| `config.APP_URL`          | The base URL for the application's own service for internal API calls.                          | `http://prospectml.prospectml.svc.cluster.local` |
| `config.API_BASE_URL`     | The base URL for the application's internal API.                                                | `http://prospectml.prospectml.svc.cluster.local` |
| `config.SERVICE_URL`      | The generic service URL for the application, potentially for external or internal use.          | `http://prospectml.prospectml.svc.cluster.local` |
| `env`                     | ProspectML environment variables                                                                | `nil`                                            |

### Agent Configuration

| Name                         | Description                                                               | Value                                   |
| ---------------------------- | ------------------------------------------------------------------------- | --------------------------------------- |
| `agent.image`                | The Docker image to use for the agent pods.                               | `algorithmicresearch/prospectml:latest` |
| `agent.maxConcurrentRuns`    | The maximum number of concurrent tasks or runs that an agent can process. | `3`                                     |
| `agent.defaultModel`         | The default AI model to be used by the agent if not specified otherwise.  | `claude-3-sonnet-20240229`              |
| `agent.defaultMaxIterations` | The default maximum number of iterations for a process run by the agent.  | `50`                                    |
| `agent.enableStorage`        | Enables or disables the use of storage for the agent.                     | `true`                                  |
| `agent.storageProvider`      | The storage backend provider to use if storage is enabled.                | `minio`                                 |
| `agent.storageBucket`        | The name of the storage bucket to be used by the agent.                   | `prospectml-outputs`                    |

### Agent Resource Requests and Limits

| Name                              | Description                                                                                      | Value |
| --------------------------------- | ------------------------------------------------------------------------------------------------ | ----- |
| `agent.resources.requests.memory` | Amount of memory (e.g., "4Gi") to request for the agent container.                               | `4Gi` |
| `agent.resources.requests.cpu`    | Amount of CPU (e.g., "2" for 2 cores or "500m" for 0.5 core) to request for the agent container. | `2`   |
| `agent.resources.limits.memory`   | Maximum amount of memory (e.g., "8Gi") the agent container is allowed to use.                    | `8Gi` |
| `agent.resources.limits.cpu`      | Maximum amount of CPU (e.g., "4" for 4 cores) the agent container is allowed to use.             | `4`   |

### AI Providers Configuration

| Name                           | Description                                                   | Value |
| ------------------------------ | ------------------------------------------------------------- | ----- |
| `aiProviders.anthropic.apiKey` | The API key for authenticating with the Anthropic AI service. | `""`  |
| `aiProviders.openai.apiKey`    | The API key for authenticating with the OpenAI AI service.    | `""`  |
| `aiProviders.google.apiKey`    | The API key for authenticating with Google AI services.       | `""`  |

### Weights & Biases (W&B) Configuration (Optional)

| Name           | Description                                                       | Value |
| -------------- | ----------------------------------------------------------------- | ----- |
| `wandb.apiKey` | The API key for authenticating with the Weights & Biases service. | `""`  |

### AWS Configuration

Optional AWS credentials for the application to use.
These are commonly used when interacting with AWS services like S3.
You can pass them via environment variables or secrets.

| Name                  | Description           | Value |
| --------------------- | --------------------- | ----- |
| `aws.accessKeyId`     | AWS Access Key ID     | `""`  |
| `aws.secretAccessKey` | AWS Secret Access Key | `""`  |

### License Configuration

| Name                         | Description                                                           | Value |
| ---------------------------- | --------------------------------------------------------------------- | ----- |
| `license.key`                | The license key or token for the application.                         | `""`  |
| `license.keygenAccountId`    | The account ID from the Keygen licensing service.                     | `""`  |
| `license.keygenProductToken` | The product token associated with your product in Keygen.             | `""`  |
| `license.fingerprint`        | A unique identifier, often generated from the machine or environment, | `""`  |

### Health Check Configuration

| Name                              | Description                                                                       | Value  |
| --------------------------------- | --------------------------------------------------------------------------------- | ------ |
| `healthcheck.enabled`             | Enable or disable the health checks for the application container.                | `true` |
| `healthcheck.initialDelaySeconds` | The number of seconds after the container has started                             | `30`   |
| `healthcheck.periodSeconds`       | The frequency (in seconds) at which Kubernetes performs the health checks.        | `10`   |
| `healthcheck.timeoutSeconds`      | The number of seconds after which the probe times out if no response is received. | `5`    |
| `healthcheck.successThreshold`    | The minimum number of consecutive successes required for a probe                  | `1`    |
| `healthcheck.failureThreshold`    | The number of consecutive failures required for a probe                           | `3`    |

### Pod Configuration

| Name                 | Description                                                                  | Value |
| -------------------- | ---------------------------------------------------------------------------- | ----- |
| `podAnnotations`     | Optional annotations to add to the Pod metadata.                             | `{}`  |
| `podSecurityContext` | Pod-level Security Context to apply to the Pod.                              | `{}`  |
| `securityContext`    | Container-level Security Context to apply to the main application container. | `{}`  |

### Autoscaling Configuration

| Name                  | Description            | Value   |
| --------------------- | ---------------------- | ------- |
| `autoscaling.enabled` | Enable or disable HPA. | `false` |

### Node Selection & Scheduling

| Name           | Description                                                                            | Value |
| -------------- | -------------------------------------------------------------------------------------- | ----- |
| `nodeSelector` | Node labels required for Pod scheduling.                                               | `{}`  |
| `tolerations`  | Taints that Pods can tolerate, allowing scheduling on tainted nodes.                   | `[]`  |
| `affinity`     | Advanced Pod scheduling rules, including node affinity and pod affinity/anti-affinity. | `{}`  |

### RBAC Configuration

| Name          | Description                                                                                        | Value  |
| ------------- | -------------------------------------------------------------------------------------------------- | ------ |
| `rbac.create` | If true, create RBAC resources (ServiceAccount, Role/ClusterRole, RoleBinding/ClusterRoleBinding). | `true` |

### Service Account Configuration

| Name                         | Description                                        | Value  |
| ---------------------------- | -------------------------------------------------- | ------ |
| `serviceAccount.create`      | If true, a ServiceAccount will be created.         | `true` |
| `serviceAccount.annotations` | Optional annotations to add to the ServiceAccount. | `{}`   |
| `serviceAccount.name`        | The name of the ServiceAccount to use.             | `""`   |

### Ingress

| Name              | Description                             | Value   |
| ----------------- | --------------------------------------- | ------- |
| `ingress.enabled` | Enable or disable the Ingress resource. | `false` |

### volumeClaim parameters

| Name                                 | Description                                        | Value           |
| ------------------------------------ | -------------------------------------------------- | --------------- |
| `volumeClaim.type`                   | Type of volume claim to create                     | `pvc`           |
| `volumeClaim.claims[0].name`         | Name of the volumeClaim                            | `shared-tmp`    |
| `volumeClaim.claims[0].accessMode`   | Access mode for volumeClaim Required ReadWriteMany | `ReadWriteMany` |
| `volumeClaim.claims[0].storageClass` | Specify the storage class of the volumeClaim       | `hostpath`      |
| `volumeClaim.claims[0].mountPath`    | Specify the mountPath of the volumeClaim           | `/tmp/shared`   |
| `volumeClaim.claims[0].size`         | Specify the size of the volumeClaim                | `10Gi`          |
| `volumeClaim.claims[1].name`         | Name of the volumeClaim                            | `outputs`       |
| `volumeClaim.claims[1].accessMode`   | Access mode for volumeClaim Required ReadWriteMany | `ReadWriteMany` |
| `volumeClaim.claims[1].storageClass` | Specify the storage class of the volumeClaim       | `hostpath`      |
| `volumeClaim.claims[1].mountPath`    | Specify the mountPath of the volumeClaim           | `/app/outputs`  |
| `volumeClaim.claims[1].size`         | Specify the size of the volumeClaim                | `20Gi`          |
| `volumeClaim.claims[2].name`         | Name of the volumeClaim                            | `data`          |
| `volumeClaim.claims[2].accessMode`   | Access mode for volumeClaim Required ReadWriteMany | `ReadWriteMany` |
| `volumeClaim.claims[2].storageClass` | Specify the storage class of the volumeClaim       | `hostpath`      |
| `volumeClaim.claims[2].mountPath`    | Specify the mountPath of the volumeClaim           | `/app/data`     |
| `volumeClaim.claims[2].size`         | Specify the size of the volumeClaim                | `10Gi`          |

### Service parameters

| Name                  | Description                                                                                                                   | Value       |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `service.type`        | Kubernetes [service type](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) | `ClusterIP` |
| `service.port`        | Service port for client connections                                                                                           | `80`        |
| `service.targetPort`  | Service target port the application listens on inside the container                                                           | `5000`      |
| `service.annotations` | Annotations to add to the Kubernetes Service                                                                                  | `{}`        |

### minio parameters

| Name            | Description   | Value   |
| --------------- | ------------- | ------- |
| `minio.enabled` | Enable minio. | `false` |

### postgresql parameters

| Name                 | Description       | Value   |
| -------------------- | ----------------- | ------- |
| `postgresql.enabled` | Enable postgresql | `false` |

### External Database Configuration

| Name                        | Description                                        | Value   |
| --------------------------- | -------------------------------------------------- | ------- |
| `database.external.enabled` | Enable or disable the use of an external database. | `false` |

