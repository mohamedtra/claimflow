#!/usr/bin/env bash
# Applique les réglages du dépôt que seul son propriétaire peut modifier :
# options de fusion, sujets, analyse des secrets, environnements dev/rct/prod, protection de main.
# Idempotent : peut être relancé sans risque.
#
# Usage (depuis la racine du dépôt, avec GitHub CLI authentifié) :
#   scripts/github/configurer-parametres.sh mohamedtra/claimflow
set -euo pipefail

depot="${1:?Usage : $0 OWNER/depot}"
racine="$(cd "$(dirname "$0")/../.." && pwd)"

etape() { printf '\n▸ %s\n' "$1"; }

etape "Options du dépôt"
gh repo edit "$depot" \
  --description "Gestion des sinistres d'assurance : Java 25, Spring Boot 4, Spring Modulith, PostgreSQL, Vue 3. Projet de démonstration de bout en bout." \
  --enable-issues --enable-projects --enable-wiki=false \
  --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false \
  --delete-branch-on-merge --enable-auto-merge \
  --add-topic java,spring-boot,spring-modulith,spring-security,postgresql,vuejs,typescript \
  --add-topic keycloak,openapi,ddd,insurance,claims-management
gh api --method PATCH "repos/$depot" \
  -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY >/dev/null
echo "  fusion squash uniquement, branches supprimées après fusion, sujets"

etape "Sécurité"
gh api --method PATCH "repos/$depot" --input - >/dev/null <<'JSON'
{"security_and_analysis": {"secret_scanning": {"status": "enabled"},
                           "secret_scanning_push_protection": {"status": "enabled"}}}
JSON
gh api --method PUT "repos/$depot/vulnerability-alerts" >/dev/null
echo "  détection des secrets avec blocage au push, alertes de vulnérabilités"

etape "Environnements"
moi="$(gh api user --jq .id)"
gh api --method PUT "repos/$depot/environments/dev" --input - >/dev/null <<'JSON'
{"deployment_branch_policy": {"protected_branches": true, "custom_branch_policies": false}}
JSON
gh api --method PUT "repos/$depot/environments/rct" --input - >/dev/null <<'JSON'
{"deployment_branch_policy": {"protected_branches": false, "custom_branch_policies": true}}
JSON
gh api --method PUT "repos/$depot/environments/prod" --input - >/dev/null <<JSON
{"reviewers": [{"type": "User", "id": $moi}], "prevent_self_review": false, "wait_timer": 0,
 "deployment_branch_policy": {"protected_branches": false, "custom_branch_policies": true}}
JSON
politique() {
  local env="$1" motif="$2"
  if ! gh api "repos/$depot/environments/$env/deployment-branch-policies" --jq '.branch_policies[].name' \
       | grep -qxF "$motif"; then
    gh api --method POST "repos/$depot/environments/$env/deployment-branch-policies" \
      -f name="$motif" -f type=tag >/dev/null
  fi
}
politique rct 'v*-rc.*'
politique prod 'v[0-9]*.[0-9]*.[0-9]*'
for env in dev rct prod; do
  gh variable set ENVIRONNEMENT --repo "$depot" --env "$env" --body "$env"
done
echo "  dev : depuis main · rct : tags vX.Y.Z-rc.N · prod : tags vX.Y.Z, avec votre approbation"

etape "Protection de main"
existant="$(gh api "repos/$depot/rulesets" --jq '.[] | select(.name == "Protection de main") | .id')"
if [ -n "$existant" ]; then
  gh api --method PUT "repos/$depot/rulesets/$existant" --input "$racine/scripts/github/regles-main.json" >/dev/null
else
  gh api --method POST "repos/$depot/rulesets" --input "$racine/scripts/github/regles-main.json" >/dev/null
fi
echo "  pull request obligatoire, 7 contrôles de CI verts, fusion squash, pas de force-push"

printf '\nTerminé. Vérifiez sur https://github.com/%s/settings\n' "$depot"
