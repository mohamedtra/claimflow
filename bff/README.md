# BFF (Backend for Frontend)

Seul point d'entrée du navigateur (ADR-003). Spring Cloud Gateway Server MVC, connexion OIDC
auprès de Keycloak (code + PKCE), jetons en session serveur (Spring Session JDBC, base `bff`),
relais du jeton vers l'API. Le navigateur ne reçoit qu'un cookie HttpOnly `CLAIMFLOW_SESSION`.

| Chemin | Rôle |
|---|---|
| `GET /oauth2/authorization/keycloak` | Démarre la connexion (redirection vers Keycloak) |
| `GET /bff/utilisateur` | `{id, nom, email, roles}` ; 401 sans session ; pose le cookie `XSRF-TOKEN` |
| `POST /bff/deconnexion` | En-tête `X-XSRF-TOKEN` requis ; 202 + `Location` (sortie Keycloak) |
| `/api/**` | Relayé vers l'API avec `Authorization: Bearer` ; cookie retiré |

Ces points sont techniques et ne figurent pas dans `docs/openapi/claimflow.yaml`.

En local : `make up`, `make api`, puis `make bff` (port 8081).
