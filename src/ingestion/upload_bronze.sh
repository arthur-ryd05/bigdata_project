#!/usr/bin/env bash
# Depot des fichiers bruts dans la couche bronze du bucket S3 Onyxia.
# Chaque objet porte en metadonnees sa source, son commit et son sha256 (tracabilite).
#   bash src/ingestion/upload_bronze.sh [dossier_local]   (defaut : data/bronze)
set -euo pipefail

SRC_DIR="${1:-data/bronze}"
BUCKET="${LAB_BUCKET_NAME:-${KUBERNETES_NAMESPACE:?definir LAB_BUCKET_NAME ou KUBERNETES_NAMESPACE}}"
# Meme racine que dbt (LAKE_ROOT) : on depose exactement la ou dbt lit.
LAKE_ROOT="${LAKE_ROOT:-s3://$BUCKET/gr05/rapprochement}"
PROFILE=(--profile "${AWS_PROFILE:-default}")
COMMIT=$(python3 -c "import json;print(json.load(open('$SRC_DIR/manifest.json'))['source_commit'])")

for f in "$SRC_DIR"/*.asc "$SRC_DIR"/manifest.json; do
  name=$(basename "$f")
  sum=$(sha256sum "$f" | cut -d' ' -f1)
  aws s3 "${PROFILE[@]}" cp "$f" "$LAKE_ROOT/bronze/$name" \
    --metadata "source=jlacko/berka-dataset,commit=$COMMIT,sha256=$sum"
done

echo "--- contenu de $LAKE_ROOT/bronze/"
aws s3 "${PROFILE[@]}" ls "$LAKE_ROOT/bronze/" --human-readable --summarize
