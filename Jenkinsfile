pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                echo "Branch: ${env.BRANCH_NAME}"
                checkout scm
            }
        }

        stage('Build Test Image') {
            steps {
                sh '''
                    docker build \
                        -f Dockerfile.test \
                        -t php-sample-test:${BUILD_NUMBER} .
                '''
            }
        }

        stage('PHP Tests') {
            steps {
                sh '''
                    docker run --rm \
                        php-sample-test:${BUILD_NUMBER}
                '''
            }
        }

        stage('GitLeaks') {
            steps {
                sh '''
                    docker run --rm \
                        -v "$WORKSPACE:/repo" \
                        zricethezav/gitleaks:latest \
                        detect \
                        --source=/repo \
                        --no-banner
                '''
            }
        }
    }

    post {
        success {
            echo 'CI PHP réussie !'
        }

        failure {
            echo 'CI PHP échouée.'
        }

        always {
            echo "Build #${BUILD_NUMBER} terminé."
        }
    }
}