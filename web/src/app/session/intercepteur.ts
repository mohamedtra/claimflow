import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';
import { Session } from './session';

/**
 * Un 401 de l'API veut dire que la session du BFF n'existe plus ou n'a plus de jeton utilisable
 * (le BFF l'a fermée). On oublie l'utilisateur et on renvoie à la connexion, avec un message.
 * Les 401 de /bff/utilisateur ne sont pas concernés : ils signifient simplement « pas connecté ».
 */
export const intercepteurSessionExpiree: HttpInterceptorFn = (requete, suivant) => {
  const session = inject(Session);
  const routeur = inject(Router);
  return suivant(requete).pipe(
    catchError((erreur: unknown) => {
      if (erreur instanceof HttpErrorResponse && erreur.status === 401 && requete.url.startsWith('/api/')) {
        session.oublier();
        void routeur.navigate(['/connexion'], { queryParams: { expiree: 1 } });
      }
      return throwError(() => erreur);
    }),
  );
};
