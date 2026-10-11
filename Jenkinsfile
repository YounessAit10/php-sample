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

        // stage('Trivy FS Scan') {
        //     steps {
        //         sh '''
        //             docker run --rm \
        //                 --volumes-from jenkins \
        //                 -w "$WORKSPACE" \
        //                 -v trivy-cache:/root/.cache/ \
        //                 aquasec/trivy:latest fs \
        //                 --scanners vuln,secret,misconfig \
        //                 --severity HIGH,CRITICAL \
        //                 --ignore-unfixed \
        //                 --exit-code 1 \
        //                 .
        //         '''
        //     }
        // }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        -v trivy-cache:/root/.cache/ \
                        aquasec/trivy:latest image \
                        --timeout 20m \
                        --db-repository public.ecr.aws/aquasecurity/trivy-db:2,ghcr.io/aquasecurity/trivy-db:2 \
                        --skip-java-db-update \
                        --severity HIGH,CRITICAL \
                        --ignore-unfixed \
                        --exit-code 1 \
                        php-sample-test:${BUILD_NUMBER}
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