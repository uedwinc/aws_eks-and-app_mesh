# AWS EKS and App Mesh

In this project, we will create a single Node EKS cluster. After that, we will install AWS App Mesh. We will deploy a sample polyglot application and implement traffic routing and mutual TLS authentication. Lastly, we will use the X-Ray service to trace the communication between individual services.

# Deploying an EKS Cluster

We will be deploying an EKS cluster using a CLI utility called `eksctl`. Then, we will access the endpoint using `kubectl`, which is a command-line binary to access Kubernetes resources.

1. Create an eks-manager-server instance on aws (ubuntu, t2.micro)
2. SSH into the instance
3. Install unzip to be used in the next command:

```sh
sudo apt update -y
sudo apt install unzip -y
```

5. Install aws cli following linux instructions: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
6. Go to IAM and create a user with access permissions as defined here: https://eksctl.io/installation/#prerequisite
7. Configure the eks-manager-server instance with the credentials of the newly created user
8. Follow the installation process here: https://eksctl.io/installation/#for-unix to install the `eksctl` cli binary
9. Do `eksctl version` to confirm
10. We will create an ec2 key pair so that we can use that key pair to SSH into a worker Node if required:

```sh
aws ec2 create-key-pair --key-name celestial --region us-east-2 > celestial.pem
```

11. Once we have a key pair, we will create an EKS cluster using eksctl. For now, we are creating a public endpoint EKS cluster.

```sh
eksctl create cluster --name celestials --region us-east-2 --with-oidc --ssh-access --ssh-public-key celestial --managed
```

The preceding command will show the status in `stdout`, but in parallel, it will create a CloudFormation stack (Confirm on the CloudFormation console), which basically spins up all the resources required for an EKS cluster, for example, a VPC, a security group, a worker Node group, and the EKS control plane

Navigate to the EKS console to see the status of the EKS cluster.

At the end of `stdout`, eksctl will create a config file in the `~/.kube` folder. This config file includes the access token and endpoint of the EKS cluster. 

To connect to the EKS cluster, we will be using the `kubectl` CLI tool, which reads the config file and connects to the EKS cluster

12. Install kubectl on the linux server following https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/ using the binary with curl approach
13. Run the following commands:

```sh
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version
```

In the preceding `kubectl version` command, we got the client and server version information, which means we can connect to the EKS endpoint.

To get the Nodes information, execute the following command:

```sh
kubectl get nodes -o wide
```

We have successfully created an EKS cluster.
