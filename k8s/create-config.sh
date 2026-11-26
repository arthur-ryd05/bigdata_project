#!/usr/bin/env bash
# Cree la configuration des Jobs a partir du profil AWS d'Onyxia (secrets jamais affiches).
set -euo pipefail
cd "$(dirname "$0")/.."
BUCKET="${LAB_BUCKET_NAME:-$KUBERNETES_NAMESPACE}"
ENDPOINT_URL=$(aws configure get endpoint_url --profile default || echo "https://$AWS_S3_ENDPOINT")

kubectl delete configmap rappro-ingest-code rappro-s3-config --ignore-not-found
kubectl delete secret rappro-s3-credentials --ignore-not-found

kubectl create configmap rappro-ingest-code \
  --from-file=src/ingestion/extract_berka.py
kubectl create configmap rappro-s3-config \
  --from-literal=AWS_ENDPOINT_URL="$ENDPOINT_URL" \
  --from-literal=AWS_S3_ENDPOINT="${ENDPOINT_URL#https://}" \
  --from-literal=AWS_DEFAULT_REGION="$(aws configure get region --profile default || echo us-east-1)" \
  --from-literal=LAB_BUCKET_NAME="$BUCKET"

umask 077
trap 'rm -f s3.env' EXIT
aws configure export-credentials --profile default --format env-no-export \
  | grep -E '^AWS_(ACCESS_KEY_ID|SECRET_ACCESS_KEY|SESSION_TOKEN)=' > s3.env
kubectl create secret generic rappro-s3-credentials --from-env-file=s3.env
kubectl get configmap rappro-ingest-code rappro-s3-config && kubectl get secret rappro-s3-credentials
