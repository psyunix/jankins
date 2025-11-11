// Example Jenkins Pipeline for Building and Pushing Web Server Image
// Save this as 'Jenkinsfile' in your repository root
// Then create a Pipeline job in Jenkins pointing to this file

pipeline {
    agent any
    
    environment {
        // GitHub Container Registry configuration
        GHCR_REGISTRY = 'ghcr.io'
        GHCR_REPO = 'psyunix/jenkins'
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
                    echo '🛠 Adding package update to Dockerfile...'
                    sh '''
                        # Create updated Dockerfile with upgrade
                        sed '/apt-get update/a\    apt-get upgrade -y \' Dockerfile.webserver > Dockerfile.webserver.tmp
                        mv Dockerfile.webserver.tmp Dockerfile.webserver
                    '''
                }
            }
        }

        stage('Check Docker Access') {
            steps {
                script {
                    echo '🔍 Checking Docker daemon access...'
                    def rc = sh(script: 'docker info > /dev/null 2>&1', returnStatus: true)
                    if (rc != 0) {
                        error '''Docker is not accessible from this Jenkins executor.
Troubleshooting:
 - Ensure /var/run/docker.sock is mounted into the Jenkins container/agent.
 - Ensure the Jenkins user is in the docker group (GID matches that of the socket: ls -l /var/run/docker.sock).
 - Or configure a proper Docker agent (e.g. docker cloud, k8s pod with dind).
Aborting before attempting build stages.'''                    } else {
                        sh 'docker version --format "Client {{.Client.Version}} | Server {{.Server.Version}}" || true'
                    }
                }
            }
        }
        
        stage('Build Image') {
            steps {
                script {
                    echo '🔨 Building Docker image...'
                    sh """
                        docker build -f Dockerfile.webserver \
                          -t ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest \
                          -t ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:build-${BUILD_NUMBER} \
                          -t ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:git-${GIT_COMMIT.take(7)} \
                          .
                    """
                }
            }
        }
        
        stage('Test Image') {
            steps {
                script {
                    echo '🧪 Testing built image...'
                    sh """
                        echo 'Testing vim...'
                        docker run --rm ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest which vim
                        echo 'Testing mc...'
                        docker run --rm ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest which mc
                        echo 'Testing curl...'
                        docker run --rm ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest curl --version
                        echo 'Testing PHP...'
                        docker run --rm ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest php --version

                        echo 'Starting test container...'
                        docker run -d --name test-webserver-${BUILD_NUMBER} \
                          -p 8082:80 \
                          ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest

                        echo 'Waiting for web server...'
                        sleep 15

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
                        echo '${DOCKER_CREDENTIALS_PSW}' | docker login ${GHCR_REGISTRY} \
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
                    echo '🚀 Pushing image to GitHub Container Registry...'
                    sh """
                        docker push ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest
                        docker push ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:build-${BUILD_NUMBER}
                        docker push ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:git-${GIT_COMMIT.take(7)}
                    """
                }
            }
        }
        
        stage('Cleanup Test Container') {
            steps {
                script {
                    echo '🧼 Cleaning up test container...'
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
            echo '🎉 Pipeline completed successfully!'
            echo "✅ Image tags:"
            echo "  - ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:latest"
            echo "  - ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:build-${BUILD_NUMBER}"
            echo "  - ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:git-${GIT_COMMIT.take(7)}"
        }
        failure {
            echo '⚠️ Pipeline failed!'
        }
        always {
            script {
                echo '🧹 Final cleanup...'
                def hasDocker = (sh(script: 'docker info > /dev/null 2>&1', returnStatus: true) == 0)
                if (hasDocker) {
                    echo 'Docker available, performing safe cleanup (no full system prune).'
                    sh """
                        # Logout (ignore errors)
                        docker logout ${GHCR_REGISTRY} || true
                        # Remove dangling images only
                        docker image prune -f || true
                        # Remove build-specific tags to free space (ignore if in use)
                        docker rmi ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:build-${BUILD_NUMBER} 2>/dev/null || true
                        docker rmi ${GHCR_REGISTRY}/${GHCR_REPO}/${IMAGE_NAME}:git-${GIT_COMMIT.take(7)} 2>/dev/null || true
                        # Ensure test container gone
                        docker rm -f test-webserver-${BUILD_NUMBER} 2>/dev/null || true
                    """
                } else {
                    echo 'Skipping Docker cleanup: Docker not accessible (permission issue).'
                }
            }
        }
    }
}