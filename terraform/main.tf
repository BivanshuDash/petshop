terraform {
  required_providers {
    minikube = {
      source  = "scott-the-programmer/minikube"
      version = "~> 0.3.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "minikube" {
  # No additional configuration needed for default setup
}

resource "minikube_cluster" "petshop_cluster" {
  driver             = "docker"  # Using Docker as the driver for Minikube
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  
  # Enable useful addons
  addons = [
    "dashboard",     # Kubernetes dashboard
    "metrics-server" # Metrics for monitoring
  ]
  
  # Resource allocation
  memory = var.minikube_memory
  cpus   = var.minikube_cpus
}

# Output the kubectl command to use the Minikube cluster
output "kubectl_command" {
  value       = "kubectl config use-context ${var.cluster_name}"
  description = "Command to switch kubectl context to the Minikube cluster"
}

# Output the minikube command to get the cluster IP
output "get_ip_command" {
  value       = "minikube ip -p ${var.cluster_name}"
  description = "Command to get the IP address of the Minikube cluster"
}