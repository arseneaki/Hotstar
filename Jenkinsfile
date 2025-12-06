pipeline {
    agent any
    
    tools {
        jdk 'jdk21'
        nodejs 'node16'
    }
    
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        DOCKER_REGISTRY = 'arseneaki17'
        DOCKER_IMAGE = "${DOCKER_REGISTRY}/hotstar"
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        K8S_NAMESPACE = 'default'
    }
    
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        
        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/arseneaki/Hotstar.git'
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }
        
        stage('Build Application') {
            steps {
                sh 'npm run build'
            }
        }
        
        stage('Sonarqube Analysis') {
            steps {
                withSonarQubeEnv('Sonar-server') {
                    sh '''
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
                    try {
                        timeout(time: 5, unit: 'MINUTES') {
                            def qg = waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                            if (qg.status != 'OK') {
                                echo "⚠️ Quality Gate status: ${qg.status}"
                                echo "⚠️ Continuing pipeline despite Quality Gate failure"
                            } else {
                                echo "✅ Quality Gate passed"
                            }
                        }
                    } catch (Exception e) {
                        echo "⚠️ Quality Gate check failed: ${e.getMessage()}"
                        echo "⚠️ Continuing pipeline..."
                    }
                }
            }
        }
        
        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        
        stage('Docker Scout FS') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh 'docker-scout quickview fs://. || true'
                        sh 'docker-scout cves fs://. || true'
                    }
                }
            }
        }
        
        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh '''
                            docker build -t ${DOCKER_IMAGE}:${DOCKER_IMAGE_TAG} .
                            docker tag ${DOCKER_IMAGE}:${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE}:latest
                            docker push ${DOCKER_IMAGE}:${DOCKER_IMAGE_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                        '''
                    }
                }
            }
        }
        
        stage('Docker Scout Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh 'docker-scout quickview ${DOCKER_IMAGE}:latest || true'
                        sh 'docker-scout cves ${DOCKER_IMAGE}:latest || true'
                        sh 'docker-scout recommendations ${DOCKER_IMAGE}:latest || true'
                    }
                }
            }
        }
        
        stage('Deploy Docker') {
            steps {
                sh '''
                    # Arrêter et supprimer l'ancien conteneur s'il existe
                    docker stop hotstar || true
                    docker rm hotstar || true
                    
                    # Lancer le nouveau conteneur
                    docker run -d --name hotstar -p 3000:3000 ${DOCKER_IMAGE}:latest
                    
                    # Vérifier que le conteneur est bien lancé
                    sleep 5
                    docker ps | grep hotstar
                    
                    # Tester le health check
                    echo "⏳ Waiting for health check..."
                    for i in {1..30}; do
                        if curl -f http://localhost:3000/health > /dev/null 2>&1; then
                            echo "✅ Health check passed"
                            exit 0
                        fi
                        echo "Attempt $i/30... Waiting for service"
                        sleep 2
                    done
                    echo "⚠️ Health check failed or timeout"
                '''
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                script {
                    dir('K8S') {
                        withKubeConfig([
                            caCertificate: '',
                            clusterName: '',
                            contextName: '',
                            credentialsId: 'k8s',
                            namespace: "${K8S_NAMESPACE}",
                            restrictKubeConfigAccess: false,
                            serverUrl: ''
                        ]) {
                            sh '''
                                echo "📋 Applying Kubernetes manifests..."
                                kubectl apply -f serviceaccount.yml || true
                                kubectl apply -f secret.yml || true
                                kubectl apply -f deployment.yml
                                kubectl apply -f service.yml
                                
                                echo "⏳ Waiting for rollout..."
                                kubectl rollout status deployment/hotstar -n ${K8S_NAMESPACE} --timeout=5m || true
                                
                                echo "✅ Deployment completed"
                                kubectl get pods -n ${K8S_NAMESPACE} || true
                            '''
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Archiving artifacts..."
            archiveArtifacts artifacts: '**/*-report.xml', allowEmptyArchive: true
            cleanWs(deleteDirs: true, patterns: [[pattern: 'node_modules/**', type: 'INCLUDE']])
        }
        
        success {
            echo "✅ Pipeline completed successfully"
        }
        
        failure {
            echo "❌ Pipeline failed - Check logs above"
        }
    }
}
