#!/bin/bash
# scripts/setup_github_auth.sh

# --- CONFIGURATION ---
PROJECT_ID="supernova-aperion-platform"
SERVICE_ACCOUNT="supernova-gke-sa@${PROJECT_ID}.iam.gserviceaccount.com"
GITHUB_REPO="YOUR_GITHUB_ORG/SuperNOVA-Aperion-platform" # <--- UPDATE THIS
POOL_NAME="supernova-aperion-platform" # Should match your Terraform workload_pool

echo "🔐 Fetching Project Number..."
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

echo "🚀 Binding GitHub Repository to GKE Service Account..."

# This command links your GitHub Actions runner to your GCP Service Account
# allowing for passwordless, keyless authentication via Workload Identity.
gcloud iam service-accounts add-iam-policy-binding "$SERVICE_ACCOUNT" \
    --project="$PROJECT_ID" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}.svc.id.goog/attribute.repository/${GITHUB_REPO}"

echo "✨ Success! GitHub can now act as $SERVICE_ACCOUNT"
