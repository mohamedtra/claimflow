#!/usr/bin/env bash
# Sauvegarde quotidienne des bases claimflow et keycloak vers S3 (timer systemd, 22 h 30).
# Les sauvegardes expirent au bout de 14 jours (règle de cycle de vie du bucket).
# Restauration : docs/runbooks/aws-demarrage.md.
set -euo pipefail

# shellcheck source=/dev/null
source /etc/claimflow/environnement
export AWS_DEFAULT_REGION="$REGION"
horodatage=$(date -u +%Y-%m-%dT%H%M%SZ)

for base in claimflow keycloak; do
  docker exec claimflow-postgres-1 pg_dump -U postgres --format=custom "$base" |
    aws s3 cp - "s3://${BUCKET_EXPLOITATION}/sauvegardes/${horodatage}/${base}.dump" --only-show-errors
  echo "Sauvegarde ${base} : s3://${BUCKET_EXPLOITATION}/sauvegardes/${horodatage}/${base}.dump"
done
