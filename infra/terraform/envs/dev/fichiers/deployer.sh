#!/usr/bin/env bash
# Déploie la pile ClaimFlow sur l'instance, ou la remet à jour. Idempotent.
# Lancé au premier démarrage (user_data), puis par la CI via SSM Run Command (_deploiement.yml) :
#   1. relit la configuration dans S3 (config/) ;
#   2. lit les secrets dans SSM, et crée ceux qui manquent (premier déploiement) ;
#   3. lit les versions de l'API et du BFF à déployer (/claimflow/<env>/version/api et …/bff) ;
#   4. prépare la base du BFF et, une seule fois, le passage du realm à keycloak-config-cli ;
#   5. tire les images, relance les conteneurs modifiés, applique le realm, recharge nginx et
#      attend que l'API et le BFF répondent.
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
version_bff=$(parametre "${PREFIXE}/version/bff")
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
mdp_bff_db=$(secret bff-db)
secret_client_bff=$(secret keycloak-client-bff)

umask 077
cat > "$REP/.env.nouveau" <<FIN
POSTGRES_PASSWORD=${mdp_postgres}
CLAIMFLOW_PASSWORD=${mdp_claimflow}
CLAIMFLOW_APP_PASSWORD=${mdp_app}
KEYCLOAK_DB_PASSWORD=${mdp_keycloak_db}
KEYCLOAK_ADMIN_PASSWORD=${mdp_keycloak_admin}
BFF_DB_PASSWORD=${mdp_bff_db}
SECRET_CLIENT_BFF=${secret_client_bff}
URL_PUBLIQUE=${url_publique}
VERSION_API=${version_api:-dev}
VERSION_BFF=${version_bff:-dev}
FIN
mv "$REP/.env.nouveau" "$REP/.env"

sed -e "s|@SECRET_ORIGINE@|${secret_origine}|" -e "s|@HOTE_PUBLIC@|${url_publique#https://}|" \
  "$REP/config/nginx.conf.modele" > "$REP/nginx.conf"
umask 022
chmod 644 "$REP/nginx.conf"

compose() { docker compose --project-directory "$REP" -f "$REP/config/docker-compose.yml" "$@"; }

# Le BFF n'est démarré qu'une fois sa première version promue en dev (Deploy backend, job bff).
services=(postgres keycloak keycloak-config keycloak-demo api proxy)
if [ -n "$version_bff" ]; then
  services+=(bff)
fi
journal "versions : API ${version_api:-dev}, BFF ${version_bff:-pas encore déployé}"
compose pull --quiet "${services[@]}"

# Base du BFF (sessions) : créée ici et non par init-postgres.sh, qui ne s'exécute qu'à la création
# des données. Idempotent ; le mot de passe est réaligné sur SSM à chaque déploiement.
compose up -d --wait postgres
journal "base du BFF"
compose exec -T postgres psql -v ON_ERROR_STOP=1 -q -U postgres -v mdp="$mdp_bff_db" <<'SQL'
SELECT format('CREATE ROLE bff LOGIN PASSWORD %L', :'mdp')
  WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'bff') \gexec
SELECT format('ALTER ROLE bff PASSWORD %L', :'mdp') \gexec
SELECT 'CREATE DATABASE bff OWNER bff'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'bff') \gexec
SQL

# Une seule fois par environnement : le realm importé autrefois au démarrage de Keycloak est
# supprimé, pour être recréé par keycloak-config-cli avec les comptes de démonstration (ADR-016).
# Le témoin est sur le volume de données, comme la base de Keycloak.
temoin=/srv/claimflow/donnees/realm-en-configuration-as-code
if [ ! -f "$temoin" ]; then
  compose up -d --wait keycloak
  journal "passage du realm à keycloak-config-cli"
  compose run --rm --no-deps -T --entrypoint /bin/bash \
    -v "$REP/config/migrer-realm.sh:/migrer-realm.sh:ro" keycloak-demo /migrer-realm.sh
  touch "$temoin"
fi

# Attend la fin d'un outil qui s'exécute puis s'arrête, et vérifie qu'il a réussi. On lit l'état du
# conteneur : « docker compose wait » ne trouve pas un conteneur déjà arrêté.
attendre_outil() {
  local outil="$1" id etat code
  for _ in $(seq 1 60); do
    id=$(compose ps -a -q "$outil")
    if [ -n "$id" ]; then
      read -r etat code < <(docker inspect -f '{{.State.Status}} {{.State.ExitCode}}' "$id")
      if [ "$etat" = exited ]; then
        [ "$code" = 0 ] && return 0
        echo "$outil a échoué (code $code). Derniers journaux :" >&2
        compose logs --tail 60 "$outil" >&2
        exit 1
      fi
    fi
    sleep 5
  done
  echo "$outil n'a pas terminé après 5 minutes. Derniers journaux :" >&2
  compose logs --tail 60 "$outil" >&2
  exit 1
}

# Démarre ou met à jour les services ; keycloak-config et keycloak-demo s'exécutent puis s'arrêtent.
compose up -d --remove-orphans "${services[@]}"
attendre_outil keycloak-config
attendre_outil keycloak-demo
journal "realm appliqué"

# Compose ne recrée un conteneur que si sa définition change, pas quand seul le contenu d'un
# fichier monté change : nginx doit relire nginx.conf, après l'avoir validé.
journal "rechargement de nginx"
compose exec -T proxy nginx -t -q
compose exec -T proxy nginx -s reload

# Attend qu'une adresse réponde, au plus 5 minutes ; sinon affiche les journaux du service.
attendre() {
  local service="$1" adresse="$2"
  shift 2
  for _ in $(seq 1 60); do
    if curl -fsS -o /dev/null "$@" "$adresse"; then
      journal "$service en bonne santé"
      return 0
    fi
    sleep 5
  done
  echo "$service ne répond pas après 5 minutes. Derniers journaux :" >&2
  compose logs --tail 80 "$service" >&2
  exit 1
}

attendre api http://127.0.0.1/actuator/health -H "X-Origine-CloudFront: ${secret_origine}"
if [ -n "$version_bff" ]; then
  attendre bff http://127.0.0.1:8081/actuator/health
fi

docker image prune -f >/dev/null
compose ps --format 'table {{.Service}}\t{{.Image}}\t{{.Status}}'
