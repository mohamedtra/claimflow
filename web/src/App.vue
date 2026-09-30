<script setup lang="ts">
import { onMounted, ref } from 'vue'
import LogoClaimFlow from './composants/LogoClaimFlow.vue'

type EtatApi = 'verification' | 'disponible' | 'indisponible'

const etatApi = ref<EtatApi>('verification')

const libelles: Record<EtatApi, string> = {
  verification: 'Vérification en cours…',
  disponible: 'API disponible',
  indisponible: 'API injoignable : lancez « make api »',
}

onMounted(async () => {
  try {
    const reponse = await fetch('/actuator/health')
    const corps: { status?: string } = await reponse.json()
    etatApi.value = corps.status === 'UP' ? 'disponible' : 'indisponible'
  } catch {
    etatApi.value = 'indisponible'
  }
})
</script>

<template>
  <header class="entete">
    <LogoClaimFlow />
  </header>
  <main class="contenu">
    <p class="surtitre">
      Sprint 0 · socle technique
    </p>
    <h1>Le socle ClaimFlow est en place</h1>
    <p class="intro">
      Les écrans de l'assuré et du gestionnaire arrivent à partir du sprint 1, avec la connexion par le BFF.
    </p>
    <section
      class="carte"
      aria-live="polite"
    >
      <span
        class="pastille"
        :class="etatApi"
        aria-hidden="true"
      />
      <span data-test="etat-api">{{ libelles[etatApi] }}</span>
    </section>
  </main>
</template>

<style scoped>
.entete {
  height: 64px;
  display: flex;
  align-items: center;
  padding-inline: 24px;
  background: var(--white);
  border-bottom: 1px solid var(--n-200);
}
.contenu {
  max-width: 720px;
  margin: 0 auto;
  padding: 48px 24px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.surtitre {
  margin: 0;
  font-family: var(--f-display);
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--brand-600);
}
h1 {
  margin: 0;
  font-family: var(--f-display);
  font-size: 28px;
  text-wrap: balance;
}
.intro {
  margin: 0;
  color: var(--n-600);
}
.carte {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 12px;
  padding: 16px 20px;
  background: var(--white);
  border: 1px solid var(--n-200);
  border-radius: var(--r-lg);
  box-shadow: var(--sh-1);
}
.pastille {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: var(--n-300);
}
.pastille.disponible {
  background: var(--success);
}
.pastille.indisponible {
  background: var(--danger);
}
</style>
