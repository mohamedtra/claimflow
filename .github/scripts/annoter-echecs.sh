#!/usr/bin/env bash
# Transforme les erreurs d'un build Maven en annotations GitHub, visibles sur la pull request
# sans ouvrir les journaux. Usage : annoter-echecs.sh maven.log
set -uo pipefail

journal="${1:?Usage : $0 maven.log}"

# Une annotation regroupe plusieurs lignes (%0A) : GitHub limite le nombre d'annotations par étape.
annoter() {
  local titre="$1" contenu
  contenu="$(sed -e 's/%/%25/g' -e 's/\r//g' | awk '{printf "%s%%0A", $0}')"
  [ -n "$contenu" ] && echo "::error title=${titre}::${contenu}"
}

grep -E '^\[ERROR\]' "$journal" | grep -v -E '^\[ERROR\] *$' | head -60 | annoter "Maven"

for rapport in api/target/surefire-reports/*.txt api/target/failsafe-reports/*.txt; do
  [ -f "$rapport" ] || continue
  if grep -q -E 'FAILURE|ERROR' "$rapport"; then
    head -c 4000 "$rapport" | annoter "$(basename "$rapport" .txt)"
  fi
done
exit 0
