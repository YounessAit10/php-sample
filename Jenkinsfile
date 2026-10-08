pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                echo "Branch: ${env.BRANCH_NAME}"
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    composer install \
                        --no-interaction \
                        --prefer-dist \
                        --no-progress
                '''
            }
        }

        stage('PHP Tests') {
            steps {
                sh '''
                    vendor/bin/phpunit
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline CI réussie !'
        }

        failure {
            echo 'Pipeline CI échouée.'
        }

        always {
            echo "Build #${BUILD_NUMBER} terminé."
        }
    }
}