#!/bin/bash
# scripts/bootstrap.sh

PROJECT_ID="supernova-aperion-platform"
REGION="us-central1"  # Updated to Iowa
BUCKET_NAME="supernova-terraform-state"

echo "🚀 Bootstrapping SuperNOVA Platform in $REGION..."

# 1. Ensure we are using the right project
gcloud config set project $PROJECT_ID

# 2. Enable Foundational APIs
echo "📡 Enabling APIs..."
gcloud services enable \
    compute.googleapis.com \
    container.googleapis.com \
    aiplatform.googleapis.com \
    secretmanager.googleapis.com \
    serviceusage.googleapis.com \
    cloudresourcemanager.googleapis.com \
    iam.googleapis.com

# 3. Create the Terraform State Bucket
if gsutil ls -b gs://$BUCKET_NAME >/dev/null 2>&1; then
    echo "✅ Bucket gs://$BUCKET_NAME already exists."
else
    echo "📦 Creating state bucket in $REGION..."
    # Use -l to specify the region for the storage bucket
    gsutil mb -p $PROJECT_ID -l $REGION gs://$BUCKET_NAME
    gsutil versioning set on gs://$BUCKET_NAME
fi

echo "✨ Bootstrap Complete! You are ready to run 'terraform init'."
