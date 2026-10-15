#!/bin/bash
# Comptes de démonstration fictifs : local et dev uniquement, jamais en rct ni en prod.
# Importés avec leurs identifiants fixes, que le jeu de démonstration de l'API reprend
# (assure.utilisateur_id = sub). keycloak-config-cli crée les utilisateurs par l'API
# d'administration, qui ignore l'identifiant fourni : d'où cet import partiel, qui le garde.
# Un compte qui existe déjà n'est pas modifié.
set -euo pipefail

kcadm=/opt/keycloak/bin/kcadm.sh
config=/tmp/kcadm.config

"$kcadm" config credentials --config "$config" --server "$KEYCLOAK_URL" --realm master \
  --user "$KEYCLOAK_USER" --password "$KEYCLOAK_PASSWORD"
"$kcadm" create partialImport --config "$config" -r claimflow \
  -s ifResourceExists=SKIP -f /demo/utilisateurs.json -o
