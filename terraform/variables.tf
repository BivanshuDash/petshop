variable "cluster_name" {
  description = "Name of the Minikube cluster"
  type        = string
  default     = "petshop"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use"
  type        = string
  default     = "v1.25.3"
}

variable "minikube_memory" {
  description = "Memory allocation for Minikube in MB"
  type        = number
  default     = 4096  # 4GB of RAM
}

variable "minikube_cpus" {
  description = "CPU cores for Minikube"
  type        = number
  default     = 2
}