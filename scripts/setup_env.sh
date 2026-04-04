#!/bin/bash
# scripts/setup_env.sh

# Load variables (ensure these match your terraform.tfvars)
PROJECT_ID="supernova-aperion-platform"
REGION="us-central1"
REPO_NAME="supernova-repo"

echo "🛠️ Configuring Environment for $PROJECT_ID..."

# 1. Enable Artifact Registry API
echo "📡 Enabling Artifact Registry API..."
gcloud services enable artifactregistry.googleapis.com

# 2. Create the Docker Repository
# We use 'check' logic so the script is idempotent (can be run multiple times)
if gcloud artifacts repositories describe $REPO_NAME --location=$REGION >/dev/null 2>&1; then
    echo "✅ Repository $REPO_NAME already exists."
else
    echo "📦 Creating Artifact Registry: $REPO_NAME..."
    gcloud artifacts repositories create $REPO_NAME \
        --repository-format=docker \
        --location=$REGION \
        --description="Docker repository for SuperNOVA microservices"
fi

# 3. Configure Docker Authentication
# This is CRITICAL: It tells your local Docker how to talk to Google's Registry
echo "🔐 Configuring Docker auth for $REGION..."
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

echo "✨ Environment Setup Complete!"
