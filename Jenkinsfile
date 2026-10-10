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

        stage('Debug Sonar') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        echo "URL: $SONAR_HOST_URL"
                        echo "Token length: ${#SONAR_AUTH_TOKEN}"
                        curl -s -u "$SONAR_AUTH_TOKEN:" "$SONAR_HOST_URL/api/authentication/validate"
                        echo
                        curl -s -u "$SONAR_AUTH_TOKEN:" "$SONAR_HOST_URL/api/components/show?component=php-sample"
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'
                    withSonarQubeEnv('SonarQube') {
                        sh "${scannerHome}/bin/sonar-scanner"
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
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