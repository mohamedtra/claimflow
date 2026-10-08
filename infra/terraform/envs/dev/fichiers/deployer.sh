#!/usr/bin/env bash
# Déploie la pile ClaimFlow sur l'instance, ou la remet à jour. Idempotent.
# Lancé au premier démarrage (user_data), puis par la CI via SSM Run Command (_deploiement.yml) :
#   1. relit la configuration dans S3 (config/) ;
#   2. lit les secrets dans SSM, et crée ceux qui manquent (premier déploiement) ;
#   3. lit la version de l'API à déployer (/claimflow/<env>/version/api) ;
#   4. tire les images, relance les conteneurs modifiés, recharge nginx et attend que l'API réponde.
set -euo pipefail

# shellcheck source=/dev/null
source /etc/claimflow/environnement # ENVIRONNEMENT, REGION, BUCKET_EXPLOITATION
export AWS_DEFAULT_REGION="$REGION"
PREFIXE="/claimflow/${ENVIRONNEMENT}"
REP=/opt/claimflow

journal() { echo "[deployer] $*"; }

# Valeur d'un paramètre SSM, vide s'il n'existe pas ; toute autre erreur arrête le script.
parametre() {
  local sortie
  if sortie=$(aws ssm get-parameter --name "$1" --with-decryption --query Parameter.Value --output text 2>&1); then
    printf '%s' "$sortie"
  elif grep -q ParameterNotFound <<<"$sortie"; then
    printf ''
  else
    echo "$sortie" >&2
    return 1
  fi
}

# Secret de l'environnement : lu dans SSM, ou généré puis rangé dans SSM s'il n'existe pas encore.
secret() {
  local nom="${PREFIXE}/secrets/$1" valeur
  valeur=$(parametre "$nom")
  if [ -z "$valeur" ]; then
    valeur=$(openssl rand -hex 24)
    aws ssm put-parameter --name "$nom" --type SecureString --value "$valeur" --no-overwrite >/dev/null
    journal "secret $1 créé dans SSM" >&2
  fi
  printf '%s' "$valeur"
}

journal "configuration depuis s3://${BUCKET_EXPLOITATION}/config/"
mkdir -p "$REP/config" /srv/claimflow/donnees/postgres
aws s3 sync "s3://${BUCKET_EXPLOITATION}/config/" "$REP/config/" --delete --only-show-errors
chmod +x "$REP/config/"*.sh

url_publique=$(parametre "${PREFIXE}/url")
secret_origine=$(parametre "${PREFIXE}/origine/secret")
version_api=$(parametre "${PREFIXE}/version/api")
[ -n "$url_publique" ] && [ -n "$secret_origine" ] || {
  echo "Paramètres ${PREFIXE}/url ou ${PREFIXE}/origine/secret absents : lancer Infra (apply) d'abord." >&2
  exit 1
}

# Une affectation par secret : une erreur SSM arrête le script (dans un echo, elle passerait).
mdp_postgres=$(secret postgres)
mdp_claimflow=$(secret claimflow)
mdp_app=$(secret claimflow-app)
mdp_keycloak_db=$(secret keycloak-db)
mdp_keycloak_admin=$(secret keycloak-admin)

umask 077
cat > "$REP/.env.nouveau" <<FIN
POSTGRES_PASSWORD=${mdp_postgres}
CLAIMFLOW_PASSWORD=${mdp_claimflow}
CLAIMFLOW_APP_PASSWORD=${mdp_app}
KEYCLOAK_DB_PASSWORD=${mdp_keycloak_db}
KEYCLOAK_ADMIN_PASSWORD=${mdp_keycloak_admin}
URL_PUBLIQUE=${url_publique}
VERSION_API=${version_api:-dev}
FIN
mv "$REP/.env.nouveau" "$REP/.env"

sed -e "s|@SECRET_ORIGINE@|${secret_origine}|" -e "s|@HOTE_PUBLIC@|${url_publique#https://}|" \
  "$REP/config/nginx.conf.modele" > "$REP/nginx.conf"
umask 022
chmod 644 "$REP/nginx.conf"

compose() { docker compose --project-directory "$REP" -f "$REP/config/docker-compose.yml" "$@"; }

journal "version de l'API : ${version_api:-dev}"
compose pull --quiet
compose up -d --remove-orphans

# Compose ne recrée un conteneur que si sa définition change, pas quand seul le contenu d'un
# fichier monté change : nginx doit relire nginx.conf, après l'avoir validé.
journal "rechargement de nginx"
compose exec -T proxy nginx -t -q
compose exec -T proxy nginx -s reload

journal "attente de l'API"
for _ in $(seq 1 60); do
  if curl -fsS -o /dev/null -H "X-Origine-CloudFront: ${secret_origine}" http://127.0.0.1/actuator/health; then
    journal "API en bonne santé"
    docker image prune -f >/dev/null
    compose ps --format 'table {{.Service}}\t{{.Image}}\t{{.Status}}'
    exit 0
  fi
  sleep 5
done

echo "L'API ne répond pas après 5 minutes. Derniers journaux :" >&2
compose logs --tail 80 api >&2
exit 1
