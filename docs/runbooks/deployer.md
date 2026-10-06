# Déployer ClaimFlow

Le build est automatique : chaque fusion sur main publie l'image du composant modifié. Le déploiement
est manuel, composant par composant et environnement par environnement (ADR-014).

## Où

GitHub → **Actions** → **Deploy backend** (l'API) ou **Deploy frontend** (la SPA) → **Run workflow**.
Deux choix :

- **Use workflow from** : la référence à déployer (main ou un tag) ;
- **Environnement cible** : dev, rct ou prod.

## Les trois environnements

| Pour déployer en | Choisir comme référence | Ce qui se passe |
|---|---|---|
| **dev** | `main` | La dernière version du composant sur main est déployée, sans approbation. |
| **rct** | un tag `vX.Y.Z-rc.N` | La version candidate est déployée pour la recette (section 3.12 du dossier). |
| **prod** | un tag `vX.Y.Z` | Refusé si l'image n'est pas exactement celle qui est en rct. Sinon, GitHub attend votre approbation. |

Toute autre combinaison est refusée avec un message qui explique pourquoi.

## Livrer une version, de bout en bout

```bash
# 1. Version candidate, posée sur le commit de main à livrer
git tag v0.2.0-rc.1 && git push origin v0.2.0-rc.1
#    → Deploy backend puis Deploy frontend, depuis v0.2.0-rc.1, vers rct
#    → recette, procès-verbal docs/recette/v0.2.0.md

# 2. Recette validée : version finale, sur le même commit
git tag v0.2.0 v0.2.0-rc.1^{} && git push origin v0.2.0
#    → Deploy backend puis Deploy frontend, depuis v0.2.0, vers prod → approuver
```

## Ordre de déploiement

Le backend et le frontend se déploient indépendamment. Quand une version modifie le contrat d'API,
déployer **le backend d'abord** : le contrat ne change que de façon compatible (oasdiff le vérifie),
donc l'ancienne SPA fonctionne avec la nouvelle API, mais pas l'inverse.

## Revenir en arrière

Relancer le déploiement de l'environnement depuis la référence précédente (le tag de la version
d'avant). Rien n'est reconstruit : l'image de cette version existe déjà dans le registre.

## Tant que les environnements AWS n'existent pas

Le déploiement vérifie les règles, retrouve l'image et la promeut (étiquettes `dev`, `rct`, `prod` et
numéro de version dans le registre GitHub), puis s'arrête avec un message. Le déploiement réel sera
branché avec EN-08 (dev), EN-09 (rct) et EN-12 (prod).
