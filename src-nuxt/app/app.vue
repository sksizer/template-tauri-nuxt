<script setup lang="ts">
import { invoke } from '@tauri-apps/api/core'
import AppHeader from './components/AppHeader.vue'
import EchoCard from './components/EchoCard.vue'
import AppFooter from './components/AppFooter.vue'

async function tauriEcho(message: string): Promise<string> {
  return await invoke('echo', { message })
}
</script>

<template>
  <div class="app-container">
    <div class="content">
      <AppHeader title="Tauri + Nuxt" subtitle="Desktop apps with web technologies" />
      <main class="main">
        <EchoCard :invoker="tauriEcho" />
      </main>
      <AppFooter text="Built with Tauri 2, Nuxt, and TypeScript" />
    </div>
  </div>
</template>

<style scoped>
.app-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  font-family:
    system-ui,
    -apple-system,
    sans-serif;
}

.content {
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
}

.main {
  margin: 2rem 0;
}
</style>

<style>
html,
body {
  overscroll-behavior: none;
}
</style>
