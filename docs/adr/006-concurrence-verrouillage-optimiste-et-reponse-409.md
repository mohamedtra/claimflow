# ADR-006 · Concurrence : verrouillage optimiste et réponse 409

- **Statut :** acceptée
- **Date :** 30/09/2026

## Contexte

Deux personnes peuvent modifier le même dossier (RG-13). Les conflits sont rares mais leurs conséquences sont graves : un montant écrasé sans que personne ne le sache.

## Décision

Colonne `version` gérée par `@Version`. Chaque commande transporte la version lue par le client. En cas d'écart, l'API répond 409 avec un Problem Details qui donne la version actuelle, et l'interface affiche la différence (maquette, écran 09).

## Options écartées

Verrou pessimiste (`SELECT … FOR UPDATE`) : bloque des utilisateurs pour des conflits rares et impose des délais d'attente. Le dernier qui écrit gagne : perte silencieuse de données. `If-Match` + 412 : plus canonique en HTTP, envisageable plus tard puisque l'ETag sera exposé en lecture.

## Conséquences

Le client doit toujours renvoyer la version. Les tests d'intégration couvrent deux mises à jour concurrentes.
