# DevSecOps Pipeline for This Weather App

## 1. Current Application Architecture

This repository is a React single-page application that:

- calls the OpenWeather API directly from the browser
- builds into static files with `react-scripts`
- can be served from Nginx inside a Docker container
- can be deployed to Kubernetes on a single EC2 instance running `k3s`

Current code observations from this repo:

- the original app hardcoded the OpenWeather API key in `src/App.js`
- the project had no Dockerfile, no Kubernetes manifests, and no working Jenkins pipeline definition
- the app imports `react-awesome-button`, `react-leaflet`, and `leaflet`, but those packages were missing from `package.json`
- there are no unit tests yet, so the pipeline is prepared for tests but will currently pass with `--passWithNoTests`

## 2. Real Modern DevSecOps Architecture

Your simplified flow is correct, but the real pipeline used in modern DevSecOps is usually this:

`Developer -> GitHub/GitLab -> CI Orchestrator -> Secrets/SAST/SCA/IaC scans -> Container build -> Container scan -> Image registry -> Kubernetes deploy -> DAST -> Runtime security and monitoring`

For your project on one EC2 instance, the practical architecture is:

`Developer push -> GitHub webhook -> Jenkins on EC2 -> SonarQube/Snyk/Gitleaks/Checkov/Trivy -> Docker image -> Amazon ECR -> update Kubernetes YAML in Git -> k3s on same EC2 -> OWASP ZAP baseline scan -> Falco runtime monitoring`

This is the security purpose of each category:

| Category | Tool | What it checks |
| --- | --- | --- |
| SAST | SonarQube | code quality issues, bugs, maintainability, insecure patterns |
| Dependency Scan | Snyk | vulnerable npm packages and transitive dependencies |
| Secrets Scan | Gitleaks | hardcoded API keys, tokens, passwords |
| Container Scan | Trivy | OS and package vulnerabilities inside the image |
| IaC Security | Checkov | insecure Kubernetes YAML and infrastructure definitions |
| DAST | OWASP ZAP | issues visible from the running application surface |
| Runtime Security | Falco | suspicious behavior after deployment inside Kubernetes |

## 3. Important Security Reality for This App

This repo is a frontend-only app. That means the weather API key is not a true backend secret. Even if you pass it through Jenkins and Docker build arguments, the key is still delivered to the browser and can be seen by users.

So there are two levels of improvement:

1. Better than current state:
   remove the key from Git and inject it during CI build using Jenkins credentials
2. Real secret protection:
   move the OpenWeather call to a backend service or API gateway and let the frontend call that backend instead

For your current repo, this implementation uses level 1 because it matches the existing architecture with minimal code change.

## 4. Files Added for This Pipeline

- `jenkins/Jenkinsfile` -> full Jenkins pipeline
- `Dockerfile` -> multi-stage React build and Nginx runtime
- `nginx.conf` -> SPA routing support
- `k8s/namespace.yaml` -> namespace
- `k8s/deployment.yaml` -> Kubernetes deployment
- `k8s/service.yaml` -> NodePort service
- `sonar-project.properties` -> SonarQube scan config
- `.gitleaks.toml` -> Gitleaks config entry
- `.env.example` -> local environment variable example

## 5. End-to-End Pipeline Flow for This Repo

When a developer pushes code:

1. GitHub triggers Jenkins through webhook.
2. Jenkins checks out the repository.
3. Gitleaks scans the source for exposed secrets.
4. `npm install` installs dependencies.
5. Jest test stage runs.
6. `npm run build` creates the production React build.
7. SonarQube performs SAST and quality analysis.
8. Snyk performs dependency scanning.
9. Docker builds the application image.
10. Trivy scans the built image.
11. Checkov scans Kubernetes manifests in `k8s/`.
12. Jenkins pushes the image to Amazon ECR.
13. Jenkins updates `k8s/deployment.yaml` with the new image tag and pushes that change to GitHub.
14. Jenkins deploys the manifests to Kubernetes on the EC2 instance.
15. OWASP ZAP runs a baseline DAST scan against the deployed app.
16. Falco monitors runtime events after deployment.

## 6. EC2 Deployment Plan

### Recommended EC2 sizing

If Jenkins, SonarQube, Docker, and k3s all run on one instance, use at least:

- `t3.large` minimum
- `t3.xlarge` preferred for smoother SonarQube and Jenkins builds
- 30 to 50 GB EBS

### Security group ports

Open only what you need:

- `22` for SSH
- `8080` for Jenkins
- `9000` for SonarQube
- `30080` for the weather app NodePort
- optionally `80/443` if later using Ingress or reverse proxy

## 7. Install the Stack on EC2

Use Ubuntu 22.04 on EC2.

### Install Docker

```bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker ubuntu
```

Log out and log in again after adding the user to the Docker group.

### Install Java and Jenkins

```bash
sudo apt install -y fontconfig openjdk-17-jre
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install -y jenkins
sudo systemctl enable --now jenkins
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Install kubectl and k3s

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
curl -sfL https://get.k3s.io | sh -
sudo kubectl get nodes
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /var/lib/jenkins/.kube/config
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
sudo sed -i 's/127.0.0.1/localhost/g' /var/lib/jenkins/.kube/config
```

### Install scanners

Install these CLIs on the EC2 instance so Jenkins can use them:

- `gitleaks`
- `trivy`
- `snyk`
- `checkov`
- `sonar-scanner`

### Run SonarQube

The simplest approach is Docker:

```bash
docker run -d --name sonarqube \
  -p 9000:9000 \
  sonarqube:lts-community
```

Then open `http://EC2_PUBLIC_IP:9000`, create the project, and generate a token for Jenkins.

### Install Falco

Falco is runtime security and is not part of the build itself. Install it into k3s:

```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm install falco falcosecurity/falco -n falco --create-namespace
```

## 8. Configure Jenkins

### Required Jenkins plugins

- Pipeline
- Git
- Credentials Binding
- Docker Pipeline
- SonarQube Scanner

### Jenkins credentials to create

Create these credentials in Jenkins:

- `snyk-token` -> Snyk API token
- `openweather-api-key` -> OpenWeather API key
- `my-git-pattoken` -> GitHub personal access token for pushing manifest updates

For ECR authentication, use one of these:

- attach an IAM role to the EC2 instance that allows ECR login and push
- or configure Jenkins/AWS CLI credentials on the instance

Also configure SonarQube in:

- `Manage Jenkins -> System -> SonarQube servers`

Name it exactly:

- `sonarqube`

### Jenkins pipeline job

Create a Pipeline job and point it to:

- repository: your GitHub repo
- script path: `jenkins/Jenkinsfile`

Add a GitHub webhook:

- `http://EC2_PUBLIC_IP:8080/github-webhook/`

## 9. How Kubernetes Deployment Works Here

This repo deploys as:

- one namespace: `weather-app`
- one deployment: `weather-app`
- one NodePort service: `30080`

The app becomes reachable at:

- `http://EC2_PUBLIC_IP:30080`

That same URL is used in the Jenkins `APP_URL` variable for OWASP ZAP scanning.

## 10. Commands You Will Run on EC2 for First Deployment

After cloning the repo on the EC2 instance:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl -n weather-app get all
```

If Jenkins already pushed a new image, the pipeline updates it with:

```bash
kubectl -n weather-app set image deployment/weather-app \
  weather-app=docker.io/your-dockerhub-username/weather-app:BUILD_NUMBER
kubectl -n weather-app rollout status deployment/weather-app
```

## 11. What You Must Change Before Running This for Real

Update these placeholders:

- `EC2_PUBLIC_IP` in `jenkins/Jenkinsfile`

If your ECR repository name or AWS account ID differs, also update:

- `ECR_REGISTRY` in `jenkins/Jenkinsfile`
- `ECR_REPOSITORY` in `jenkins/Jenkinsfile`
- the image value in `k8s/deployment.yaml`

Install dependencies and regenerate the lock file once:

```bash
npm install
```

Then commit the updated `package-lock.json`. After that, you can improve the pipeline by replacing `npm install` with `npm ci`.

## 12. Recommended Next Improvement

If you want this to look like a stronger real-world DevSecOps project in interviews or demos, add a small backend service:

- frontend calls backend
- backend calls OpenWeather
- API key stays only on the server
- Kubernetes secret becomes meaningful

That changes the design from "better repo hygiene" to "real secret protection".
