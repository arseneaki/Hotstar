pipeline {
    agent any
    
    tools {
        jdk 'jdk21'
        nodejs 'node18'  // Updated to node18
    }
    
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKER_REGISTRY = 'arseneaki17'
        DOCKER_IMAGE = "${DOCKER_REGISTRY}/hotstar"
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        K8S_NAMESPACE = 'default'
        NODE_ENV = 'production'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        ansiColor('xterm')
    }
    
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        
        stage('Checkout from Git') {
            steps {
                checkout scm: [
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[url: 'https://github.com/arseneaki/Hotstar.git']]
                ]
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh '''
                    echo "📦 Installing dependencies..."
                    npm ci --prefer-offline --no-audit
                '''
            }
        }
        
        stage('Lint Code') {
            steps {
                sh '''
                    echo "🔍 Running linter..."
                    npm run lint || true
                '''
            }
        }
        
        stage('Run Tests') {
            steps {
                sh '''
                    echo "🧪 Running tests..."
                    npm test -- --coverage --watchAll=false || true
                '''
            }
            post {
                always {
                    publishTestResults testResultsPattern: '**/test-results.xml'
                    publishCoverage adapters: [
                        coberturaAdapter('coverage/cobertura-coverage.xml')
                    ], sourceFileResolver: sourceFiles('STORE_LAST_BUILD')
                }
            }
        }
        
        stage('Sonarqube Analysis') {
            steps {
                withSonarQubeEnv('Sonar-server') {
                    sh '''
                        echo "🔎 Running SonarQube analysis..."
                        $SCANNER_HOME/bin/sonar-scanner \
                            -Dsonar.projectName=Hotstar \
                            -Dsonar.projectKey=Hotstar \
                            -Dsonar.sources=src \
                            -Dsonar.exclusions=**/node_modules/**,**/build/**,**/*.test.js
                    '''
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    echo "⏳ Waiting for Quality Gate..."
                    waitForQualityGate abortPipeline: true, credentialsId: 'Sonar-token'
                }
            }
        }
        
        stage('Build Application') {
            steps {
                sh '''
                    echo "🏗️ Building React application..."
                    npm run build
                '''
            }
            post {
                success {
                    archiveArtifacts artifacts: 'build/**', fingerprint: true
                }
            }
        }
        
        stage('OWASP Dependency Check') {
            steps {
                script {
                    echo "🔒 Running OWASP Dependency Check..."
                    dependencyCheck(
                        additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit --format ALL',
                        odcInstallation: 'DP-Check'
                    )
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }
        
        stage('Docker Scout FS') {
            steps {
                script {
                    echo "🐳 Running Docker Scout filesystem scan..."
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh '''
                            docker-scout quickview fs://. || true
                            docker-scout cves fs://. || true
                        '''
                    }
                }
            }
        }
        
        stage('Docker Build & Push') {
            steps {
                script {
                    echo "🐳 Building and pushing Docker image..."
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh '''
                            docker build -t ${DOCKER_IMAGE}:${DOCKER_IMAGE_TAG} .
                            docker tag ${DOCKER_IMAGE}:${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE}:latest
                            
                            echo "📤 Pushing images..."
                            docker push ${DOCKER_IMAGE}:${DOCKER_IMAGE_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                            
                            echo "✅ Image pushed: ${DOCKER_IMAGE}:${DOCKER_IMAGE_TAG}"
                        '''
                    }
                }
            }
        }
        
        stage('Docker Scout Image') {
            steps {
                script {
                    echo "🔍 Scanning Docker image with Docker Scout..."
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh '''
                            docker-scout quickview ${DOCKER_IMAGE}:latest || true
                            docker-scout cves ${DOCKER_IMAGE}:latest || true
                            docker-scout recommendations ${DOCKER_IMAGE}:latest || true
                        '''
                    }
                }
            }
        }
        
        stage('Deploy Docker Container') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "🚀 Deploying Docker container..."
                    sh '''
                        docker stop hotstar || true
                        docker rm hotstar || true
                        
                        docker run -d \
                            --name hotstar \
                            -p 3000:3000 \
                            --restart unless-stopped \
                            ${DOCKER_IMAGE}:latest
                        
                        sleep 5
                        docker ps | grep hotstar
                        
                        echo "⏳ Waiting for health check..."
                        for i in {1..30}; do
                            if curl -f http://localhost:3000/health > /dev/null 2>&1; then
                                echo "✅ Health check passed"
                                exit 0
                            fi
                            echo "Attempt $i/30... Waiting for service"
                            sleep 2
                        done
                        
                        echo "⚠️ Health check timeout"
                        exit 1
                    '''
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "☸️ Deploying to Kubernetes cluster..."
                    dir('K8S') {
                        withKubeConfig(
                            caCertificate: '',
                            clusterName: '',
                            contextName: '',
                            credentialsId: 'k8s',
                            namespace: "${K8S_NAMESPACE}",
                            restrictKubeConfigAccess: false,
                            serverUrl: ''
                        ) {
                            sh '''
                                echo "🔍 Checking kubeconfig..."
                                kubectl config current-context
                                kubectl get nodes
                                
                                echo "📋 Applying Kubernetes manifests..."
                                kubectl apply -f serviceaccount.yml
                                kubectl apply -f secret.yml
                                kubectl apply -f deployment.yml
                                kubectl apply -f service.yml
                                
                                echo "⏳ Waiting for rollout..."
                                kubectl rollout status deployment/hotstar -n ${K8S_NAMESPACE} --timeout=5m
                                
                                echo "✅ Checking deployment status..."
                                kubectl get deployment -n ${K8S_NAMESPACE}
                                kubectl get pods -n ${K8S_NAMESPACE}
                                kubectl get svc -n ${K8S_NAMESPACE}
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Smoke Tests') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo "🔥 Running smoke tests..."
                    sh '''
                        SERVICE_IP=$(kubectl get svc hotstar-service -n ${K8S_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "localhost:3000")
                        
                        echo "Testing service at: $SERVICE_IP"
                        
                        for i in {1..30}; do
                            if curl -f -s http://$SERVICE_IP/health > /dev/null 2>&1; then
                                echo "✅ Health check passed"
                                curl -s http://$SERVICE_IP/health | jq . || echo "Health endpoint response received"
                                exit 0
                            fi
                            echo "Attempt $i/30... Waiting for service"
                            sleep 5
                        done
                        
                        echo "⚠️ Service not responding"
                        exit 1
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Archiving artifacts..."
            archiveArtifacts artifacts: '**/*-report.xml,**/coverage/**', allowEmptyArchive: true
            cleanWs(deleteDirs: true, patterns: [[pattern: 'node_modules/**', type: 'INCLUDE']])
        }
        
        success {
            echo "✅ Pipeline completed successfully"
        }
        
        failure {
            echo "❌ Pipeline failed - Check logs above"
        }
        
        unstable {
            echo "⚠️ Pipeline unstable"
        }
    }
}
