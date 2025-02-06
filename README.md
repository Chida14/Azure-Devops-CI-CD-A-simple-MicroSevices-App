# Azure-Devops-CI-CD-A-Simple-MicroSevices-App

# 1. Introduction

This project is a reference implementation showing how to build, test, and deploy a simple distributed application using Azure DevOps, running across multiple K8s deployments and services. We leverage a fully automated pipeline for both Continuous Integration (CI) and Continuous Deployment (CD), ensuring code quality, reliability, and speed of delivery.

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
 
```bash
.
├── k8s-specifications/                       # K8s YAML manifests for Vote, Worker, Redis, Postgressdb and Result microservices
├── K8s-terraform-manifest/                   # Terraform files for deploying infrastructure (AKS)
├── result/                                   # Node.js web application (displays voting results)
├── vote/                                     # Python-based frontend voting application
├── worker/                                   # .NET worker service that processes and stores votes
├── 01-Vote-build-push-to-ACR.yml             # Azure DevOps pipeline for building & pushing Vote image
├── 02-Worker-build-push-to-ACR.yml           # Azure DevOps pipeline for building & pushing Worker image
├── 03-Result-Build-and-Push-to-ACR.yml       # Azure DevOps pipeline for building & pushing Result image
├── 04-K8s-Iac-Terraform.yml                  # Azure DevOps pipeline for validating and applying Terraform
└── 05-K8s-specifications-Publish-to-Release-Pipeline.yml
                                              # Pipeline that packages K8s manifests and triggers deployment
> ```

---

## 4. Prerequisites

- **Tools**: Azure CLI, Docker, Terraform, ArgoCD, HELM.  
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
- **Build and Container Image Creation**  
- **Security Scanning** of the container image using tools like Trivy  
- **Publishing** of the resulting image to **Azure Container Registry (ACR)**  

A shell script also updates the Kubernetes deployment manifests (`Vote`, `Worker`, and `Result`) in the `k8s-specifications` directory with the latest container image tag.

**Trigger**: CI is triggered on every push to the main (default) branch or via pull requests.

---

### Push Deployment

In a **push-based** deployment model (using a Kubernetes deployment task in the Azure DevOps release pipeline), container images are pushed to the target environment (Dev, Staging, Production) once the build is successful. We use a single AKS cluster with separate namespaces to isolate each environment.

- **Trigger**: Typically occurs on merges to `main` or on completion of a successful build in Dev, Staging, or Production.

---

### GitOps Approach (ArgoCD)

We also have a **GitOps** strategy using **ArgoCD** installed in the AKS cluster via Helm charts. In this model:

1. **ArgoCD** continuously watches a designated Git repository (in this case, `Azure repo- k8s-specifications/`) which acts as the source of truth for Kubernetes manifests.  
2. When a new commit updates the image tag or other config in the manifest, **ArgoCD** detects this change and automatically reconciles the live cluster to match the desired state in Git.  
3. If any drift occurs (someone manually modifies a resource in AKS), ArgoCD reverts the cluster to the Git-defined state.

This approach centralizes environment control in the cluster itself rather than in the deployment pipeline.

---

## 6. Environment Variables and Secrets

- **Azure Key Vault**:  
  - Azure DevOps Personal Access Token (PAT) is stored as a secret in Key Vault. The Key Vault is linked to variable groups in Azure DevOps, and the PAT is used in scripts.  

- **Variable Groups**:  
  - The Key Vault secret (Azure PAT) is linked to the pipeline via a variable named `az-repo2-token`. This variable is utilized in the “Update_Image_tag” stage of the CI pipelines to authenticate and push image references.

---

## 7. Troubleshooting

A few issues encountered during the project:

- **Access Denied**: Azure DevOps permissions misconfiguration.  
- **Release Errors**: Incorrect service connections to Azure Container Registry, Kubernetes, or Managed Identities causing “permission denied” errors.  
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
