# ADR-010 · Journal d'audit en ajout seul et chaîné

- **Statut :** acceptée
- **Date :** 30/09/2026

## Contexte

RG-11 : toute action est tracée, le journal n'est jamais modifié ni supprimé. Un contrôle interne ou la CNIL doit pouvoir s'y fier.

## Décision

Table en ajout seul : trigger qui refuse UPDATE et DELETE, droits retirés au compte applicatif. Chaque entrée contient le hachage de la précédente, donc une modification directe en base est détectable. Les écritures sont sérialisées par un verrou consultatif (`pg_advisory_xact_lock`) pour garder une chaîne linéaire. On y stocke des identifiants plutôt que des noms (RGPD).

## Options écartées

Hibernate Envers : historise des entités et non des actions métier, et ses tables restent modifiables. Logs applicatifs : non structurés et sans garantie de conservation.

## Conséquences

Le verrou sérialise les écritures d'audit : le coût sera mesuré à l'étape 7. Un superutilisateur peut toujours contourner le trigger, mais le chaînage révèle l'altération. En production, un export vers S3 Object Lock complétera le dispositif.
