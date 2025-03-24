# PetShop Minikube Cleanup Script

Write-Host "Starting PetShop cleanup..." -ForegroundColor Cyan

# Step 1: Stop any port forwarding jobs
$portForwardJobs = Get-Job | Where-Object { $_.Command -like "*port-forward*" }
if ($portForwardJobs) {
    Write-Host "Stopping port forwarding jobs..." -ForegroundColor Cyan
    $portForwardJobs | Stop-Job
    $portForwardJobs | Remove-Job
}

# Step 2: Delete Kubernetes resources
Write-Host "Deleting Kubernetes resources..." -ForegroundColor Cyan
kubectl delete -f ./k8s/frontend.yaml --ignore-not-found
kubectl delete -f ./k8s/backend.yaml --ignore-not-found
kubectl delete -f ./k8s/namespace.yaml --ignore-not-found

# Step 3: Stop Minikube
Write-Host "Stopping Minikube..." -ForegroundColor Cyan
minikube stop -p petshop

# Step 4: Delete Minikube cluster if desired
$deleteCluster = Read-Host "Do you want to delete the Minikube cluster? (y/n)"
if ($deleteCluster -eq "y") {
    Write-Host "Deleting Minikube cluster..." -ForegroundColor Cyan
    minikube delete -p petshop
}

# Step 5: Remove Docker images if desired
$removeImages = Read-Host "Do you want to remove the Docker images? (y/n)"
if ($removeImages -eq "y") {
    Write-Host "Removing Docker images..." -ForegroundColor Cyan
    docker rmi petshop-frontend:latest -f
    docker rmi petshop-backend:latest -f
}

Write-Host "Cleanup completed successfully!" -ForegroundColor Green