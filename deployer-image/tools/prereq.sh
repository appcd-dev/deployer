#!/bin/bash

# Prompt for necessary inputs
read -p "Enter your Google Cloud Project ID: " PROJECT_ID
read -p "Enter your GKE Cluster Name: " CLUSTER_NAME
read -p "Enter your GKE Cluster Region (e.g., us-central1): " CLUSTER_REGION

# Fixed service account parameters
GSA_NAME="terraform-runner-sa"
K8S_SERVICE_ACCOUNT="terraform-runner"
NAMESPACE="default"  # Using default namespace for deployer container

echo "Using Project ID: $PROJECT_ID"
echo "Cluster: $CLUSTER_NAME in region $CLUSTER_REGION"
echo "Using fixed names: GSA=$GSA_NAME, KSA=$K8S_SERVICE_ACCOUNT in namespace $NAMESPACE"

# Step 1: Enable required APIs
REQUIRED_APIS=(
  "cloudresourcemanager.googleapis.com"
  "iam.googleapis.com"
  "container.googleapis.com"
)

echo "Checking and enabling required APIs for project $PROJECT_ID..."
for API in "${REQUIRED_APIS[@]}"; do
  if ! gcloud services list --enabled --project="$PROJECT_ID" --format="value(config.name)" | grep -q "$API"; then
    echo "Enabling API: $API..."
    gcloud services enable "$API" --project="$PROJECT_ID"
  else
    echo "API already enabled: $API"
  fi
done

# Step 2: Check if Workload Identity is enabled
WORKLOAD_POOL=$(gcloud container clusters describe "$CLUSTER_NAME" --region "$CLUSTER_REGION" --project "$PROJECT_ID" --format="value(workloadIdentityConfig.workloadPool)")

if [[ -z "$WORKLOAD_POOL" ]]; then
  echo "Workload Identity is NOT enabled on cluster $CLUSTER_NAME."
  read -p "Do you want to enable Workload Identity on this cluster? (y/n): " ENABLE_WI
  if [[ "$ENABLE_WI" =~ ^[Yy]$ ]]; then
    echo "Enabling Workload Identity..."
    gcloud container clusters update "$CLUSTER_NAME" \
      --workload-pool="${PROJECT_ID}.svc.id.goog" \
      --region="$CLUSTER_REGION" \
      --project="$PROJECT_ID"
    WORKLOAD_POOL=$(gcloud container clusters describe "$CLUSTER_NAME" --region "$CLUSTER_REGION" --project "$PROJECT_ID" --format="value(workloadIdentityConfig.workloadPool)")
    if [[ -z "$WORKLOAD_POOL" ]]; then
      echo "Failed to enable Workload Identity. Exiting."
      exit 1
    else
      echo "Workload Identity enabled: $WORKLOAD_POOL"
    fi
  else
    echo "Workload Identity is required. Exiting."
    exit 1
  fi
else
  echo "Workload Identity is enabled: $WORKLOAD_POOL"
fi

# Step 3: Create Google Service Account (GSA) if not exists
EXISTING_GSA=$(gcloud iam service-accounts list --filter="email:${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" --format="value(email)")
if [ -z "$EXISTING_GSA" ]; then
  echo "Creating Google Service Account: $GSA_NAME"
  gcloud iam service-accounts create ${GSA_NAME} \
    --display-name="Terraform Runner Service Account" \
    --project=${PROJECT_ID}
else
  echo "Google Service Account ${GSA_NAME} already exists."
fi

# Step 4: Assign IAM roles to the GSA
echo "Assigning IAM roles to ${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/resourcemanager.projectIamAdmin"


# Step 5: Create Kubernetes Service Account (KSA) in the default namespace
echo "Creating Kubernetes Service Account '$K8S_SERVICE_ACCOUNT' in namespace '$NAMESPACE'..."
kubectl create serviceaccount ${K8S_SERVICE_ACCOUNT} -n ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Step 6: Annotate the KSA for Workload Identity in the default namespace
echo "Annotating Service Account for Workload Identity..."
kubectl annotate serviceaccount ${K8S_SERVICE_ACCOUNT} -n ${NAMESPACE} \
  iam.gke.io/gcp-service-account=${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com --overwrite

# Step 7: Grant Workload Identity User Role
echo "Granting Workload Identity User role to ${GSA_NAME}..."
gcloud iam service-accounts add-iam-policy-binding ${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${NAMESPACE}/${K8S_SERVICE_ACCOUNT}]"

echo "Setup complete."
echo "Verify Kubernetes ServiceAccount:"
kubectl get serviceaccount ${K8S_SERVICE_ACCOUNT} -n ${NAMESPACE} -o yaml
echo "Verify Google ServiceAccount exists:"
gcloud iam service-accounts list --filter="email:${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
