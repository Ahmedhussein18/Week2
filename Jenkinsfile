pipeline {
    agent any

    environment {
        ANSIBLE_HOST = "192.168.100.117"
        ANSIBLE_USER = "shekshek"
        SSH_KEY_ID = "jenkins-ssh"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/spring-projects/spring-petclinic.git'
            }
        }

        stage('Build WAR') {
            steps {
                 
                    sh '/home/pet-clinic/ansible/jar-to-war.sh'
                
            }
        }

        stage('Run Ansible: Deploy') {
            steps {
                sshagent([env.SSH_KEY_ID]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${ANSIBLE_USER}@${ANSIBLE_HOST} \\
                        'cd /home/${ANSIBLE_USER}/ansible && \\
                         ansible-playbook -i inventory.ini deploy.yml'
                    """
                }
            }
        }

        stage('Run Ansible: Sanity Check') {
            steps {
                sshagent([env.SSH_KEY_ID]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${ANSIBLE_USER}@${ANSIBLE_HOST} \\
                        'cd /home/${ANSIBLE_USER}/petclinic-ansible && \\
                         ansible-playbook -i inventory.ini sanity.yml'
                    """
                }
            }
        }

        stage('Run Ansible: Configure Nagios') {
            steps {
                sshagent([env.SSH_KEY_ID]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${ANSIBLE_USER}@${ANSIBLE_HOST} \\
                        'cd /home/${ANSIBLE_USER}/petclinic-ansible && \\
                         ansible-playbook -i inventory.ini nagios_monitoring.yml'
                    """
                }
            }
        }
    }
}
