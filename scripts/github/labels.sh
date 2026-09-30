#!/usr/bin/env bash
# Crée les étiquettes du projet (types, priorités, releases, epics). Idempotent.
# Usage : scripts/github/labels.sh OWNER/claimflow
set -euo pipefail

depot="${1:?Usage : $0 OWNER/depot}"

etiquette() {
  gh label create "$1" --repo "$depot" --color "$2" --description "$3" --force >/dev/null
  echo "  $1"
}

echo "Types"
etiquette "type:us"          "0F6B7A" "User story"
etiquette "type:enabler"     "52646D" "Travail technique sans utilisateur direct"
etiquette "type:bug"         "B42318" "Anomalie"
etiquette "type:spike"       "5B3CB0" "Étude limitée dans le temps"
etiquette "type:dependances" "94A3AB" "Mise à jour de dépendances (Renovate)"

echo "Priorités"
etiquette "priorite:must"   "0B4F5C" "Indispensable au MVP"
etiquette "priorite:should" "178A9A" "Important, pas bloquant"
etiquette "priorite:could"  "B6DDE2" "Souhaitable, après le MVP"

echo "Releases"
for release in R0 R1 R2 R3 R4 RX; do
  etiquette "release:$release" "E09A12" "Release $release"
done

echo "Epics"
while IFS=';' read -r id nom; do
  etiquette "epic:$id" "EFF8F9" "$nom"
done <<'LISTE'
EP-01;Socle et chaîne de livraison
EP-02;Identité et accès
EP-03;Espace assuré et déclaration
EP-04;Instruction du dossier
EP-05;Pièces justificatives
EP-06;Expertise
EP-07;Indemnisation et offre
EP-08;Audit et traçabilité
EP-09;Notifications
EP-10;Pilotage
EP-11;Paramétrage
EP-12;Performance et observabilité
EP-13;Environnements et exploitation
EP-14;Détection de fraude
LISTE
