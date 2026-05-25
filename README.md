# Demo DevOps Python

REST API built with Django REST Framework, containerized with Docker, and deployed on AWS EKS through a Jenkins pipeline and Helm.

## AWS Architecture | [NOTE] INFRASTRUCTURE DELETED ON MONDAY 25TH AT 09:30 A.M.


![AWS Architecture](https://i.imgur.com/6Rgsdps.png)


The infrastructure runs in **us-east-2** and is composed of:

- **VPC** `10.0.0.0/16` with public (`us-east-2a/b`) and private (`us-east-2a/b`) subnets
- **NAT Gateway** in the public subnet for outbound traffic from private nodes
- **EKS 1.30** (`demo-eks-cluster`) with an `t3.medium` ON_DEMAND node group in private subnets
- **ECR** `<AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/<ECR_REPOSITORY>` as the image registry
- **NGINX Ingress Controller** exposed via LoadBalancer; host `<YOUR_DOMAIN>`
- **SQLite** persisted on a `gp2` 1Gi PVC inside the cluster

---

## Dockerfile

Multi-stage build using `python:3.11.3-slim`:

1. **Builder stage** — installs dependencies from `src/requirements.txt`
2. **Runtime stage** — copies only the installed packages and source code

In production the container runs migrations and starts Gunicorn with 2 workers / 2 threads on port `8000`.

```bash
# Local build
docker build -t devops-project:latest .

# Local run
docker run -p 8000:8000 \
  -e DJANGO_SECRET_KEY=<secret> \
  -e DATABASE_NAME=db.sqlite3 \
  devops-project:latest
```

---

## Terraform — Infrastructure

> **Cluster base image:** `python:3.11.3-slim` (used in the Dockerfile pushed to ECR).  
> The EKS module uses `t3.medium` nodes and Kubernetes version `1.30`.

### Requirements

| Tool | Minimum version |
|------|----------------|
| Terraform | >= 1.0 |
| AWS CLI | >= 2.x |
| AWS Provider (hashicorp/aws) | ~> 5.49 |

AWS credentials configured with permissions to create VPC, EKS, IAM roles, ECR, and NAT Gateway.

### Deploying the infrastructure

```bash
cd terraform

# 1. Initialize providers and modules
terraform init

# 2. Review the plan (uses env=demo by default)
terraform plan

# 3. Apply
terraform apply

# For a different environment:
terraform apply -var="env=staging"
```

The `env` variable (default `demo`) prefixes all resources: cluster, subnets, roles, etc.

### Modules

```
terraform/
├── main.tf            # Orchestrates all modules
├── locals.tf          # CIDRs, AZs, EKS version, node type
├── variables.tf       # var.env (default: "demo")
└── modules/
    ├── networking/
    │   ├── vpc/       # VPC + IGW
    │   ├── subnets/   # 2 public + 2 private
    │   ├── nat/       # NAT Gateway
    │   └── routing/   # Route tables + associations
    └── eks/
        ├── roles/     # IAM roles for cluster and node group
        ├── (eks)/     # EKS cluster + general node group
        └── addon/     # OIDC + cluster addons
```

### Destroy infrastructure

```bash
terraform destroy
```

---

## Helm

Chart `demo-devops-python` (version `0.1.0`) located in `helm/`.

Key configurable values in `helm/values.yaml`:

| Value | Description |
|-------|-------------|
| `image.repository` | ECR repository URL |
| `image.tag` | Image tag to deploy |
| `secret.djangoSecretKey` | Django secret key |
| `ingress.host` | Ingress hostname |
| `persistence.storageClass` | PVC storage class (default: `gp2`) |
| `app.gunicornWorkers` / `app.gunicornThreads` | Gunicorn workers and threads |

### Manual deploy with Helm

```bash
# Configure kubectl against the cluster
aws eks update-kubeconfig --region <AWS_REGION> --name <EKS_CLUSTER_NAME>

# Install / upgrade
helm upgrade --install demo-devops-python helm/ \
  --set image.repository=<AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/<ECR_REPOSITORY> \
  --set image.tag=<BUILD_NUMBER> \
  --set ingress.host=<YOUR_DOMAIN> \
  --set secret.djangoSecretKey="<secret>" \
  --set persistence.storageClass=gp2 \
  --create-namespace \
  --namespace demo-devops \
  --wait --timeout 5m
```

---

## CI/CD Pipeline (Jenkins)

The pipeline is defined in `cicd-pipeline/jenkinsfile` and runs the following stages in order:

| # | Stage | Description |
|---|-------|-------------|
| 1 | Checkout | Clones the repository |
| 2 | Install dependencies | Creates virtualenv and installs dependencies + QA tools |
| 3 | Unit tests | `python manage.py test tests` — publishes JUnit results |
| 4 | Static Code Analysis | Flake8 (max 120 chars) — publishes JUnit report |
| 5 | Code Coverage | `coverage run` + `coverage xml` — publishes Cobertura report |
| 6 | Build Image | `docker build` tagged with `BUILD_NUMBER` and `latest` |
| 7 | Push Image | ECR login and push of both tags |
| 8 | Configure kubectl | `aws eks update-kubeconfig` pointing to the cluster |
| 9 | Install Ingress Controller | Installs `ingress-nginx` via Helm (if not present) |
| 10 | Deploy with Helm | `helm upgrade --install` in the `demo-devops` namespace |

### Requirements on the Jenkins server

**Software installed on the agent:**

- Python 3.x with `pip`
- Docker (daemon accessible by the agent)
- AWS CLI v2
- `kubectl`
- Helm 3

**Credentials configured in Jenkins** (`Manage Jenkins → Credentials`):

| ID | Type | Usage |
|----|------|-------|
| `django-secret-key` | Secret text | Django `SECRET_KEY` |
| `aws-creds` | AWS Credentials (access key + secret) | ECR push, EKS kubeconfig, Helm deploy |

### How to run the pipeline

1. Create a new **Pipeline** job in Jenkins.
2. Under *Pipeline definition* select **Pipeline script from SCM**.
3. Point to the repository and set the script path to `cicd-pipeline/jenkinsfile`.
4. Trigger with **Build Now**.

The pipeline expects the ECR repository `devops-project` to already exist in the AWS account before the *Push Image* stage.  
The EKS cluster `demo-eks-cluster` must be running (via Terraform) before the *Configure kubectl* stage.

---

## Testing the live API

Base URL: `http://demo.devopsweb.pw/api/users/`

**Create a user**
```bash
curl -X POST http://demo.devopsweb.pw/api/users/ \
  -H "Content-Type: application/json" \
  -d '{"dni": "1234567890123", "name": "John Doe"}'
# → 201 Created
```

**List all users**
```bash
curl http://demo.devopsweb.pw/api/users/
# → 200 OK
```

**Retrieve a single user**
```bash
curl http://demo.devopsweb.pw/api/users/1/
# → 200 OK | 404 Not Found
```
