# DevSecOps for This Weather App

## 1. What is this project?

This project is a weather website made using React.

GitHub repository:

`https://github.com/arumullayaswanth/weather-app-devsecops.git`

It works like this:

- user types a city name
- app asks OpenWeather for weather data
- app shows the result on the screen

Later, we can:

- build the app
- scan it for security problems
- put it inside Docker
- deploy it to Kubernetes on EC2

So the short story is:

`Code -> Check -> Build -> Push -> Deploy`

## 2. What is DevSecOps?

DevSecOps is a simple idea:

- `Dev` means writing code
- `Sec` means security
- `Ops` means deployment and running the app

Meaning:

We do security checks in every step, not only at the end.

## 3. Pipeline flow

Your pipeline for this project is:

`Developer -> GitHub -> Jenkins -> Security Scans -> Docker Build -> Amazon ECR -> Update Kubernetes File -> Deploy to Kubernetes on EC2 -> OWASP ZAP Scan -> Falco Monitoring`

Very simple explanation:

1. You write code.
2. You push code to GitHub.
3. Jenkins starts automatically.
4. Jenkins checks code and security.
5. Jenkins builds Docker image.
6. Jenkins pushes image to Amazon ECR.
7. Jenkins updates Kubernetes deployment file with the new image version.
8. Kubernetes runs the new app.
9. OWASP ZAP checks the live website.
10. Falco watches runtime activity.

## 4. Tools and jobs

| Tool | Job | Easy meaning |
| --- | --- | --- |
| GitHub | source code | stores your project |
| Jenkins | CI/CD | runs pipeline automatically |
| SonarQube | SAST | checks code quality and risky code |
| Snyk | dependency scan | checks npm packages for vulnerabilities |
| Gitleaks | secrets scan | finds keys, passwords, tokens in code |
| Trivy | container scan | checks Docker image for vulnerabilities |
| Checkov | IaC scan | checks Kubernetes YAML for mistakes |
| Docker | build image | packs app into a container |
| Amazon ECR | image registry | stores Docker images |
| Kubernetes / k3s | deployment | runs the app |
| OWASP ZAP | DAST | tests the running app from outside |
| Falco | runtime security | watches the cluster after deployment |

## 5. Why each security check is used

### SonarQube

Checks the code itself.

Finds things like:

- bad code quality
- code smells
- risky coding patterns

### Snyk

Checks packages from `package.json`.

Finds things like:

- old vulnerable libraries

### Gitleaks

Checks if secrets are written in code.

Finds things like:

- API keys
- passwords
- tokens

### Trivy

Checks the Docker image.

Finds things like:

- vulnerable OS packages
- risky software in the image

### Checkov

Checks Kubernetes YAML files.

Finds things like:

- bad security settings
- weak deployment config

### OWASP ZAP

Checks the live website after deployment.

Finds things like:

- common web security issues
- missing security headers

### Falco

Watches the app after it is running.

Finds things like:

- suspicious processes
- strange runtime behavior

## 6. Important truth about this app

This app is a frontend app.

So even if we remove the API key from GitHub, the browser can still see the key when the frontend uses it.

That means:

- removing the key from code is good
- using Jenkins secret is better than hardcoding
- but it is still not a fully hidden backend secret

Real best solution later:

`React frontend -> backend API -> OpenWeather API`

That way the key stays on the server, not in the browser.

## 7. Files added for the pipeline

These files were added:

- [jenkins/Jenkinsfile](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/jenkins/Jenkinsfile#L1) = Jenkins pipeline
- [Dockerfile](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/Dockerfile#L1) = Docker build file
- [nginx.conf](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/nginx.conf#L1) = Nginx config
- [k8s/namespace.yaml](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/k8s/namespace.yaml#L1) = namespace
- [k8s/deployment.yaml](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/k8s/deployment.yaml#L1) = deployment
- [k8s/service.yaml](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/k8s/service.yaml#L1) = service
- [sonar-project.properties](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/sonar-project.properties#L1) = SonarQube config
- [.gitleaks.toml](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/.gitleaks.toml#L1) = Gitleaks config
- [.env.example](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/.env.example#L1) = sample env file

## 8. Jenkins pipeline stages

Jenkins runs these stages:

1. `Checkout`
   Downloads code from GitHub.
2. `Secrets Scan`
   Gitleaks checks if secrets are in the code.
3. `Install Dependencies`
   npm installs the packages.
4. `Test`
   Project tests run.
5. `Build Frontend`
   React production build is created.
6. `SAST`
   SonarQube scans the code.
7. `Dependency Scan`
   Snyk scans the packages.
8. `Container Build`
   Docker builds image.
9. `Container Scan`
   Trivy scans image.
10. `ECR Image Pushing`
   Docker image is pushed to Amazon ECR.
11. `IaC Security Scan`
   Checkov scans Kubernetes files.
12. `Update Deployment file`
   Jenkins updates image tag in deployment YAML and pushes it to GitHub.
13. `Deploy to Kubernetes`
   Kubernetes applies the YAML files.
14. `DAST`
   OWASP ZAP scans the running app.

## 9. Your EC2 plan

You said you want one EC2 instance.

That is okay for:

- demo project
- learning
- practice

This EC2 instance will run:

- Jenkins
- SonarQube
- Docker
- k3s
- scanners

### Good EC2 size

Use:

- `t3.large` minimum
- `t3.xlarge` better
- `30 GB` or more disk

## 10. AWS security group ports

Open these ports:

- `22` for SSH
- `8080` for Jenkins
- `9000` for SonarQube
- `30080` for your weather app

If you later use Ingress:

- `80`
- `443`

## 11. Install software on EC2

Use Ubuntu 22.04.

### Install Docker

```bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker ubuntu
```

Logout and login again after this.

### Install Java and Jenkins

```bash
sudo apt install -y fontconfig openjdk-17-jre
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
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
```

### Install these tools too

Install:

- `gitleaks`
- `trivy`
- `snyk`
- `checkov`
- `sonar-scanner`
- `aws cli`

## 12. Start SonarQube

Easy command:

```bash
docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community
```

Then open:

`http://EC2_PUBLIC_IP:9000`

## 13. Start Falco

Falco watches runtime activity.

Install with Helm:

```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm install falco falcosecurity/falco -n falco --create-namespace
```

## 14. Jenkins setup

### Install Jenkins plugins

Install:

- Pipeline
- Git
- Credentials Binding
- Docker Pipeline
- SonarQube Scanner

### Add Jenkins credentials

Create these:

- `openweather-api-key`
- `snyk-token`
- `my-git-pattoken`

For Amazon ECR:

- best way is attach IAM role to EC2
- or configure AWS credentials in Jenkins

### Add SonarQube server in Jenkins

Go to:

`Manage Jenkins -> System -> SonarQube servers`

Use this name:

`sonarqube`

### Create pipeline job

In Jenkins:

- create Pipeline job
- connect GitHub repo `https://github.com/arumullayaswanth/weather-app-devsecops.git`
- use script path `jenkins/Jenkinsfile`

### Add GitHub webhook

Use:

`http://EC2_PUBLIC_IP:8080/github-webhook/`

## 15. How deployment works

The app is deployed using:

- namespace YAML
- deployment YAML
- service YAML

Jenkins updates the image version in:

- [k8s/deployment.yaml](c:/Users/Yaswanth%20Reddy/OneDrive%20-%20vitap.ac.in/Desktop/weather-app/k8s/deployment.yaml#L1)

Then Kubernetes runs the latest image.

Your app will open at:

`http://EC2_PUBLIC_IP:30080`

## 16. First deployment commands

Run:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl -n weather-app get all
```

## 17. Things you must change

Before real use, change:

- `EC2_PUBLIC_IP` in `jenkins/Jenkinsfile`
- ECR values if account, region, or repo name changes
- GitHub repo name if your repo name is different

Also run:

```bash
npm install
```

Then commit the new `package-lock.json`.

Later you can use `npm ci` in Jenkins.

## 18. One warning

Jenkins updates the deployment file and pushes it back to GitHub.

This can trigger the pipeline again.

That can create a loop.

To reduce this:

- commit message uses `[skip ci]`
- or keep Kubernetes YAML in another repo
- or add Jenkins filters

Best real-world method:

Keep app code and deployment manifests in different repos.

## 19. Easy explanation for your project

You can explain your project like this:

"I built a React weather app. When I push code to GitHub, Jenkins starts automatically. Jenkins checks secrets, code quality, dependencies, Docker image security, and Kubernetes file security. Then Jenkins builds the Docker image, pushes it to Amazon ECR, updates the Kubernetes deployment file, deploys the app to k3s on EC2, runs OWASP ZAP on the live app, and uses Falco for runtime monitoring."
