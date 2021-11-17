**Setup your own Kubernetes cluster in AWS with Terraform**
1. Create & configure one ubuntu 18.04 EC2 instance with a public IP to be used as the k8s control node
2. Create & configure two ubuntu 18.04 EC2 instances in a private subnet to be used as k8s worker nodes
3. Init k8s cluster
4. Join worker nodes to k8s cluster
5. Verify status of cluster


# Local Setup
## Download & unzip Terraform
```bash
wget https://releases.hashicorp.com/terraform/1.0.11/terraform_1.0.11_linux_amd64.zip
unzip terraform_1.0.11_linux_amd64.zip -d /usr/bin/
```
---
## Download, unzip, & install AWS CLI
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
## **Optional:** Enable auto complete & cli auto-prompt
```bash
echo "complete -C '/usr/local/bin/aws_completer' aws" >> ~/.bashrc
echo "export AWS_CLI_AUTO_PROMPT=on-partial" >> ~/.bashrc
. ~/.bashrc
```
## Configure AWS CLI
```bash
aws configure
```
**AWS IAM user with admin permissions needed, Terraform will use this user to build**


**Command will prompt you for access key, secret key, default region, & default output**

---
## Add your external IP address to code for inbound ssh security group
```
On line 35 in ec2.tf replace ##.##.##.## with your external IP
Leave the /32 at the end of the IP address
You can google 'what is my ip' to find your public IP address
```
## Create default rsa ssh keys (if you don't already have some)
```bash
ssh-keygen -t rsa
```
**At prompts just press enter for defaults**

---
---
---
# Deploy & verify AWS infrastructure creation
## Deploy AWS infrastructure with Terraform
Run while in directory with terraform code
```bash
terraform init
terraform apply
```
Apply command will output a plan showing what will be created


At prompt enter yes to build

---
## Find IP addresses to nodes
```bash
aws ec2 describe-instances --filters file://pub-filter.json --query 'Reservations[*].Instances[*].{"Copy this public EC2 instance IP":PublicIpAddress}'
```
Command above will output a public IP address, this is for the k8s control node

Save this IP to connect to k8s control node later
```bash
aws ec2 describe-instances --filters file://prv-filter.json --query 'Reservations[*].Instances[*].{"Copy this private EC2 instance IP":PrivateIpAddress}'
```
Command above will output two private IP addresses, this is for the k8s worker nodes

You can only ssh to worker nodes from k8s control

Save the two IPs to connect to k8s worker nodes from the k8s control node later 

---

## How to connect to nodes
First copy your local default rsa key to k8s control node, this will allow you to ssh to k8s worker nodes from the k8s control node
```bash
# replace xx.xx.xx.xx with k8s control node public IP
scp ~/.ssh/id_rsa ubuntu@xx.xx.xx.xx:~/.ssh/
```
To ssh to k8s control node run command
```bash
# replace xx.xx.xx.xx with k8s control node public IP
ssh ubuntu@xx.xx.xx.xx
```
From k8s control node you can ssh to all k8s worker nodes with command
```bash
# replace xx.xx.xx.xx with a k8s worker node private IP
ssh ubuntu@xx.xx.xx.xx
```

---
---
---

# Init k8s cluster
ssh to k8s control node, run the following commands from the k8s control node
```bash
sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version 1.21.0
```
After above command finishes, run the commands
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Verify cluster started
```bash
kubectl get nodes
```
Above command will show this machine with status 'not ready', okay to ignore

```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```
The command above will setup networking for the cluster
## Get join command to run on worker nodes
```bash
kubeadm token create --print-join-command
```
**Copy output to run the join command with sudo on worker nodes to join to cluster**

---
---
---

# Join worker nodes to cluster
ssh to worker nodes from k8s control node

run commands on worker nodes to join to cluster
## Run join command on worker nodes
Add sudo first, then paste join command from previous command's output

ex:
```bash
sudo kubeadm join ....
```
## Verify worker nodes joined cluster
ssh to k8s control node

run command to get nodes in cluster
```bash
kubectl get nodes
```
After a few minutes all nodes should have status ready