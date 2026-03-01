// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  telemetry: false,
  compatibilityDate: '2024-11-01',
  css: [
    '~/assets/css/no-bounce.css', // Gets rid of the annoying bounce effect on the page, makes it more app liek
    '~/assets/css/main.css',
  ],
  devtools: { enabled: true },
  ssr: false,
  devServer: {
    port: 1420,
    host: 'localhost',
  },
  modules: [
    '@nuxt/content',
    '@nuxt/eslint',
    '@nuxt/fonts',
    '@nuxt/icon',
    '@nuxt/scripts',
    '@nuxt/test-utils',
    '@nuxt/ui',
  ],
})
