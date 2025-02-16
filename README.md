# Azure-Devops-CI-CD-A-Simple-MicroSevices-App

# 1. Introduction

This project is a reference implementation showing how to build, test, and deploy a simple microservices application using Azure DevOps, running across multiple K8s deployments and services. We leverage a fully automated pipeline for both Continuous Integration (CI) and Continuous Deployment (CD), ensuring code quality, reliability, and speed of delivery.

The source code is cloned from [https://github.com/dockersamples/example-voting-app](https://github.com/dockersamples/example-voting-app).

---

## 2. Architecture Overview

### 2.1. Application Architecture

This is a simple voting application made up of multiple microservices:

- **A front-end web app in Python** which lets you vote between two options  
- **A Redis** instance that collects new votes  
- **A .NET worker** which consumes votes and stores them in…  
- **A Postgres database** backed by a Docker volume  
- **A Node.js web app** which shows the results of the voting in real time
  
![Image](https://github.com/user-attachments/assets/7c885ce4-930b-4469-a3bc-5a331006c4a4)

### 2.2. CI/CD Architecture

We use two approaches to deploy to our Kubernetes clusters: **push-based** deployments and a **GitOps** approach using ArgoCD.

![Image](https://github.com/user-attachments/assets/00dc93a4-9665-407d-9b6d-b0e6adb090a4)

![Image](https://github.com/user-attachments/assets/6aa79828-5cf5-4c69-b979-b1d091a88f89)

---

## 3. Project Directory Structure

Important folders and files in the repository used for the CI/CD process. (Adjust to your repository layout as needed.)

> **Example**  
> ```bash
> .
> ├── k8s-specifications/                       # K8s YAML manifests for Vote, Worker, Redis, Postgressdb and Result microservices
> ├── K8s-terraform-manifest/                   # Terraform files for deploying infrastructure (AKS)
> ├── result/                                   # Node.js web application (displays voting results)
> ├── vote/                                     # Python-based frontend voting application
> ├── worker/                                   # .NET worker service that processes and stores votes
> ├── 01-Vote-build-push-to-ACR.yml             # Azure DevOps pipeline for building & pushing Vote image
> ├── 02-Worker-build-push-to-ACR.yml           # Azure DevOps pipeline for building & pushing Worker image
> ├── 03-Result-Build-and-Push-to-ACR.yml       # Azure DevOps pipeline for building & pushing Result image
> ├── 04-K8s-Iac-Terraform.yml                  # Azure DevOps pipeline for validating and applying Terraform
> └── 05-K8s-specifications-Publish-to-Release-Pipeline.yml # Pipeline that packages K8s manifests and triggers deployment
>                                              # Pipeline that packages K8s manifests and triggers deployment
> ```

---

## 4. Prerequisites

- **Tools**: Azure CLI, Docker, Terraform, ArgoCD.  
- **Azure DevOps**: Valid account with appropriate permissions to create pipelines and releases.  
- **GitHub Access**: Permission to clone/push/pull from this repository.  
- **IDE**: (Optional) VSCode (or any IDE of choice).

---

## 5. Azure DevOps CI/CD Overview

### Continuous Integration (CI) & Continuous Delivery/Deployment (CD)

We have **5 pipelines** set up, each targeting specific aspects of this project:

1. **Vote Microservice CI**  
2. **Worker Microservice CI**  
3. **Result Microservice CI**  
4. **K8s-Iac-Terraform-Manifest-Pipeline**:  
   - Validates Terraform manifests, runs the plan, and if everything goes well, applies it to deploy to the AKS cluster in Azure.  

5. **K8s-specifications-Publish-to-Pipeline**:  
   - Publishes the Kubernetes manifest files to a staging directory in the pipeline for the release pipeline to pick up and deploy the application to the Dev AKS cluster.

Within each microservice’s CI pipeline, we perform:

- **Code Analysis** using SonarQube  
- **Build Container Image**  
- **Security Scanning** of the container image using Trivy  
- **Publishing** of the image to **Azure Container Registry (ACR)**  

A shell script is to used update the Kubernetes deployment manifests (`Vote`, `Worker`, and `Result`) in the `k8s-specifications` directory with the latest container image tag.

**Trigger**: CI is triggered on every push to the main (default) branch in the respective folders vote, result and worker.

![Image](https://github.com/user-attachments/assets/f4d9662e-0a7c-480c-ab63-92fcfa4769e7)

---

### Push Deployment

In a **push-based** deployment model (using a Kubernetes deployment task in the Azure DevOps release pipeline), container images are pushed to the target environment (Dev, Staging, Production). In this project we use a single AKS cluster with separate namespaces to isolate each environment. Each stage is can be configured with Pre and Post- Deployment approvals.

- **Trigger**: Occurs on merges or pr on `main` branch in the k8s-specifications/

State of the environment is controlled primarily by the pipeline rather than by the environment itself.

![Image](https://github.com/user-attachments/assets/4332102f-2e27-4426-8588-6cdc6a266ff9)

---

### GitOps Approach (ArgoCD)

We also have a **GitOps** strategy using **ArgoCD** installed in the AKS cluster. In this model:

1. **ArgoCD** continuously watches a designated Git repository (in this case, `Azure repo- k8s-specifications/`) which acts as the source of truth for Kubernetes manifests.  
2. When a new commit updates the image tag or other config in the manifest, **ArgoCD** detects this change and automatically reconciles the live cluster to match the desired state in Git.  
3. If any drift occurs (someone manually modifies a resource in AKS), ArgoCD reverts the cluster to the Git-defined state.

This approach centralizes environment control in the cluster itself rather than in the deployment pipeline.

![Image](https://github.com/user-attachments/assets/afa47985-1128-402d-9e11-0c647c79ac6d)

---

## 6. Environment Variables and Secrets

- **Azure Key Vault**:  
  - Azure DevOps Personal Access Token (PAT) is stored as a secret in Key Vault. The Key Vault is linked to variable groups in Azure DevOps, and the PAT is used in scripts.
 
  ![Image](https://github.com/user-attachments/assets/bbddfb2c-84f8-470a-85eb-5e39362d4b6e)

- **Variable Groups**:  
  - The Key Vault secret (Azure PAT) is linked to the pipeline via a variable named `az-repo2-token`. This variable is utilized in the “Update_Image_tag” stage of the CI pipelines to authenticate and push image references.
  - Subcription ID need for the provider block of the K8s terraform manifest is stored as ENV variable i the variable group and passed to the pipeline.

  ![Image](https://github.com/user-attachments/assets/1798a6a2-78e2-44a3-a36f-cb54b3aacca4)

  ![Image](https://github.com/user-attachments/assets/02ab8146-f24a-49a1-aa8d-8e52fa9b6876)

  ![Image](https://github.com/user-attachments/assets/68b77e0b-7c1d-4d46-ac1a-0d7e137d79fb)
  
---

## 7. Troubleshooting

A few issues encountered during the project:

- **Access Denied**: Azure DevOps permissions misconfiguration.  Ensuring the managed identities have right authorization to access images in the registry etc
- **Release Errors**: Incorrect service connections to Azure Container Registry, Kubernetes, Azure storageaccount (used as backend to store the terraform state file) or Managed Identities causing “permission denied” errors.  
- **Docker Registry Secrets**: Creating Kubernetes secrets to ensure deployments can pull images with the correct tags and credentials.

---

## 8. Best Practices

Some of the best practices utilized in this project include:

- **Security**:  
  - Use secure variable storage like Azure Key Vault.  
  - Upload secure files to the pipeline and manage permissions carefully.  

- **Pipelines**:  
  - Organize folders and naming conventions for multiple pipelines (CI, CD, infrastructure).  

- **Commit and Push**:  
  - Write meaningful commit messages for future reference and easier auditing.

---

## End Result of the App Deployment

After the pipelines run successfully and the infrastructure plus microservices are deployed:

1. **Vote App**  
   - Accessible via a web interface (e.g., `<Node_IP>/<node_port>`) as the service type used here is NodePort
   - Users can select between two options and submit their votes.
     
![Image](https://github.com/user-attachments/assets/07b631a1-a8d1-4b9f-9646-7b3e91eb0d8e)


2. **Result App**  
   - Accessible at `<Node_IP>/<node_port>`  
   - Displays real-time vote %counts retrieved from the database, updated automatically.
  
![Image](https://github.com/user-attachments/assets/bf8e677f-9300-4347-a6e1-b18e6df7d87a)
