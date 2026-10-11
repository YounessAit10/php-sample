pipeline {
    agent any

    environment {
    DOCKERHUB_REPO = 'youness10/php-sample'
}

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

        stage('Build Production Image') {
            when { anyOf { branch 'main'; branch 'dev' } }
            steps {
                sh '''
                    docker build \
                        -t ${DOCKERHUB_REPO}:${BUILD_NUMBER} \
                        -t ${DOCKERHUB_REPO}:${BRANCH_NAME} .
                '''
            }
        }

        stage('Trivy Image Scan') {
            when { anyOf { branch 'main'; branch 'dev' } }
            steps {
                sh '''
                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        -v trivy-cache:/root/.cache/ \
                        aquasec/trivy:latest image \
                        --scanners vuln \
                        --skip-db-update \
                        --skip-java-db-update \
                        --severity HIGH,CRITICAL \
                        --ignore-unfixed \
                        --exit-code 0 \
                        ${DOCKERHUB_REPO}:${BUILD_NUMBER}
                '''
            }
        }

        stage('Push to Docker Hub') {
            when { anyOf { branch 'main'; branch 'dev' } }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DH_USER',
                    passwordVariable: 'DH_TOKEN'
                )]) {
                    sh '''
                        echo "$DH_TOKEN" | docker login -u "$DH_USER" --password-stdin
                        docker push ${DOCKERHUB_REPO}:${BUILD_NUMBER}
                        docker push ${DOCKERHUB_REPO}:${BRANCH_NAME}
                    '''
                }
            }
        }

        stage('Deploy') {
            when { anyOf { branch 'main'; branch 'dev' } }
            steps {
                script {
                    env.APP_ENV  = (env.BRANCH_NAME == 'main') ? 'prod' : 'dev'
                    env.APP_PORT = (env.BRANCH_NAME == 'main') ? '8082' : '8081'
                }
                sh '''
                    export IMAGE_TAG=${BUILD_NUMBER}
                    docker compose -p php-sample-${APP_ENV} pull
                    docker compose -p php-sample-${APP_ENV} up -d --remove-orphans

                    # Vérification : l'application répond-elle ?
                    for i in 1 2 3 4 5 6; do
                        curl -fs http://host.docker.internal:${APP_PORT} > /dev/null && echo "App OK" && exit 0
                        sleep 5
                    done
                    echo "L'application ne répond pas" && docker compose -p php-sample-${APP_ENV} logs && exit 1
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