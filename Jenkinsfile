// Example Jenkins Pipeline for Building and Pushing Web Server Image
// Save this as 'Jenkinsfile' in your repository root
// Then create a Pipeline job in Jenkins pointing to this file

pipeline {
    agent any
    
    environment {
        // GitHub Container Registry configuration
        GHCR_REGISTRY = 'ghcr.io'
        GHCR_REPO = 'psyunix/jankins'
        IMAGE_NAME = 'webserver'
        
        // Jenkins credentials ID (create this in Jenkins)
        DOCKER_CREDENTIALS = credentials('github-packages')
    }
    
    parameters {
        booleanParam(
            name: 'PUSH_TO_REGISTRY',
            defaultValue: true,
            description: 'Push the built image to GHCR?'
        )
        booleanParam(
            name: 'UPDATE_PACKAGES',
            defaultValue: false,
            description: 'Run apt-get upgrade before building?'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📦 Checking out source code...'
                checkout scm
            }
        }
        
        stage('Update Dockerfile (Optional)') {
            when {
                expression { params.UPDATE_PACKAGES == true }
            }
            steps {
                script {
                    echo '🔄 Adding package update to Dockerfile...'
                    sh '''
                        # Create updated Dockerfile with upgrade
                        sed '/apt-get update/a\\    apt-get upgrade -y \\&\\&' Dockerfile.webserver > Dockerfile.webserver.tmp
                        mv Dockerfile.webserver.tmp Dockerfile.webserver
                    '''
                }
            }
        }
        
        stage('Build Image') {
            steps {
                script {
                    echo '🏗️ Building Docker image...'
                    sh """
                        docker build -f Dockerfile.webserver \\
                            -t ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest \\
                            -t ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:build-${BUILD_NUMBER} \\
                            -t ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:${GIT_COMMIT.take(7)} \\
                            .
                    """
                }
            }
        }
        
        stage('Test Image') {
            steps {
                script {
                    echo '🧪 Testing built image...'
                    
                    // Test if required tools are installed
                    sh """
                        echo 'Testing vim...'
                        docker run --rm ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest which vim
                        
                        echo 'Testing mc...'
                        docker run --rm ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest which mc
                        
                        echo 'Testing curl...'
                        docker run --rm ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest curl --version
                        
                        echo 'Testing PHP...'
                        docker run --rm ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest php --version
                    """
                    
                    // Start container and test web server
                    sh """
                        echo 'Starting test container...'
                        docker run -d --name test-webserver-${BUILD_NUMBER} \\
                            -p 8082:80 \\
                            ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest
                        
                        # Wait for web server to start
                        echo 'Waiting for web server...'
                        sleep 15
                        
                        # Test HTTP response
                        echo 'Testing HTTP response...'
                        curl -f http://localhost:8082/ || exit 1
                        
                        echo '✅ All tests passed!'
                    """
                }
            }
        }
        
        stage('Login to GHCR') {
            when {
                expression { params.PUSH_TO_REGISTRY == true }
            }
            steps {
                script {
                    echo '🔐 Logging in to GitHub Container Registry...'
                    sh """
                        echo '${DOCKER_CREDENTIALS_PSW}' | docker login ${GHCR_REGISTRY} \\
                            -u '${DOCKER_CREDENTIALS_USR}' --password-stdin
                    """
                }
            }
        }
        
        stage('Push to Registry') {
            when {
                expression { params.PUSH_TO_REGISTRY == true }
            }
            steps {
                script {
                    echo '📤 Pushing image to GitHub Container Registry...'
                    sh """
                        docker push ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest
                        docker push ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:build-${BUILD_NUMBER}
                        docker push ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:${GIT_COMMIT.take(7)}
                    """
                }
            }
        }
        
        stage('Cleanup Test Container') {
            steps {
                script {
                    echo '🧹 Cleaning up test container...'
                    sh """
                        docker stop test-webserver-${BUILD_NUMBER} || true
                        docker rm test-webserver-${BUILD_NUMBER} || true
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline completed successfully!'
            echo "📦 Image tags:"
            echo "  - ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest"
            echo "  - ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:build-${BUILD_NUMBER}"
            echo "  - ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:${GIT_COMMIT.take(7)}"
        }
        failure {
            echo '❌ Pipeline failed!'
        }
        always {
            script {
                echo '🧹 Final cleanup...'
                sh """
                    docker logout ${GHCR_REGISTRY} || true
                    docker system prune -f || true
                """
            }
        }
    }
}
