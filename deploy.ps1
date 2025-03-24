# Simplified PetShop Deployment Script

# Step 1: Build Docker images
Write-Host "Building Docker images..." -ForegroundColor Cyan
docker build -t petshop-backend:latest ./petshop-backend
docker build -t petshop-frontend:latest ./petshop-frontend
Write-Host "Docker images built successfully" -ForegroundColor Green

# Step 2: Delete existing Minikube cluster if it exists
Write-Host "Checking for existing Minikube cluster..." -ForegroundColor Cyan
minikube delete -p petshop

# Step 3: Start Minikube with standard configuration
Write-Host "Starting Minikube..." -ForegroundColor Cyan
minikube start --driver=docker --profile=petshop --memory=4096 --cpus=2 --kubernetes-version=v1.27.4

# Step 4: Load Docker images into Minikube
Write-Host "Loading Docker images into Minikube..." -ForegroundColor Cyan
minikube image load petshop-backend:latest --profile=petshop
minikube image load petshop-frontend:latest --profile=petshop

# Step 5: Create YAML files for Kubernetes resources
$backendYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petshop-backend
  namespace: petshop
spec:
  replicas: 1
  selector:
    matchLabels:
      app: petshop-backend
  template:
    metadata:
      labels:
        app: petshop-backend
    spec:
      containers:
      - name: backend
        image: petshop-backend:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: petshop-backend
  namespace: petshop
spec:
  selector:
    app: petshop-backend
  ports:
  - port: 5000
    targetPort: 5000
  type: ClusterIP
"@

$frontendYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petshop-frontend
  namespace: petshop
spec:
  replicas: 1
  selector:
    matchLabels:
      app: petshop-frontend
  template:
    metadata:
      labels:
        app: petshop-frontend
    spec:
      containers:
      - name: frontend
        image: petshop-frontend:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: petshop-frontend
  namespace: petshop
spec:
  selector:
    app: petshop-frontend
  ports:
  - port: 80
    targetPort: 80
  type: NodePort
"@

# Step 6: Create namespace
Write-Host "Creating namespace..." -ForegroundColor Cyan
kubectl create namespace petshop

# Step 7: Apply backend YAML
Write-Host "Deploying backend..." -ForegroundColor Cyan
$backendYaml | kubectl apply -f -

# Step 8: Apply frontend YAML
Write-Host "Deploying frontend..." -ForegroundColor Cyan
$frontendYaml | kubectl apply -f -

# Step 9: Wait for deployments to be ready
Write-Host "Waiting for backend deployment to be ready..." -ForegroundColor Cyan
kubectl wait --namespace=petshop --for=condition=available --timeout=300s deployment/petshop-backend

Write-Host "Waiting for frontend deployment to be ready..." -ForegroundColor Cyan
kubectl wait --namespace=petshop --for=condition=available --timeout=300s deployment/petshop-frontend

# Step 10: Get the NodePort URL
$nodePort = kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services petshop-frontend -n petshop
$minikubeIp = minikube ip -p petshop
Write-Host "NodePort URL: http://$minikubeIp`:$nodePort" -ForegroundColor Yellow

# Step 11: Also set up port forwarding for reliable access
Write-Host "Setting up port forwarding..." -ForegroundColor Cyan
$portForwardJob = Start-Job -ScriptBlock { kubectl port-forward svc/petshop-frontend -n petshop 8080:80 }

Write-Host "Application is running!" -ForegroundColor Green
Write-Host "Access your application at: http://localhost:8080" -ForegroundColor Yellow
Write-Host "To stop port forwarding when done: Stop-Job $($portForwardJob.Id); Remove-Job $($portForwardJob.Id)" -ForegroundColor White