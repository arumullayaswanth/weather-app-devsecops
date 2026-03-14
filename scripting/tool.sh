#!/bin/bash
set -euo pipefail

# Show simple step names on screen
log() {
  echo
  echo "==> $1"
}

# Run this file only with sudo or as root
if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root: sudo bash tool.sh"
  exit 1
fi

# These are folder paths used in this script
JENKINS_HOME="/var/lib/jenkins"
CHECKOV_VENV="/opt/checkov-venv"
AWS_CLI_ZIP="/tmp/awscliv2.zip"
AWS_CLI_DIR="/tmp/aws"

# Step 1: update the server
log "Updating system packages"
dnf update -y

# Step 2: install basic tools
log "Installing base packages"
dnf install -y \
  git \
  docker \
  java-17-amazon-corretto \
  python3 \
  python3-pip \
  python3-virtualenv \
  unzip \
  tar \
  curl \
  wget

# Step 3: start Docker and enable it after reboot
log "Enabling and starting Docker"
systemctl enable docker
systemctl start docker

# Step 4: give Docker access to users
log "Adding ec2-user and jenkins to docker group when present"
id -u ec2-user >/dev/null 2>&1 && usermod -aG docker ec2-user || true

# Step 5: install Jenkins
log "Installing Jenkins"
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y jenkins

# Step 6: start Jenkins and give Jenkins Docker access
log "Enabling and starting Jenkins"
systemctl enable jenkins
systemctl start jenkins
usermod -aG docker jenkins
systemctl restart docker
systemctl restart jenkins

# Step 7: install Node.js and Snyk
log "Installing Node.js and Snyk CLI"
dnf install -y nodejs
npm install -g snyk

# Step 8: install AWS CLI
log "Installing AWS CLI v2"
rm -f "$AWS_CLI_ZIP"
rm -rf "$AWS_CLI_DIR"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$AWS_CLI_ZIP"
unzip -q "$AWS_CLI_ZIP" -d /tmp
/tmp/aws/install --update
ln -sf /usr/local/bin/aws /usr/bin/aws
rm -f "$AWS_CLI_ZIP"
rm -rf "$AWS_CLI_DIR"

# Step 9: install Gitleaks
log "Installing gitleaks"
GITLEAKS_VERSION="$(curl -fsSL https://api.github.com/repos/gitleaks/gitleaks/releases/latest | grep tag_name | cut -d '"' -f4 | sed 's/v//')"
wget -q "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" -O /tmp/gitleaks.tar.gz
tar -xzf /tmp/gitleaks.tar.gz -C /tmp
install -m 0755 /tmp/gitleaks /usr/local/bin/gitleaks
rm -f /tmp/gitleaks /tmp/gitleaks.tar.gz

# Step 10: install Trivy
log "Installing Trivy"
cat >/etc/yum.repos.d/trivy.repo <<'EOF'
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$basearch/
enabled=1
gpgcheck=0
EOF
dnf install -y trivy

# Step 11: install Checkov
log "Installing Checkov in a shared virtual environment"
python3 -m venv "$CHECKOV_VENV"
"$CHECKOV_VENV/bin/pip" install --upgrade pip
"$CHECKOV_VENV/bin/pip" install checkov
ln -sf "$CHECKOV_VENV/bin/checkov" /usr/local/bin/checkov

# Step 12: install K3s Kubernetes
log "Installing K3s"
curl -sfL https://get.k3s.io | sh -

# Step 13: give Kubernetes access to Jenkins
log "Configuring kubeconfig for Jenkins"
mkdir -p "$JENKINS_HOME/.kube"
cp /etc/rancher/k3s/k3s.yaml "$JENKINS_HOME/.kube/config"
chown -R jenkins:jenkins "$JENKINS_HOME/.kube"
chmod 600 "$JENKINS_HOME/.kube/config"

# Step 14: install Helm
log "Installing Helm"
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Step 15: install Falco
log "Installing Falco with Helm"
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm upgrade --install falco falcosecurity/falco -n falco --create-namespace

# Step 16: start SonarQube in Docker
log "Starting SonarQube container"
if docker ps -a --format '{{.Names}}' | grep -qx sonarqube; then
  docker start sonarqube || true
  docker update --restart unless-stopped sonarqube
else
  docker run -d \
    --name sonarqube \
    --restart unless-stopped \
    -p 9000:9000 \
    sonarqube:lts-community
fi

# Step 17: check if tools are working
log "Basic verification"
docker --version
java -version
systemctl status jenkins --no-pager || true
aws --version
snyk --version
gitleaks version
trivy --version
checkov --version
kubectl get nodes || true
sudo -u jenkins -H bash -lc 'docker version >/dev/null 2>&1 && echo "jenkins Docker access: OK" || echo "jenkins Docker access: FAILED"'
sudo -u jenkins -H bash -lc 'kubectl get nodes >/dev/null 2>&1 && echo "jenkins kubectl access: OK" || echo "jenkins kubectl access: FAILED"'

# Step 18: show Jenkins first login password
log "Jenkins initial admin password"
cat /var/lib/jenkins/secrets/initialAdminPassword || true

log "Bootstrap completed"
echo "Re-login may be needed for ec2-user Docker group changes."
