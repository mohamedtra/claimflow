# ADR-016 · Realm Keycloak en configuration as code

- **Statut :** acceptée
- **Date :** 14/10/2026
- **Complète :** ADR-002 ; décisions D1, D2, D3 du 14/10 (section 3.26 du dossier projet)

## Contexte

Keycloak démarrait avec `--import-realm`, qui n'importe le realm que s'il n'existe pas : toute
modification ultérieure du fichier était ignorée, sans erreur. Le secret du BFF et ses adresses
étaient écrits en dur. Le second facteur du personnel (D2) et la connexion par numéro de
sociétaire (D1) demandent un réglage fin du realm, qui doit être relu et rejouable.

## Décision

- Le realm est décrit dans `infra/keycloak/realm/claimflow.yaml` et appliqué par
  keycloak-config-cli à chaque démarrage : différence calculée, application rejouable, variables
  d'environnement obligatoires pour les adresses, le secret du BFF et l'envoi d'e-mails.
- Le second facteur est imposé par le flux de connexion, à tout titulaire du rôle marqueur
  `PERSONNEL`, inclus dans chaque rôle du personnel. Code à usage unique (TOTP) maintenant ;
  clés d'accès (WebAuthn) visées pour la production.
- Les comptes de démonstration sont à part (`infra/keycloak/demo`), importés par l'import partiel de
  Keycloak, qui conserve leur identifiant. Ils ne vont jamais en rct ni en prod.
- La CI applique le realm deux fois sur un Keycloak éphémère, puis le vérifie.

## Options écartées

- `--import-realm` seul : ne suit pas les modifications.
- Terraform (fournisseur Keycloak) : un état de plus à protéger, et Keycloak n'est pas joignable
  depuis la CI en dev (console fermée).
- Script maison sur l'API d'administration : à écrire et maintenir, sans calcul de différence.

## Conséquences

- Toute modification passe par une pull request ; un changement fait dans la console est écrasé
  au démarrage suivant.
- keycloak-config-cli 6.5.1 est publié par version de Keycloak (tag `6.5.1-26.5.5`) ; le projet est en
  26.7. L'API d'administration reste compatible au sein de la version 26, et la CI le vérifie à chaque
  changement. Renovate suivra les deux images.
- Le client `admin-cli` du realm accepte encore la connexion directe (utilisée par la vérification
  CI). Ses jetons ne portent pas l'audience de l'API, qui les refuse ; à fermer avant la production.
- Dev sur AWS passe à ce mécanisme à l'étape 6, avec la mise en ligne du BFF.
