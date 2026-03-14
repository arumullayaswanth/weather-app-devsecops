

# DevSecOps Weather App – Complete Guide

## 1. Project Introduction

This project is a **React Weather Application**.

GitHub Repository:

```
https://github.com/arumullayaswanth/weather-app-devsecops.git
```

What the application does:

1. User enters a city name
2. Application calls the OpenWeather API
3. API returns weather data
4. Weather data is shown on the screen

Example:

```
User → React App → OpenWeather API → Weather Data → Browser
```

But the main goal of this project is **DevSecOps automation**.

Meaning:

```
Code → Security → Build → Deploy → Monitor
```

Everything is automated using **Jenkins**.

---

# 2. What is DevSecOps?

DevSecOps means:

| Word | Meaning      |
| ---- | ------------ |
| Dev  | Writing code |
| Sec  | Security     |
| Ops  | Deployment   |

Instead of adding security at the end, we add security **at every step**.

Example pipeline:

```
Developer
   ↓
GitHub
   ↓
Jenkins Pipeline
   ↓
Security Scans
   ↓
Build Docker Image
   ↓
Push Image to ECR
   ↓
Deploy to Kubernetes
   ↓
Security Testing
```

---

# 3. Architecture of the Project

This project uses **only ONE EC2 instance**.

Architecture:

```
Developer
   │
   ▼
GitHub Repository
   │
   ▼
Jenkins CI/CD
   │
   ├ Secrets Scan (Gitleaks)
   ├ Code Scan (SonarQube)
   ├ Dependency Scan (Snyk)
   ├ Container Scan (Trivy)
   ├ Kubernetes Scan (Checkov)
   │
   ▼
Docker Build
   │
   ▼
Amazon ECR
   │
   ▼
Kubernetes (k3s)
   │
   ▼
Weather App Running
   │
   ▼
OWASP ZAP Security Test
   │
   ▼
Falco Runtime Monitoring
```

Everything runs on **one server**.

---

# 4. Tools Used

| Tool                              | Purpose                           |
| --------------------------------- | --------------------------------- |
| GitHub                            | Stores project code               |
| Jenkins                           | CI/CD pipeline automation         |
| SonarQube                         | Static code security scanning     |
| Snyk                              | Dependency vulnerability scanning |
| Gitleaks                          | Secret detection                  |
| Docker                            | Containerization                  |
| Trivy                             | Container vulnerability scan      |
| Amazon Elastic Container Registry | Docker image registry             |
| Kubernetes (k3s)                  | Container orchestration           |
| Checkov                           | Kubernetes security scan          |
| OWASP ZAP                         | Dynamic web security testing      |
| Falco                             | Runtime security monitoring       |

---

# 5. AWS Setup

Create **one EC2 instance**.

Recommended configuration:

```
Instance type: t3.large
Operating System: Ubuntu 22.04
Storage: 30 GB
```

---

# 6. Security Group Ports

Open these ports:

| Port  | Purpose     |
| ----- | ----------- |
| 22    | SSH         |
| 8080  | Jenkins     |
| 9000  | SonarQube   |
| 30080 | Weather App |

---

# 7. Connect to EC2

SSH into the server.

```
ssh -i key.pem ubuntu@EC2_PUBLIC_IP
```

---

# 8. Update System

```
sudo apt update
sudo apt upgrade -y
```

---
Here is your **updated and corrected documentation** based on what actually worked on **Ubuntu 24.04 / EC2** (since the Jenkins repo method caused the GPG key error). I kept your structure but fixed the Jenkins installation method.

---

# 9. Install Docker

Install Docker:

```bash
sudo apt update
sudo apt install docker.io -y
```

Start Docker:

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

Add user to Docker group:

```bash
sudo usermod -aG docker ubuntu
```

Apply group changes:

```bash
newgrp docker
```

Verify Docker:

```bash
docker --version
```

---

# 10. Install Java

Jenkins requires **Java 17**.

Install Java:

```bash
sudo apt install openjdk-17-jdk -y
```

Check Java version:

```bash
java -version
```

Expected output should show **OpenJDK 17**.

---

# 11. Install Jenkins

Due to repository key issues on **Ubuntu 24.04**, install Jenkins using the official `.deb` package.

Download Jenkins package:

```bash
wget https://pkg.jenkins.io/debian-stable/binary/jenkins_2.452.3_all.deb
```

Install Jenkins:

```bash
sudo dpkg -i jenkins_2.452.3_all.deb
```

If dependency errors appear, fix them:

```bash
sudo apt -f install -y
```

Start Jenkins:

```bash
sudo systemctl enable jenkins
sudo systemctl start jenkins
```

Check Jenkins status:

```bash
sudo systemctl status jenkins
```

---

# 12. Access and Unlock Jenkins

## Access Jenkins

Open Jenkins in your browser:

```
http://EC2_PUBLIC_IP:8080
```

Make sure your **EC2 Security Group allows port 8080**.

Example inbound rule:

| Type       | Protocol | Port | Source    |
| ---------- | -------- | ---- | --------- |
| Custom TCP | TCP      | 8080 | 0.0.0.0/0 |

---

## Unlock Jenkins

Retrieve the Jenkins initial admin password:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Copy the password and paste it into the **Unlock Jenkins** page in the browser.

---

## Install Plugins

On the **Customize Jenkins** page, choose:

```
Install suggested plugins
```

Jenkins will automatically install the commonly used plugins required for most CI/CD pipelines.


## Create Admin User

After the plugins are installed, create your administrator account:

* **Username**
* **Password**
* **Email address**

Click **Save and Continue**.

---

# 13. Install Kubernetes (k3s)

```
curl -sfL https://get.k3s.io | sh -
```

Check cluster:

```
sudo kubectl get nodes
```

---

# 14. Give Jenkins Kubernetes Access

```
sudo mkdir -p /var/lib/jenkins/.kube
```

```
sudo cp /etc/rancher/k3s/k3s.yaml \
/var/lib/jenkins/.kube/config
```

```
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
```

---

# 15. Install Security Tools

Install Gitleaks:

```
wget https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks-linux-amd64
chmod +x gitleaks-linux-amd64
sudo mv gitleaks-linux-amd64 /usr/local/bin/gitleaks
```

---

Install Trivy:

```
sudo apt install trivy -y
```

---

Install Checkov:

```
pip install checkov
```

---

Install Snyk:

```
npm install -g snyk
```

---

Install AWS CLI:

```
sudo apt install awscli -y
```

---

# 16. Start SonarQube

Run:

```
docker run -d \
--name sonarqube \
-p 9000:9000 \
sonarqube:lts-community
```

Open:

```
http://EC2_IP:9000
```

Default login:

```
admin
admin
```

Generate **Sonar token** and store it in Jenkins.

---

# 17. Create Amazon ECR Repository

Open AWS console.

Create repository:

```
weather-app
```

Example:

```
242201296943.dkr.ecr.us-east-1.amazonaws.com/weather-app
```

---

# 18. Jenkins Credentials

Add credentials:

| ID                  | Purpose             |
| ------------------- | ------------------- |
| openweather-api-key | OpenWeather API key |
| snyk-token          | Snyk API token      |
| my-git-pattoken     | GitHub token        |
| sonar-token         | SonarQube token     |

---

# 19. Jenkins Pipeline Job

Create job:

```
New Item → Pipeline
```

Name:

```
weather-app-pipeline
```

Choose:

```
Pipeline script from SCM
```

Repository:

```
https://github.com/arumullayaswanth/weather-app-devsecops.git
```

Script path:

```
jenkins/Jenkinsfile
```

---

# 20. Pipeline Execution

When Jenkins runs, it performs:

```
1 Checkout Code
2 Secrets Scan (Gitleaks)
3 Install Dependencies
4 Run Tests
5 Build React App
6 SAST Scan (SonarQube)
7 Dependency Scan (Snyk)
8 Build Docker Image
9 Container Scan (Trivy)
10 Push Image to Amazon ECR
11 Kubernetes YAML Scan (Checkov)
12 Update Deployment YAML
13 Deploy to Kubernetes
14 Run OWASP ZAP Scan
```

---

# 21. Deploy Application

Run once:

```
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Check pods:

```
kubectl get pods -n weather-app
```

---

# 22. Access the Application

Open browser:

```
http://EC2_PUBLIC_IP:30080
```

Weather app will appear.

---

# 23. OWASP ZAP Security Scan

Pipeline automatically runs **OWASP ZAP**.

It checks for:

* XSS
* insecure headers
* vulnerabilities

Report stored in Jenkins.

---

# 24. Runtime Security

Install **Falco**:

```
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm install falco falcosecurity/falco -n falco --create-namespace
```

Falco monitors suspicious activity.

---

# 25. Final Pipeline

Final DevSecOps workflow:

```
GitHub
   ↓
Jenkins
   ↓
Security Scans
   ↓
Docker Build
   ↓
Push to Amazon ECR
   ↓
Deploy to Kubernetes
   ↓
OWASP ZAP Scan
   ↓
Falco Monitoring
```

Application URL:

```
http://EC2_PUBLIC_IP:30080
```

---
