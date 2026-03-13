

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
