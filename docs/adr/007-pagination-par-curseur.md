# ADR-007 · Pagination par curseur

- **Statut :** acceptée
- **Date :** 30/09/2026

## Contexte

Les listes portent sur un million de dossiers et doivent répondre en moins de 300 ms au 95ᵉ centile.

## Décision

Pagination par curseur (keyset) : `WHERE (declare_le, id) < (:d, :id) ORDER BY declare_le DESC, id DESC LIMIT 50`, avec un curseur opaque renvoyé au client. Côté Spring Data, on utilise l'API `Window` / `ScrollPosition`.

## Options écartées

OFFSET : le coût croît avec la profondeur, car PostgreSQL lit puis jette toutes les lignes précédentes. `Page` de Spring Data : exécute un COUNT à chaque requête.

## Conséquences

Temps de réponse stable quelle que soit la page. Plus de saut direct à la page 37, et le tri est limité aux colonnes indexées. Le nombre total, si besoin, est une estimation.
