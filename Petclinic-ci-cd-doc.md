# Spring Petclinic – CI/CD & Monitoring Stack

> **Status:** _Draft v0.1 – please review & comment_

---

## 1  High‑Level Overview

This repo delivers a fully‑automated path—from source to running application—for the **Spring Petclinic** demo.  It covers:

* **Build:** Jenkins converts the default JAR project into a WAR and packages it with Maven.
* **Deploy:** Ansible provisions AlmaLinux hosts with Java 17, Tomcat 10, Jenkins, and Nagios, then deploys the WAR to Tomcat listening on **:9090**.
* **Operate:** Nagios monitors Tomcat’s HTTP endpoint and raises alerts via check *http*.

```mermaid
flowchart TD
    %% Provisioning phase
    Dev((Trigger)) --> Control["Ansible Control Node"]
    Control -->|playbook1.yml\n(provision)| Target["Petclinic Host\n(AlmaLinux)"]

    %% CI/CD phase
    Source[(GitHub\nspring-petclinic)] --> Jenkins[Jenkins]
    Jenkins -->|jar-to-war.sh + Maven| War["spring-petclinic.war"]
    Jenkins -->|deploy.yml| Target
    Jenkins -->|sanity.yml| Target
    Jenkins -->|nagios-playbook.yml| Target
    Target -->|port 9090| App["Petclinic App"]
    Jenkins -.->|artifacts| War
    War -->|copy| Target

    %% Monitoring
    Nagios[Nagios] -.->|check_http 9090| Target
```

<!-- Exported PNG for static renderers -->
![Architecture Diagram](petclinic-architecture.png)


---

## 2  Host & Inventory
```ini
[petclinic]
192.168.100.116 ansible_user=server ansible_ssh_private_key_file=~/.ssh/id_rsa
```
* Control node (Ansible) reachable at **192.168.100.117** (SSH user **shekshek**)—Jenkins connects here to execute playbooks.

---

## 3  Component Versions (Pinned)
| Component | Version | Variable            |
|-----------|---------|---------------------|
| Java JDK  | 17.0.12 | `java_version`      |
| Tomcat    | 10.1.41 | `tomcat_version`    |
| Maven     | distro pkg | —                 |
| Jenkins   | latest LTS from `jenkins.repo` (pin once known) | `jenkins_version` (optional) |
| Nagios    | 4.4.6   | `nagios_version`    |
| Petclinic | 3.4.0‑SNAPSHOT | derived from build |

All variables live in `group_vars/all.yml` and are referenced throughout roles; changing a version requires editing one file only.

---

## 4  Directory Layout (Proposed)
```
ansible/
├── inventories/
│   └── prod.ini
├── group_vars/
│   └── all.yml
├── roles/
│   ├── java/
│   ├── tomcat/
│   ├── jenkins/
│   ├── petclinic_app/
│   └── monitoring/
└── site.yml
```

* `site.yml` includes the role sequence; Jenkins invokes `ansible-playbook -i inventories/prod.ini site.yml`.
* Secrets (Tomcat manager + Nagios admin) are encrypted via **Ansible Vault** under `vault.yml`.

---

## 5  Role Highlights
### 5.1  java
* Uses `ansible.builtin.get_url` + `ansible.builtin.unarchive` to download/extract Oracle JDK.
* Exports `JAVA_HOME` through `/etc/profile.d/java.sh` template for system‑wide availability.

### 5.2  tomcat
* Downloads Tomcat, sets permissions, creates a **systemd unit** `petclinic-tomcat.service` (see Appendix A).
* Templated `server.xml` and `tomcat-users.xml` ensure idempotent port & credential management.
* Handler restarts via `systemd`—replacing ad‑hoc shell commands.

### 5.3  jenkins
* Installs Jenkins from official repo; version can be pinned via `jenkins_version` variable.

### 5.4  petclinic_app
* Copies `spring-petclinic.war` from Jenkins workspace (or artefact repo once integrated).
* Notifies Tomcat restart handler.
* Uses `ansible.builtin.wait_for` and `uri` to perform post‑deploy health check.

### 5.5  monitoring
* Compiles Nagios Core 4.4.6 and plugins 2.4.6.
* Registers an HTTP check on **/spring-petclinic** port `{{ petclinic_port }}`.
* Future: tie into corporate SMTP for alerts.

---

## 6  CI Pipeline (Jenkinsfile)
```groovy
pipeline {
  agent any
  environment {
    ANSIBLE_HOST = "192.168.100.117"
    ANSIBLE_USER = "shekshek"
    SSH_KEY_ID   = "jenkins-ssh"
  }
  stages {
    stage('Checkout')    { steps { git url: 'https://github.com/spring-projects/spring-petclinic.git' } }
    stage('Convert to WAR') { steps { sh 'scripts/jar-to-war.sh' } }
    stage('Build')        { steps { sh './mvnw clean package' } }
    stage('Deploy')       { steps { ansiblePlay('deploy')   } }
    stage('Sanity Check') { steps { ansiblePlay('sanity')   } }
    stage('Configure Monitoring') { steps { ansiblePlay('nagios') } }
  }
  // ansiblePlay() defined in a shared library or inline shell, reusing your sshagent snippet
}
```

---

## 7  Secrets Management
| Secret | Location | Accessed by |
|--------|----------|-------------|
| Tomcat manager user/password | **Vault**: `group_vars/all/vault.yml` | `roles/tomcat` template |
| Nagios UI user/password      | **Vault**: `group_vars/all/vault.yml` | `roles/monitoring` tasks |
| Jenkins SSH key              | Jenkins credentials (`jenkins-ssh`) | Jenkins pipeline |

---

## 8  Health Check & Monitoring
* **Ansible Sanity Playbook:** waits for port 9090, then `GET /spring-petclinic` expecting status 200.
* **Nagios:** `check_http -p 9090 -u /spring-petclinic`.  Alerts if >5 × consecutive failures.

---

## 9  Rollback (Future‑Work)
Current approach is *in‑place* deploy.  If required, add:

* **Backup task** in `petclinic_app` role to save prior WAR with timestamp.
* **Handler** to restore previous WAR & restart Tomcat when `--tags rollback` is invoked.
* Optional blue‑green pattern using two Tomcat instances on different ports + HAProxy.

---

## 10  Troubleshooting Tips
| Symptom | Where to Look |
|---------|---------------|
| Jenkins build fails | Pipeline log – mvn output, verify POM was patched to `packaging: war`. |
| Tomcat not starting | `/var/log/messages`, `journalctl -u petclinic-tomcat`, check `JAVA_HOME`. |
| Health check fails | Ensure firewall open, WAR deployed as `spring-petclinic.war`, browse http://host:9090. |
| Nagios not loading | `httpd` & `nagios` services, `/usr/local/nagios/var/nagios.log`. |

---

## Appendix A  Systemd Unit for Tomcat
```ini
[Unit]
Description=Petclinic Tomcat
After=network.target

[Service]
Type=forking
User=pet-clinic
Group=pet-clinic
Environment="JAVA_HOME=/home/pet-clinic/java/jdk-17.0.12"
Environment="CATALINA_PID=/home/pet-clinic/tomcat/apache-tomcat-10.1.41/temp/tomcat.pid"
ExecStart=/home/pet-clinic/tomcat/apache-tomcat-10.1.41/bin/startup.sh
ExecStop=/home/pet-clinic/tomcat/apache-tomcat-10.1.41/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
Add this via `template:` task and enable with `systemd` module.

---

## Appendix B  group_vars/all.yml (excerpt)
```yaml
# Versions
java_major: 17
java_version: "17.0.12"
tomcat_version: "10.1.41"
petclinic_port: 9090
nagios_version: "4.4.6"

# Ports
jenkins_http_port: 8080

# Vault‑encrypted secrets (file encrypted with ansible-vault)
# tomcat_mgr_user: "tomcat"
# tomcat_mgr_pass: "<password>"
# nagios_admin_user: "nagiosadmin"
# nagios_admin_pass: "<password>"
```

---

> **Next Steps**
> 1. Review this draft and leave comments.
> 2. Confirm variables, especially component versions you’d like pinned.
> 3. I’ll proceed to refactor your playbooks into roles and supply a rendered architecture diagram (PNG) once you’re happy with the structure.
