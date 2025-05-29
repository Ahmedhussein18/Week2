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
                git 'https://github.com/ahmedhussein18/Week2.git'
            }
        }

        stage('Build WAR') {
            steps {
                sh './build_petclinic.sh'
            }
        }

        stage('Run Ansible: Deploy') {
            steps {
                sshagent([env.SSH_KEY_ID]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${ANSIBLE_USER}@${ANSIBLE_HOST} \\
                        'cd /home/${ANSIBLE_USER}/ansible && \\
                         ansible-playbook -i inventory.ini deploy_petclinic.yml'
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
                         ansible-playbook -i inventory.ini sanity_check.yml'
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
