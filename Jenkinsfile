pipeline {
    agent any
    
    tools {
        nodejs "Node 18.x"  // Use the name you specified in Global Tool Configuration
    }
    
    environment {
        DOCKER_HUB_CREDS = credentials('docker-hub-credentials')
        DOCKER_HUB_USERNAME = "${DOCKER_HUB_CREDS_USR}"
        BACKEND_IMAGE_NAME = "petshop-backend"
        FRONTEND_IMAGE_NAME = "petshop-frontend"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Verify Tools') {
            steps {
                sh 'node --version'
                sh 'npm --version'
            }
        }
        
        stage('Install Dependencies') {
            parallel {
                stage('Backend Dependencies') {
                    steps {
                        dir('petshop-backend') {
                            sh 'npm install'
                        }
                    }
                }
                
                stage('Frontend Dependencies') {
                    steps {
                        dir('petshop-frontend') {
                            sh 'npm install'
                        }
                    }
                }
            }
        }
        
        stage('Run Tests') {
            parallel {
                stage('Backend Tests') {
                    steps {
                        dir('petshop-backend') {
                            bat 'npm test'
                        }
                    }
                }
                
                stage('Frontend Tests') {
                    steps {
                        dir('petshop-frontend') {
                            bat 'npm test'
                        }
                    }
                }
            }
        }
        
        stage('Build Docker Images') {
            steps {
                bat "docker build -t %DOCKER_HUB_USERNAME%/%BACKEND_IMAGE_NAME%:%IMAGE_TAG% -t %DOCKER_HUB_USERNAME%/%BACKEND_IMAGE_NAME%:latest ./petshop-backend"
                bat "docker build -t %DOCKER_HUB_USERNAME%/%FRONTEND_IMAGE_NAME%:%IMAGE_TAG% -t %DOCKER_HUB_USERNAME%/%FRONTEND_IMAGE_NAME%:latest ./petshop-frontend"
            }
        }
        
        stage('Push Docker Images') {
            steps {
                withCredentials([string(credentialsId: 'docker-hub-credentials', variable: 'DOCKER_PWD')]) {
                    bat "docker login -u %DOCKER_HUB_USERNAME% -p %DOCKER_PWD%"
                }
                bat "docker push %DOCKER_HUB_USERNAME%/%BACKEND_IMAGE_NAME%:%IMAGE_TAG%"
                bat "docker push %DOCKER_HUB_USERNAME%/%BACKEND_IMAGE_NAME%:latest"
                bat "docker push %DOCKER_HUB_USERNAME%/%FRONTEND_IMAGE_NAME%:%IMAGE_TAG%"
                bat "docker push %DOCKER_HUB_USERNAME%/%FRONTEND_IMAGE_NAME%:latest"
            }
        }
        
        stage('Update Kubernetes Manifests') {
            steps {
                script {
                    // Create directory for manifests
                    bat "mkdir kubernetes-manifests 2>NUL || echo Directory already exists"
                    
                    // Copy existing manifests if they exist
                    bat "xcopy /E /Y /I .\\k8s\\* kubernetes-manifests\\ 2>NUL || echo No k8s directory found"
                    
                    // Create namespace.yaml if it doesn't exist
                    if (!fileExists('kubernetes-manifests/namespace.yaml')) {
                        writeFile file: 'kubernetes-manifests/namespace.yaml', text: """
                            apiVersion: v1
                            kind: Namespace
                            metadata:
                              name: petshop
                              labels:
                                name: petshop
                        """.stripIndent()
                    }
                    
                    // Create backend.yaml if it doesn't exist
                    if (!fileExists('kubernetes-manifests/backend.yaml')) {
                        writeFile file: 'kubernetes-manifests/backend.yaml', text: """
                            apiVersion: apps/v1
                            kind: Deployment
                            metadata:
                              name: petshop-backend
                              namespace: petshop
                              labels:
                                app: petshop-backend
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
                                    imagePullPolicy: Always
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
                        """.stripIndent()
                    }
                    
                    // Create frontend.yaml if it doesn't exist
                    if (!fileExists('kubernetes-manifests/frontend.yaml')) {
                        writeFile file: 'kubernetes-manifests/frontend.yaml', text: """
                            apiVersion: apps/v1
                            kind: Deployment
                            metadata:
                              name: petshop-frontend
                              namespace: petshop
                              labels:
                                app: petshop-frontend
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
                                    imagePullPolicy: Always
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
                              type: LoadBalancer
                        """.stripIndent()
                    }
                    
                    // Update image tags in the manifests - using PowerShell for this
                    powershell """
                        (Get-Content kubernetes-manifests/backend.yaml) -replace 'image: petshop-backend:latest', 'image: ${DOCKER_HUB_USERNAME}/${BACKEND_IMAGE_NAME}:${IMAGE_TAG}' | Set-Content kubernetes-manifests/backend.yaml
                        (Get-Content kubernetes-manifests/frontend.yaml) -replace 'image: petshop-frontend:latest', 'image: ${DOCKER_HUB_USERNAME}/${FRONTEND_IMAGE_NAME}:${IMAGE_TAG}' | Set-Content kubernetes-manifests/frontend.yaml
                    """
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                expression { 
                    return env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master'
                }
            }
            steps {
                script {
                    try {
                        // Try to deploy to Kubernetes with PowerShell
                        powershell """
                            kubectl create namespace petshop --dry-run=client -o yaml | kubectl apply -f -
                            kubectl apply -f kubernetes-manifests/namespace.yaml
                            kubectl apply -f kubernetes-manifests/backend.yaml
                            kubectl apply -f kubernetes-manifests/frontend.yaml
                            kubectl rollout status deployment/petshop-backend -n petshop --timeout=300s
                            kubectl rollout status deployment/petshop-frontend -n petshop --timeout=300s
                        """
                        
                        // Get NodePort information
                        def nodePort = powershell(
                            script: "kubectl get -o jsonpath='{.spec.ports[0].nodePort}' services petshop-frontend -n petshop",
                            returnStdout: true
                        ).trim()
                        
                        echo "Application deployed successfully!"
                        echo "If your cluster has LoadBalancer capabilities, the application should be accessible via the LoadBalancer IP."
                        echo "If using NodePort, the application is accessible at port: ${nodePort}"
                    } catch (Exception e) {
                        echo "Deployment was not successful. Either kubectl is not configured or there was an issue with the deployment."
                        echo "You can still manually apply the Kubernetes manifests from the workspace."
                        echo "${e.getMessage()}"
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Clean up Docker images to save space
            bat "docker rmi %DOCKER_HUB_USERNAME%/%BACKEND_IMAGE_NAME%:%IMAGE_TAG% || echo Image cleanup skipped"
            bat "docker rmi %DOCKER_HUB_USERNAME%/%BACKEND_IMAGE_NAME%:latest || echo Image cleanup skipped"
            bat "docker rmi %DOCKER_HUB_USERNAME%/%FRONTEND_IMAGE_NAME%:%IMAGE_TAG% || echo Image cleanup skipped"
            bat "docker rmi %DOCKER_HUB_USERNAME%/%FRONTEND_IMAGE_NAME%:latest || echo Image cleanup skipped"
        }
        
        success {
            echo "Pipeline completed successfully! 🚀"
        }
        
        failure {
            echo "Pipeline failed! 😢"
        }
    }
}    

    