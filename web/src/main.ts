import { bootstrapApplication } from '@angular/platform-browser';
import { Racine } from './app/app';
import { appConfig } from './app/app.config';

// Retour arrière après la déconnexion : le navigateur peut réafficher la page depuis son cache
// (bfcache) sans rien demander au serveur. On recharge, ce qui revérifie la session (US-01).
window.addEventListener('pageshow', (evenement) => {
  if (evenement.persisted) {
    window.location.reload();
  }
});

bootstrapApplication(Racine, appConfig).catch((erreur: unknown) => console.error(erreur));
