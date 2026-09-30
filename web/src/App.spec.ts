import { afterEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import App from './App.vue'

afterEach(() => vi.unstubAllGlobals())

describe('App', () => {
  it('indique que l’API est disponible quand la sonde de santé répond UP', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ json: () => Promise.resolve({ status: 'UP' }) }))
    const page = mount(App)
    await flushPromises()
    expect(page.get('[data-test="etat-api"]').text()).toBe('API disponible')
  })

  it('explique quoi faire quand l’API est injoignable', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('connexion refusée')))
    const page = mount(App)
    await flushPromises()
    expect(page.get('[data-test="etat-api"]').text()).toContain('make api')
  })
})
