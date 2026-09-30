# ADR-011 · Identifiants : UUID v7 et numéro métier lisible

- **Statut :** acceptée
- **Date :** 30/09/2026

## Contexte

Les identifiants apparaissent dans les URL. Les assurés et les gestionnaires ont besoin d'un numéro qu'ils peuvent dicter au téléphone.

## Décision

Clé technique en UUID v7, générée par l'application : ordonnée dans le temps (index B-tree compact, contrairement à l'UUID v4) et non devinable (contrairement à une séquence). Numéro métier `SIN-AAAA-NNNNNN` issu d'une séquence PostgreSQL, affiché partout mais jamais utilisé seul pour autoriser un accès.

## Options écartées

Séquence `bigint` exposée : permet d'énumérer les dossiers. UUID v4 : insertions dispersées dans l'index.

## Conséquences

Le caractère non devinable de l'UUID est une défense en profondeur, pas un contrôle d'accès : les règles de la section 2.9 s'appliquent toujours.
