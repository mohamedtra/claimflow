import { Routes } from '@angular/router';
import { AccesRoute, gardeSession } from './session/garde';

// Écrans chargés à la demande : la page de connexion ne télécharge pas le code des espaces.
export const routes: Routes = [
  {
    path: 'connexion',
    title: 'Connexion · ClaimFlow',
    canActivate: [gardeSession],
    data: { publique: true } satisfies AccesRoute,
    loadComponent: () => import('./connexion/connexion').then((m) => m.ConnexionPage),
  },
  {
    path: 'collaborateur',
    title: 'Espace collaborateur · ClaimFlow',
    canActivate: [gardeSession],
    data: { personnel: true } satisfies AccesRoute,
    loadComponent: () => import('./espace-collaborateur/espace-collaborateur').then((m) => m.EspaceCollaborateur),
  },
  {
    path: '',
    canActivate: [gardeSession],
    data: { role: 'ASSURE' } satisfies AccesRoute,
    loadComponent: () => import('./espace-assure/espace-assure').then((m) => m.EspaceAssure),
    children: [
      {
        path: '',
        title: 'Accueil · ClaimFlow',
        loadComponent: () => import('./espace-assure/accueil').then((m) => m.AccueilPage),
      },
      {
        path: 'contrats',
        title: 'Mes contrats · ClaimFlow',
        loadComponent: () => import('./espace-assure/mes-contrats').then((m) => m.MesContratsPage),
      },
    ],
  },
  { path: '**', redirectTo: '' },
];
