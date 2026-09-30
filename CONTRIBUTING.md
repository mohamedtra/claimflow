# Contribuer à ClaimFlow

## Branches

- `main` est protégée et toujours déployable.
- Une branche courte par US ou anomalie : `feat/US-05-declaration`, `fix/BUG-03-arrondi`.
- Fusion par pull request uniquement, contrôles verts exigés, fusion « squash », historique linéaire.

## Messages de commit

[Conventional Commits](https://www.conventionalcommits.org/fr/), vérifiés par commitlint.

```
<type>(<module>): <résumé à l'impératif, en minuscules>

<pourquoi, si ce n'est pas évident>

Refs: US-05
```

| Type | Usage |
|---|---|
| `feat` | nouvelle fonctionnalité |
| `fix` | correction d'anomalie |
| `refactor` | restructuration sans changement de comportement |
| `test` | ajout ou correction de tests |
| `docs` | documentation, ADR |
| `build` | Maven, npm, Docker |
| `ci` | GitHub Actions |
| `chore` | maintenance |

Portées usuelles : `sinistre`, `contrat`, `document`, `expertise`, `indemnisation`, `audit`,
`notification`, `pilotage`, `parametrage`, `shared`, `api`, `web`, `bff`, `infra`, `openapi`, `repo`.

## Versions

SemVer. `vX.Y.Z-rc.N` déclenche la recette, `vX.Y.Z` la mise en production.

## Définition de « terminé »

Une US est terminée quand :

1. le code est fusionné par pull request, avec tous les contrôles au vert ;
2. ses critères d'acceptation sont automatisés (test d'intégration ou E2E) ;
3. la couverture du code nouveau atteint 80 % et le quality gate Sonar est vert ;
4. le contrat OpenAPI et, si besoin, un ADR sont à jour ;
5. les actions métier apparaissent dans le journal d'audit ;
6. elle est déployée (en local jusqu'à la release 2, puis en dev) et vérifiée par le PO ;
7. aucune vulnérabilité critique ou haute n'a été introduite.

## Code produit avec l'IA

Autorisé et assumé, aux conditions de [`AGENTS.md`](AGENTS.md) : chaque ligne est relue et
comprise, couverte par un test, et respecte les ADR.
