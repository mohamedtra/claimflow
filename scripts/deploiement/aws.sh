#!/usr/bin/env bash
# Déploie un composant de ClaimFlow sur AWS. Appelé par .github/workflows/_deploiement.yml, avec des
# identifiants AWS temporaires obtenus par OIDC. Les identifiants des ressources sont lus dans SSM
# (/claimflow/<environnement>/…, écrits par Terraform) : rien n'est codé en dur ici.
#
#   aws.sh api   démarre l'instance si besoin, enregistre la version, lance deployer.sh par SSM
#   aws.sh web   extrait les fichiers de l'image web, les publie dans S3, invalide CloudFront
#
# Variables attendues : ENVIRONNEMENT, IMAGE (sans étiquette), SHA (étiquette de l'image), VERSION.
set -euo pipefail

composant="${1:?api ou web}"
: "${ENVIRONNEMENT:?}" "${IMAGE:?}" "${SHA:?}" "${VERSION:?}"
PREFIXE="/claimflow/${ENVIRONNEMENT}"

parametre() { aws ssm get-parameter --name "${PREFIXE}/$1" --query Parameter.Value --output text; }
echouer() { echo "::error title=$1::$2"; exit 1; }

url=$(parametre url) || echouer "Environnement introuvable" \
  "Paramètre ${PREFIXE}/url absent : lancer d'abord Actions → Infra → apply."
echo "url=${url}" >> "${GITHUB_OUTPUT:-/dev/null}"
echo "::notice title=Adresse de ${ENVIRONNEMENT}::${url}"

attendre_sante() {
  local adresse="$1"
  for _ in $(seq 1 30); do
    if curl -fsS -o /dev/null --max-time 10 "$adresse"; then
      echo "Répond : $adresse"
      return 0
    fi
    sleep 10
  done
  echouer "Contrôle de santé" "$adresse ne répond pas après 5 minutes."
}

deployer_api() {
  local instance bucket etat statut commande
  instance=$(parametre instance-id)
  bucket=$(parametre bucket-exploitation)

  # L'instance est arrêtée la nuit (planification.tf) : un déploiement la redémarre.
  etat=$(aws ec2 describe-instances --instance-ids "$instance" \
    --query 'Reservations[0].Instances[0].State.Name' --output text)
  echo "Instance $instance : $etat"
  case "$etat" in
    stopping) aws ec2 wait instance-stopped --instance-ids "$instance" ;&
    stopped)
      aws ec2 start-instances --instance-ids "$instance" >/dev/null
      aws ec2 wait instance-running --instance-ids "$instance" ;;
    pending | running) aws ec2 wait instance-running --instance-ids "$instance" ;;
    *) echouer "Instance indisponible" "État inattendu : $etat" ;;
  esac

  echo "Attente de l'agent SSM…"
  for _ in $(seq 1 60); do
    statut=$(aws ssm describe-instance-information \
      --filters "Key=InstanceIds,Values=${instance}" \
      --query 'InstanceInformationList[0].PingStatus' --output text)
    [ "$statut" = Online ] && break
    sleep 10
  done
  [ "$statut" = Online ] || echouer "Agent SSM" "L'agent SSM de $instance n'est pas en ligne après 10 minutes."

  # La version déployée est enregistrée avant le déploiement : un redémarrage de l'instance
  # relance cette version, pas la précédente.
  aws ssm put-parameter --name "${PREFIXE}/version/api" --type String --value "$SHA" --overwrite >/dev/null

  commande=$(aws ssm send-command \
    --instance-ids "$instance" \
    --document-name AWS-RunShellScript \
    --comment "ClaimFlow api ${VERSION}" \
    --parameters "$(jq -cn --arg b "$bucket" '{
        commands: [
          "set -e",
          "aws s3 cp s3://\($b)/config/deployer.sh /opt/claimflow/deployer.sh --only-show-errors",
          "bash /opt/claimflow/deployer.sh"
        ],
        executionTimeout: ["900"]
      }')" \
    --query Command.CommandId --output text)
  echo "Commande SSM : $commande"

  for _ in $(seq 1 100); do
    sleep 10
    statut=$(aws ssm get-command-invocation --command-id "$commande" --instance-id "$instance" \
      --query Status --output text 2>/dev/null || echo Pending)
    case "$statut" in Pending | InProgress | Delayed) continue ;; *) break ;; esac
  done

  echo "::group::Sortie de deployer.sh"
  aws ssm get-command-invocation --command-id "$commande" --instance-id "$instance" \
    --query '[StandardOutputContent, StandardErrorContent]' --output text
  echo "::endgroup::"
  [ "$statut" = Success ] || echouer "Déploiement de l'API" \
    "deployer.sh a terminé en « $statut ». Voir le groupe « Sortie de deployer.sh »."

  attendre_sante "${url}/actuator/health"
  # Keycloak démarre après l'API (construction au premier lancement) : le sprint 1 en dépend.
  attendre_sante "${url}/auth/realms/claimflow/.well-known/openid-configuration"
}

deployer_web() {
  local bucket distribution conteneur invalidation
  bucket=$(parametre bucket-spa)
  distribution=$(parametre distribution-id)

  # Les fichiers sont ceux de l'image construite et testée : rien n'est reconstruit.
  rm -rf spa
  conteneur=$(docker create "${IMAGE}:${SHA}")
  docker cp "${conteneur}:/usr/share/nginx/html" spa
  docker rm "$conteneur" >/dev/null

  # Fichiers nommés par empreinte (assets/) : cache d'un an. index.html : toujours revalidé.
  # Pas de --delete : un navigateur qui a encore l'ancien index.html doit trouver ses fichiers.
  aws s3 sync spa/ "s3://${bucket}/" --exclude index.html \
    --cache-control "public,max-age=31536000,immutable" --only-show-errors
  aws s3 cp spa/index.html "s3://${bucket}/index.html" --cache-control "no-cache" --only-show-errors

  invalidation=$(aws cloudfront create-invalidation --distribution-id "$distribution" \
    --paths "/index.html" "/" --query Invalidation.Id --output text)
  echo "Invalidation CloudFront : $invalidation"
  aws cloudfront wait invalidation-completed --distribution-id "$distribution" --id "$invalidation"

  attendre_sante "${url}/"
}

case "$composant" in
  api) deployer_api ;;
  web) deployer_web ;;
  *) echouer "Composant inconnu" "$composant" ;;
esac
