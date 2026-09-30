# ADR-009 · Communication entre modules : appel direct ou événement

- **Statut :** acceptée
- **Date :** 30/09/2026

## Contexte

Certaines actions doivent être cohérentes dans une seule transaction (déposer le rapport ET faire évoluer le dossier). D'autres sont des effets de bord (e-mail, statistiques) qui ne doivent pas bloquer l'utilisateur.

## Décision

Appel direct à l'API publique du module quand la cohérence est requise. Événement applicatif pour le reste. L'audit écoute de façon synchrone, dans la transaction : pas d'action sans trace. Notification et pilotage écoutent après le commit (`@ApplicationModuleListener`). Le registre de publication de Spring Modulith, en base, joue le rôle d'outbox et rejoue les événements non traités au redémarrage.

## Options écartées

Kafka ou RabbitMQ : une infrastructure de plus pour un seul processus. `@TransactionalEventListener` sans registre : un événement est perdu si l'application s'arrête juste après le commit.

## Conséquences

Livraison « au moins une fois » : les consommateurs sont idempotents (identifiant d'événement unique). L'externalisation vers SQS reste possible sans réécrire les modules.
