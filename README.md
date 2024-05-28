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


# Deploying an application (Product Catalog) on EKS

We will be deploying an application that comprises three microservices.

The three microservices are as follows:

  - **Frontend**: This service (`frontend-Node`) shows the UI for the Product Catalog functionality. It has been developed in `Node.js` with `ES templating`.

  - **Backend**: The backend is a REST API service (`prodcatalog`), developed in Python Flask, that does the following operations:

    - Adds a product to the catalog
    - Gets the product from the catalog
    - Gets the catalog details from the `proddetail` service
  
  - **Catalog details backend**: This is also a REST API service (`proddetail`), developed in Node.js, and is used to get the catalog details.

Perform the following steps to deploy the application on EKS:

1. Clone the following repository to your terminal, from where you can also access EKS cluster:

```sh
git clone https://github.com/uedwinc/aws_eks-and-app_mesh.git
cd aws_eks-and-app_mesh
```

2. Export AWS variables so that they're available when we execute AWS related commands:

```sh
export ACCOUNT_ID=<YOUR AWS ACCOUNT ID>
export AWS_REGION=us-east-2
export PROJECT_NAME=celestials
```

3. Now we need to create a namespace where we will deploy our services. We also need to create an Identity and Access Management (IAM) role and a service account for this namespace so that any resources in this namespace will have permission to provide the data to AWS X-Ray:

```sh
kubectl create namespace prodcatalog-ns

aws iam create-policy --policy-name ProdEnvoyNamespaceIAMPolicy --policy-document file://deployment/envoy-iam-policy.json

eksctl create iamserviceaccount --cluster celestials --namespace prodcatalog-ns --name prodcatalog-envoy-proxies --attach-policy-arn arn:aws:iam::$ACCOUNT_ID:policy/ProdEnvoyNamespaceIAMPolicy --override-existing-serviceaccounts --approve

# You can see the detail of service account
kubectl describe sa prodcatalog-envoy-proxies -n prodcatalog-ns
```

4. Next, we need to install docker following instructions here: https://docs.docker.com/engine/install/ubuntu/

  - Do `docker --version` to confirm

5. The next thing we need to do is to build the services and create a Docker image, and after that, push it into Elastic Container Registry (ECR). We will tag the Docker image with the application version:

```sh
# Login to ECR
aws ecr get-login-password --region $AWS_REGION | sudo docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Export APP_VERSION
export APP_VERSION=1.0

# Loop through each application
for app in catalog_detail product_catalog frontend_node; do
  # Check if the repository exists, if not, create it
  aws ecr describe-repositories --repository-name "$PROJECT_NAME/$app" >/dev/null 2>&1 || \
  aws ecr create-repository --repository-name "$PROJECT_NAME/$app" >/dev/null
  
  # Set the target repository URL
  TARGET="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$PROJECT_NAME/$app:$APP_VERSION"
  
  # Build the Docker image
  sudo docker build -t "$TARGET" "apps/$app"
  
  # Push the Docker image to ECR
  sudo docker push "$TARGET"
done
```
sudo docker build -t ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}/product_catalog:${APP_VERSION} .

sudo docker push ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}/product_catalog:${APP_VERSION}

Once you are done with the preceding steps, you will be able to see the Docker images in ECR.

6. Now deploy the application in the EKS cluster:

```sh
envsubst < ./deployment/deploy_app.yaml | kubectl apply -f -
```

7. Once all the services are deployed, you can verify that using the following commands:

```sh
kubectl get deployments -n prodcatalog-ns

kubectl get pods -n prodcatalog-ns

kubectl get services -n prodcatalog-ns
```

