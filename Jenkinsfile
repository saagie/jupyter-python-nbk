pipeline {
    agent { node { label 'docker_image' } }

    options {
        disableConcurrentBuilds()
    }

    stages {
        stage('Build Jupyter images') {
            steps {
                script {
                    sh "docker build -t saagie/jupyter-python-nbk:v2_wip ."
                    sh "docker build -t saagie/jupyter-python-nbk:v2-cuda_wip --build-arg BASE_CONTAINER=saagie/jupyter-python-nbk:v2 -f cuda/Dockerfile ./cuda"
                }
            }
        }

        stage('Push techno images') {
            steps {
                script {
                    withCredentials(
        [usernamePassword(credentialsId: '8fc4964e-30c6-4bb9-8a19-69e37ea905b6',
                usernameVariable: 'USERNAME',
                passwordVariable: 'PASSWORD')]) {

                        sh "docker login -u $USERNAME -p $PASSWORD"
                        sh "docker push saagie/jupyter-python-nbk:v2_wip"
                        sh "docker push saagie/jupyter-python-nbk:v2-cuda_wip"
                    }
                }
            }
        }
    }
}
