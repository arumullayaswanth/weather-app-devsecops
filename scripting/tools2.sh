sudo mkdir -p /var/lib/jenkins/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /var/lib/jenkins/.kube/config
sudo sed -i 's/127.0.0.1/172.31.32.195/g' /var/lib/jenkins/.kube/config
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
sudo chmod 600 /var/lib/jenkins/.kube/config
sudo su - jenkins -s /bin/bash
kubectl --kubeconfig=/var/lib/jenkins/.kube/config get nodes

#Use your current private IP there:
#172.31.32.195