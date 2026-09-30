import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'

// En local, les appels /api partent vers l'API. À partir du sprint 1, ils passeront par le BFF
// (ADR-003) : seule la cible du proxy changera, jamais le code de la SPA.
export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:8080',
      '/actuator': 'http://localhost:8080',
    },
  },
  test: {
    environment: 'jsdom',
  },
})
