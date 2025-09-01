pipeline {
    agent any

    environment {
        DOCKER_HUB_REPO = 'anikesh372/microservice'
        K8S_CLUSTER_NAME = 'microservice-cluster'
        AWS_REGION = 'eu-north-1'
        NAMESPACE = 'default'
        APP_NAME = 'microservice'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                git 'https://github.com/Anikesh-developer/microservices-ingress.git'
            }
        }

        stage('Install NPM Packages') {
            steps {
                sh 'npm install'
                
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    def buildNumber = env.BUILD_NUMBER
                    def imageTag = "${DOCKER_HUB_REPO}:${buildNumber}"
                    def latestTag = "${DOCKER_HUB_REPO}:latest"

                    sh "docker build -t ${imageTag} ."
                    sh "docker tag ${imageTag} ${latestTag}"

                    env.IMAGE_TAG = buildNumber
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                echo 'Pushing Docker image to DockerHub...'
                script {
                    withCredentials([usernamePassword(credentialsId: 'anikesh372', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh "echo \${DOCKER_PASSWORD} | docker login -u \${DOCKER_USERNAME} --password-stdin"
                        sh "docker push ${DOCKER_HUB_REPO}:${env.IMAGE_TAG}"
                        sh "docker push ${DOCKER_HUB_REPO}:latest"
                    }
                }
            }
        }

        stage('Configure AWS and Kubectl') {
            steps {
                echo 'Configuring AWS CLI and kubectl...'
                script {
                    withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'Aws-creds', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh "aws configure set region ${AWS_REGION}"
                        sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${K8S_CLUSTER_NAME}"
                        sh "kubectl config current-context"
                        sh "kubectl get nodes"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying application to Kubernetes...'
                script {
                    withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'Aws-creds', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh "sed -i 's|anikesh372/microservice:latest|anikesh372/microservice:${env.IMAGE_TAG}|g' k8s/deployment.yaml"
                        sh "kubectl apply -f k8s/deployment.yaml"
                    }
                }
            }
        }

        stage('Deploy Service') {
            steps {
                echo 'Deploying Service resource...'
                script {
                    withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'Aws-creds', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh "kubectl apply -f k8s/service.yaml"
                    }
                }
            }
        }

        stage('Deploy Ingress') {
            steps {
                echo 'Deploying Ingress resource...'
                script {
                    withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'Aws-creds', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh "kubectl apply -f k8s/ingress.yaml"
                    }
                }
            }
        }

        stage('Get Ingress URL') {
            steps {
                echo 'Getting Ingress URL...'
                script {
                    withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'Aws-creds', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        timeout(time: 10, unit: 'MINUTES') {
                            waitUntil {
                                script {
                                    def result = sh(
                                        script: "kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'",
                                        returnStdout: true
                                    ).trim()

                                    if (result && result != '') {
                                        env.INGRESS_URL = "http://${result}"
                                        echo "Ingress URL: ${env.INGRESS_URL}"
                                        return true
                                    }
                                    return false
                                }
                            }
                        }

                        echo "========================================="
                        echo "DEPLOYMENT SUCCESSFUL!"
                        echo "========================================="
                        echo "Application URL: ${env.INGRESS_URL}"
                        echo ""
                        echo "Available Paths:"
                        echo "- Home Page: ${env.INGRESS_URL}/"
                        echo "- About Page: ${env.INGRESS_URL}/about"
                        echo "- Services Page: ${env.INGRESS_URL}/services"
                        echo "- Contact Page: ${env.INGRESS_URL}/contact"
                        echo "========================================="

                        sh "curl -I ${env.INGRESS_URL}/ || echo 'Home page check failed'"
                        sh "curl -I ${env.INGRESS_URL}/about || echo 'About page check failed'"
                        sh "curl -I ${env.INGRESS_URL}/services || echo 'Services page check failed'"
                        sh "curl -I ${env.INGRESS_URL}/contact || echo 'Contact page check failed'"
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up Docker images...'
            sh "docker rmi ${DOCKER_HUB_REPO}:${env.IMAGE_TAG} || true"
            sh "docker rmi ${DOCKER_HUB_REPO}:latest || true"
        }

        success {
            echo 'Pipeline completed successfully!'
            echo "Access your application at: ${env.INGRESS_URL}"
        }

        failure {
            echo 'Pipeline failed! Please check the logs.'
        }
    }
}
