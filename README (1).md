# Spring Petclinic – CI/CD & Monitoring Stack

This project sets up a fully automated CI/CD and monitoring pipeline for the [Spring Petclinic](https://github.com/spring-projects/spring-petclinic) demo application using **Ansible**, **Jenkins**, **Tomcat**, and **Nagios**.

---

## 📁 Project Structure

```bash
ansible/
├── bootstrap.yml                 # 🛠️ First-time manual provisioning (setup + jenkins roles)
├── site.yml                      # 🚀 Jenkins-triggered deploy playbook (petclinic_app + monitoring)
├── inventories/
│   └── prod.ini                  # Inventory file
├── group_vars/
│   ├── all.yml                   # Non-secret variables (ports, versions, paths)
│   └── vault.yml                 # 🔐 Encrypted secrets (Ansible Vault)
├── roles/
│   ├── setup/                    # Sets up user, Java, Tomcat, and manager-gui config
│   ├── jenkins/                  # Installs Jenkins and sets JAVA_HOME via systemd
│   ├── petclinic_app/            # Converts JAR to WAR, deploys WAR to Tomcat
│   └── monitoring/               # Installs and configures Nagios
└── README.md
```

---

## 🧱 Phase 1 – Manual Server Bootstrap

Run this once to prepare the server:

```bash
ansible-playbook -i inventories/prod.ini bootstrap.yml --ask-vault-pass
```

This runs two roles:

### 🔧 Role: `setup`
- Creates `pet-clinic` user
- Installs Java 17 and Tomcat in the user’s home directory
- Adds Tomcat manager-gui role and credentials to `tomcat-users.xml`
- Changes Tomcat port to `9090`
- Creates a `systemd` unit for Tomcat

### 💻 Role: `jenkins`
- Installs Jenkins from the official RedHat repository
- Configures `JAVA_HOME` using a systemd override (`/etc/systemd/system/jenkins.service.d/java.conf`)
- Enables and starts Jenkins

---

## ⚙️ Phase 2 – Jenkins CI/CD Pipeline Setup

Once Jenkins is installed and running:

1. Access Jenkins in your browser:  
   `http://<host>:8080`

2. Copy the initial admin password:  
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

3. Complete the setup wizard and install recommended plugins

4. Create a **new pipeline job**, point it to the GitHub repo, and use the included `Jenkinsfile`

---

## 🔁 Jenkins Pipeline Workflow

Once configured, the Jenkins pipeline performs the following:

### ✅ Step 1: Clone the Spring Petclinic Repository
Pulled from GitHub on the `main` branch.

### ✅ Step 2: Convert JAR → WAR and Deploy
**Role: `petclinic_app`**
- Runs the `jar-to-war.sh` script (converts Spring Boot JAR to WAR)
- Updates `PetClinicApplication.java` for Tomcat compatibility
- Builds the WAR with Maven
- Copies the `.war` file into Tomcat’s `webapps` folder
- Restarts Tomcat
- Performs a health check on port 9090

### ✅ Step 3: Install Nagios and Set Up Monitoring
**Role: `monitoring`**
- Installs Nagios Core 4.4.6 from source
- Installs Nagios plugins
- Configures an HTTP check on `/spring-petclinic` via port 9090
- Starts and enables the `nagios` and `httpd` services

---

## 🛡️ Secrets Management

Sensitive credentials (Tomcat and Nagios users) are stored securely in `group_vars/vault.yml`, encrypted using Ansible Vault.

---

## ✅ Summary

| Step | What Happens |
|------|--------------|
| `bootstrap.yml` | Installs everything needed for Jenkins + Tomcat |
| `site.yml`      | Executed by Jenkins — builds, deploys, monitors the app |

