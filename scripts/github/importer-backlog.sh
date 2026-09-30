#!/usr/bin/env bash
# Crée une issue par élément de docs/backlog/backlog.csv et l'ajoute au projet GitHub.
# Usage : scripts/github/importer-backlog.sh OWNER/claimflow NUMERO_DU_PROJET
# Prérequis : gh authentifié avec la portée « project » (gh auth refresh -s project),
#             étiquettes créées par scripts/github/labels.sh.
set -euo pipefail

depot="${1:?Usage : $0 OWNER/depot NUMERO_DU_PROJET}"
projet="${2:?Usage : $0 OWNER/depot NUMERO_DU_PROJET}"
proprietaire="${depot%%/*}"
fichier="$(dirname "$0")/../../docs/backlog/backlog.csv"

tail -n +2 "$fichier" | while IFS=';' read -r id epic recit priorite points reference release; do
  case "$id" in
    US-*) type="type:us" ;;
    *)    type="type:enabler" ;;
  esac
  priorite_min="$(tr '[:upper:]' '[:lower:]' <<<"$priorite")"
  corps="$(printf '%s\n\n**Estimation :** %s points\n**Référence :** %s\n\nCritères d'"'"'acceptation à rédiger en Gherkin lors de l'"'"'affinage (définition de « prêt »).' \
    "$recit" "$points" "$reference")"

  url="$(gh issue create --repo "$depot" \
    --title "$id · $recit" \
    --body "$corps" \
    --label "$type" --label "epic:$epic" --label "priorite:$priorite_min" --label "release:$release")"
  gh project item-add "$projet" --owner "$proprietaire" --url "$url" >/dev/null
  echo "$id  $url"
done
