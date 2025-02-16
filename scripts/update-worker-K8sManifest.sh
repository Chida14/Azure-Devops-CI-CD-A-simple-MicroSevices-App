#!/bin/bash

set -x

# Set the repository URL.
REPO_URL="https://$4@dev.azure.com/cmandolk/voting-new/_git/voting-new"

# Clone the git repository into the /tmp directory
git clone "$REPO_URL" /tmp/test3

# Navigate into the cloned repository directory
cd /tmp/test3


# Make changes to the Kubernetes manifest file(s)
# For example, let's say you want to change the image tag in a deployment.yaml file
sed -i "s|image:.*|image: cmandolk1.azurecr.io/$2:$3|g" k8s-specifications/$1-deployment.yaml

# Add the modified files
git add .

# Commit the changes
git commit -m "Update Kubernetes manifest"

# Push the changes back to the repository
git push

# Cleanup: remove the temporary directory
rm -rf /tmp/test3