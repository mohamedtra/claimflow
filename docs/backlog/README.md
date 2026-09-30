# Backlog

`backlog.csv` est la source du backlog initial (section 3.5 du dossier projet) : 43 éléments,
186 points pour le MVP et 5 points en « Could ». Une fois importé dans GitHub, le backlog vit dans
GitHub Projects ; ce fichier n'est plus modifié.

Import (une seule fois, après `scripts/github/labels.sh`) :

```bash
scripts/github/importer-backlog.sh OWNER/claimflow <numéro-du-projet>
```

| Colonne | Contenu |
|---|---|
| `id` | US-xx (user story) ou EN-xx (enabler) |
| `epic` | EP-01 à EP-14 |
| `priorite` | Must, Should, Could |
| `points` | estimation en points (suite de Fibonacci) |
| `reference` | écran de la maquette ou règle de gestion |
| `release` | R0 à R4, RX après la release 4 |
