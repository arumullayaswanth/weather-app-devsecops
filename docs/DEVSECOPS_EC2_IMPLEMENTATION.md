

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
Below is the **Amazon Linux 2023 version of your setup**.
Amazon Linux uses **`dnf` instead of `apt`**, and the **default user is `ec2-user`** (not `ubuntu`).

---

# 5️⃣ AWS Setup

Create **EC2 Instance**

Recommended:

| Setting       | Value                 |
| ------------- | --------------------- |
| Instance Type | t3.large              |
| OS            | **Amazon Linux 2023** |
| Storage       | 30 GB                 |

---

# 6️⃣ Security Group Ports

Open these ports in **Inbound Rules**:

| Port  | Purpose     |
| ----- | ----------- |
| 22    | SSH         |
| 8080  | Jenkins     |
| 9000  | SonarQube   |
| 30080 | Weather App |

---

# 7️⃣ Connect to EC2

```bash
ssh -i key.pem ec2-user@EC2_PUBLIC_IP
```

---

# 8️⃣ Update System

```bash
sudo dnf update -y
```

---

# 9️⃣ Install Docker

Install Docker:

```bash
sudo dnf install docker -y
```

Start Docker:

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

Add user to Docker group:

```bash
sudo usermod -aG docker ec2-user
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

# 🔟 Install Java (Required for Jenkins)

Amazon Linux provides **Amazon Corretto**.

Install Java 17:

```bash
sudo dnf install java-17-amazon-corretto -y
```

Check version:

```bash
java -version
```

Expected output:

```
openjdk version "17.x.x"
```

---

# 11️⃣ Install Jenkins

Add Jenkins repository:

```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/redhat-stable/jenkins.repo
```

Import Jenkins key:

```bash
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
```

Install Jenkins:

```bash
sudo dnf install jenkins -y
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

# 12️⃣ Access Jenkins

Open browser:

```
http://EC2_PUBLIC_IP:8080
```

Example:

```
http://54.xx.xx.xx:8080
```

---

# Unlock Jenkins

Get initial password:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Paste into **Unlock Jenkins page**.

---

# Install Plugins

Choose:

```
Install Suggested Plugins
```

---

# Create Admin User

Provide:

* Username
* Password
* Email

Click **Save and Continue**.

---

# 13️⃣ Install Kubernetes (k3s)

Install k3s:

```bash
curl -sfL https://get.k3s.io | sh -
```

Check cluster:

```bash
sudo kubectl get nodes
```

Expected:

```
Ready
```

---

# 14️⃣ Give Jenkins Kubernetes Access

```bash
sudo mkdir -p /var/lib/jenkins/.kube
```

```bash
sudo cp /etc/rancher/k3s/k3s.yaml \
/var/lib/jenkins/.kube/config
```

```bash
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
```

---

# 15️⃣ Install Security Tools

### Install Gitleaks

```bash
wget https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks-linux-amd64
chmod +x gitleaks-linux-amd64
sudo mv gitleaks-linux-amd64 /usr/local/bin/gitleaks
```

---

### Install Trivy

```bash
sudo dnf install -y trivy
```

---

### Install Checkov

Install pip first:

```bash
sudo dnf install python3-pip -y
```

Install Checkov:

```bash
pip3 install checkov
```

---

### Install Snyk

Install NodeJS:

```bash
sudo dnf install nodejs -y
```

Install Snyk:

```bash
npm install -g snyk
```

---

### Install AWS CLI

```bash
sudo dnf install awscli -y
```

---

# 16️⃣ Start SonarQube

Run container:

```bash
docker run -d \
--name sonarqube \
-p 9000:9000 \
sonarqube:lts-community
```

---

# Open SonarQube

```
http://EC2_PUBLIC_IP:9000
```

Default login:

```
admin
admin
```

Generate **Sonar Token** and store it in **Jenkins credentials**.

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
