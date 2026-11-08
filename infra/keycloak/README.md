# Keycloak : realm en configuration as code (ADR-016)

| Dossier | Contenu | Appliqué par |
|---|---|---|
| `realm/` | Réglages, rôles, flux de connexion, clients. Valeurs d'environnement en `$(env:…)` | keycloak-config-cli, à chaque démarrage |
| `demo/` | Comptes fictifs à identifiants fixes, mot de passe `demo` | Import partiel Keycloak ; local et dev seulement |

Modifier le realm = modifier `realm/claimflow.yaml` dans une pull request. Jamais par la console
d'administration : la prochaine application écraserait le changement.

Le personnel (rôle `PERSONNEL`, inclus dans GESTIONNAIRE, EXPERT, RESPONSABLE, ADMIN) doit saisir
un code à usage unique ; au premier passage, Keycloak fait configurer l'application d'authentification.

En dev sur AWS, le même realm est appliqué à chaque déploiement (`deployer.sh`), avec les adresses
de CloudFront et sans envoi d'e-mails ; les comptes de démonstration y sont importés aussi. L'ancien
import au démarrage (`claimflow-realm.json`) a été retiré à l'étape 6 du sprint 1.
