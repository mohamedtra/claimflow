#!/usr/bin/env bash
# Vérifie le realm appliqué en CI (ADR-016) : connexion par numéro de sociétaire ou e-mail (D1),
# second facteur du personnel (D2), comptes de démonstration aux identifiants attendus.
set -euo pipefail

kc=${KEYCLOAK_URL:-http://localhost:8180}
echec() { echo "::error title=Realm Keycloak::$1"; exit 1; }

jeton=$(curl -fsS -d client_id=admin-cli -d grant_type=password -d username=admin \
  --data-urlencode "password=${KEYCLOAK_ADMIN_PASSWORD:-admin}" \
  "$kc/realms/master/protocol/openid-connect/token" | jq -r .access_token)
admin() { curl -fsS -H "Authorization: Bearer $jeton" "$kc/admin/realms/claimflow$1"; }

# Connexion directe par le client admin-cli du realm : elle passe par la vraie résolution de
# l'identifiant (numéro de sociétaire ou e-mail), sans le flux du navigateur.
connexion() {
  curl -fsS -o /dev/null -d client_id=admin-cli -d grant_type=password \
    --data-urlencode "username=$1" -d password=demo \
    "$kc/realms/claimflow/protocol/openid-connect/token"
}

realm=$(admin "")
[ "$(jq -r .browserFlow <<<"$realm")" = "navigateur claimflow" ] || echec "flux de connexion non lié au realm"
[ "$(jq -r .registrationAllowed <<<"$realm")" = "false" ] || echec "inscription libre ouverte"

[ "$(admin "/users?username=10004821&exact=true" | jq -r '.[0].id')" = "5b1f2c3d-0001-4a00-8000-00000000c1a1" ] \
  || echec "Claire n'a pas l'identifiant attendu par le jeu de démonstration de l'API"

connexion 10004821 || echec "connexion par numéro de sociétaire refusée"
connexion claire.martin@exemple.fr || echec "connexion par e-mail refusée"

for role in GESTIONNAIRE EXPERT RESPONSABLE ADMIN; do
  admin "/roles/$role/composites/realm" | jq -e 'any(.[]; .name == "PERSONNEL")' >/dev/null \
    || echec "$role n'impose pas le second facteur"
done
admin "/roles/ASSURE" | jq -e '.composite == false' >/dev/null \
  || echec "ASSURE ne doit pas imposer le second facteur"

echo "Realm conforme : connexion par numéro ou e-mail, second facteur du personnel, comptes de démonstration."
