import { provideHttpClient, withInterceptors, withXsrfConfiguration } from '@angular/common/http';
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { provideApiConfiguration } from './api/api-configuration';
import { routes } from './app.routes';
import { intercepteurSessionExpiree } from './session/intercepteur';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    // Les paramètres d'adresse (?expiree=1…) arrivent en entrées des composants.
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(
      withInterceptors([intercepteurSessionExpiree]),
      // Noms du BFF (Spring Security, csrf.spa()) : HttpClient lit le cookie et renvoie l'en-tête
      // sur chaque requête qui modifie (POST, PUT, DELETE…). Ce sont aussi les valeurs par défaut.
      withXsrfConfiguration({ cookieName: 'XSRF-TOKEN', headerName: 'X-XSRF-TOKEN' }),
    ),
    // Même origine : le BFF relaie /api vers l'API (ADR-003). Sans cette ligne, le client généré
    // appellerait l'adresse du contrat OpenAPI (http://localhost:8080).
    provideApiConfiguration(''),
  ],
};
