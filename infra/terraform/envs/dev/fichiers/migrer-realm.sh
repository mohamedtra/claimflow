#!/bin/bash
# Exécuté une seule fois par deployer.sh, dans un conteneur Keycloak (kcadm), au passage du realm à
# keycloak-config-cli (ADR-016, étape 6 du sprint 1). Le realm « claimflow » importé autrefois au
# démarrage est supprimé : keycloak-config le recrée aussitôt à partir de infra/keycloak/realm, puis
# keycloak-demo réimporte les comptes de démonstration avec leurs identifiants fixes. Ne concerne
# que le realm claimflow, jamais master. Sans realm existant (instance neuve), ne fait rien.
set -euo pipefail

kcadm=/opt/keycloak/bin/kcadm.sh
config=/tmp/kcadm.config

"$kcadm" config credentials --config "$config" --server http://keycloak:8080/auth --realm master \
  --user admin --password "$KEYCLOAK_PASSWORD"

if "$kcadm" get realms/claimflow --config "$config" --fields realm >/dev/null 2>&1; then
  "$kcadm" delete realms/claimflow --config "$config"
  echo "[migrer-realm] realm claimflow supprimé ; keycloak-config va le recréer"
else
  echo "[migrer-realm] aucun realm claimflow à supprimer"
fi
