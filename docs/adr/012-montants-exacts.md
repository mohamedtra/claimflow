# ADR-012 · Montants exacts

- **Statut :** acceptée
- **Date :** 30/09/2026

## Contexte

RG-05 : indemnité au centime près, jamais négative.

## Décision

Value object `Montant` immuable sur `BigDecimal`. Les calculs se font en précision complète, avec un seul arrondi final au centime (HALF_UP). En base : `numeric(12,2)`. En JSON, le montant est transmis sous forme de chaîne (`"3876.00"`) pour que le JavaScript ne le convertisse jamais en flottant.

## Options écartées

`double` : erreurs d'arrondi (0,1 + 0,2 ≠ 0,3). Entier en centimes : exact, mais moins lisible et peu pratique pour appliquer des taux de vétusté.

## Conséquences

La SPA formate les montants avec `Intl.NumberFormat` sans calculer dessus : tout calcul reste côté serveur.
