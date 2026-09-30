# ADR-008 · Pièces jointes : stockage objet, contrôle en entrée, URL présignée en sortie

- **Statut :** acceptée
- **Date :** 30/09/2026

## Contexte

Photos et PDF jusqu'à 10 Mo, données sensibles, fichiers potentiellement malveillants (RG-12).

## Décision

L'envoi passe par l'API, qui détecte le type réel (Apache Tika), vérifie la taille, calcule le SHA-256 et soumet le fichier à ClamAV avant de l'écrire dans MinIO en local ou S3 chiffré (SSE-KMS) en production. Les métadonnées sont en base. La lecture renvoie une URL présignée de 60 secondes, après contrôle d'accès et inscription au journal d'audit.

## Options écartées

Stockage en `bytea` : sauvegardes alourdies et mémoire applicative sollicitée. Envoi direct du navigateur vers S3 par URL présignée : le contenu non vérifié atterrit dans le stockage, sauf à gérer une zone de quarantaine.

## Conséquences

Deux stockages à garder cohérents : un traitement planifié supprime les fichiers orphelins. ClamAV demande environ 1 à 2 Go de mémoire, à budgéter sur AWS.

## Amendement du 01/10/2026

MinIO a cessé de publier ses images Docker communautaires en octobre 2025. En local, on utilise
l'image gratuite maintenue par Chainguard (`cgr.dev/chainguard/minio`), qui n'est publiée qu'avec
l'étiquette `latest`. Ce choix ne concerne que le poste de développement : en production, le
stockage est Amazon S3, et le code n'utilise que l'API S3.
