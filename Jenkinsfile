pipeline{
    agent any
    tools{
        jdk 'jdk21'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
    }
    stages {
        stage('clean workspace'){
            steps{
                cleanWs()
            }
        }
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/arseneaki/Hotstar.git'
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('Sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Hotstar \
                    -Dsonar.projectKey=Hotstar'''
                }
            }
        }
        stage("quality gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
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
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       sh 'docker-scout quickview fs://.'
                       sh 'docker-scout cves fs://.'
                   }
                }   
            }
        }
        stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       sh "docker build -t hotstar ."
                       sh "docker tag hotstar arseneaki17/hotstar:latest"
                       sh "docker push arseneaki17/hotstar:latest"
                    }
                }
            }
        }
        stage('Docker Scout Image') {
            steps {
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       sh 'docker-scout quickview arseneaki17/hotstar:latest'
                       sh 'docker-scout cves arseneaki17/hotstar:latest'
                       sh 'docker-scout recommendations arseneaki17/hotstar:latest'
                   }
                }   
            }
        }
        stage("deploy_docker"){
            steps{
                sh '''
                # Arrêter et supprimer l'ancien conteneur s'il existe
                docker stop hotstar || true
                docker rm hotstar || true
                
                # Lancer le nouveau conteneur
                docker run -d --name hotstar -p 3000:3000 arseneaki17/hotstar:latest
                
                # Vérifier que le conteneur est bien lancé
                sleep 5
                docker ps | grep hotstar
                
                # Tester le health check
                curl -f http://localhost:3000/health || echo "Health check failed"
            '''
            }
        }
        stage('Deploy to kubernets'){
            steps{
                script{
                    dir('K8S') {
                        withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'k8s', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                                sh 'kubectl apply -f deployment.yml'
                                sh 'kubectl apply -f service.yml'
                        }   
                    }
                }
            }
        }
    }
}
