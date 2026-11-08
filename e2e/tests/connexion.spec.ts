import { expect, Page, test } from '@playwright/test';

// Compte de démonstration fictif (infra/keycloak/demo) : local et dev seulement, jamais rct ni prod.
const CLAIRE = { identifiant: '10004821', motDePasse: 'demo' };

async function capturer(page: Page, nom: string): Promise<void> {
  await page.screenshot({ path: `captures/${nom}.png`, fullPage: true });
}

async function seConnecterChezKeycloak(page: Page, identifiant: string, motDePasse: string): Promise<void> {
  await expect(page).toHaveURL(/\/auth\/realms\/claimflow\//);
  await page.locator('#username').fill(identifiant);
  await page.locator('#password').fill(motDePasse);
  await page.locator('#kc-login').click();
}

test('US-01, US-04 : Claire se connecte par son numéro de sociétaire, consulte ses contrats et se déconnecte', async ({ page }) => {
  // Sans session, la SPA envoie vers la connexion ; aucun champ d'identifiant n'y figure (ADR-003).
  await page.goto('/');
  await expect(page).toHaveURL(/\/connexion$/);
  await expect(page.locator('input')).toHaveCount(0);
  await capturer(page, '01-connexion');

  // Le bouton passe par le BFF, qui envoie vers Keycloak (code + PKCE).
  await page.getByTestId('se-connecter').click();
  await expect(page.locator('#username')).toBeVisible();
  await capturer(page, '02-keycloak');
  await seConnecterChezKeycloak(page, CLAIRE.identifiant, CLAIRE.motDePasse);

  // Retour dans la SPA, connectée : seul un cookie HttpOnly porte la session.
  await expect(page.getByTestId('salutation')).toHaveText('Bonjour Claire');
  await expect(page.getByTestId('nom-utilisateur')).toHaveText('Claire Martin');
  const cookies = await page.context().cookies();
  expect(cookies.find((cookie) => cookie.name === 'CLAIMFLOW_SESSION')).toMatchObject({ httpOnly: true, secure: true });
  expect(await page.evaluate(() => JSON.stringify({ ...window.localStorage }))).toBe('{}');
  await capturer(page, '03-accueil');

  // US-04 : contrats et garanties, relayés par le BFF vers l'API avec le jeton de la session.
  await page.getByRole('navigation').getByRole('link', { name: 'Mes contrats' }).click();
  await expect(page).toHaveURL(/\/contrats$/);
  await expect(page.getByTestId('contrat')).toHaveCount(2);
  await expect(page.getByText('HAB-3391027')).toBeVisible();
  await expect(page.getByText('AUTO-7712045')).toBeVisible();
  await expect(page.getByTestId('garantie').first()).toContainText('€');
  await capturer(page, '04-mes-contrats');

  // Déconnexion : session du BFF et session SSO de Keycloak fermées.
  await page.getByTestId('se-deconnecter').click();
  await expect(page).toHaveURL(/\/connexion/);
  await page.goto('/contrats');
  await expect(page).toHaveURL(/\/connexion/);
  await page.getByTestId('se-connecter').click();
  await expect(page.locator('#username')).toBeVisible();
  await capturer(page, '05-apres-deconnexion');
});

test('US-01 : l’API n’est pas joignable sans session', async ({ request }) => {
  const reponse = await request.get('/api/v1/contrats');
  expect(reponse.status()).toBe(401);
  expect(reponse.headers()['content-type']).toContain('application/problem+json');
});
