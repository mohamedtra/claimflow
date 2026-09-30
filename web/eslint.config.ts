import pluginVue from 'eslint-plugin-vue'
import { defineConfigWithVueTs, vueTsConfigs } from '@vue/eslint-config-typescript'

export default defineConfigWithVueTs(
  { name: 'claimflow/fichiers', files: ['**/*.{ts,mts,vue}'] },
  { name: 'claimflow/ignores', ignores: ['dist/**', 'coverage/**', 'src/api/schema.d.ts'] },
  pluginVue.configs['flat/recommended'],
  vueTsConfigs.recommended,
  {
    name: 'claimflow/regles',
    rules: {
      // ADR-003 : aucun jeton dans le stockage du navigateur.
      'no-restricted-globals': [
        'error',
        { name: 'localStorage', message: 'Interdit pour les jetons (ADR-003). Utiliser le BFF.' },
        { name: 'sessionStorage', message: 'Interdit pour les jetons (ADR-003). Utiliser le BFF.' },
      ],
    },
  },
)
