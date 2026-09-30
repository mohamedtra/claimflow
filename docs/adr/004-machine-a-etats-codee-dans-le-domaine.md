# ADR-004 · Machine à états codée dans le domaine

- **Statut :** acceptée
- **Date :** 30/09/2026

## Contexte

12 statuts et 19 transitions, chacune avec un rôle autorisé et une garde métier (RG-04, RG-06, RG-10).

## Décision

Un enum `Statut` décrit les transitions possibles. L'agrégat `Sinistre` expose une méthode par commande métier, qui vérifie la garde puis appelle `passerA()`. Aucun setter de statut n'existe.

## Options écartées

Spring Statemachine : puissant, mais ses concepts (persistance de la machine, configuration séparée) dispersent les règles hors du domaine et alourdissent les tests. Un simple champ modifiable : c'est la cause classique des dossiers dans des états impossibles.

## Conséquences

Les règles se lisent dans un seul fichier et se testent par des tests paramétrés, sans Spring. Chaque transition publie un événement que l'audit enregistre.
