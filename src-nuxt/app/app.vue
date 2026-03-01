<script setup lang="ts">
import { ref } from 'vue'
import { invoke } from '@tauri-apps/api/core'

const message = ref('')
const echoResult = ref('')

async function callEcho() {
  if (!message.value) return
  try {
    echoResult.value = await invoke('echo', { message: message.value })
  } catch (error) {
    console.error('Error calling echo:', error)
    echoResult.value = `Error: ${error}`
  }
}
</script>

<template>
  <div class="app-container">
    <div class="content">
      <header class="header">
        <h1 class="title">Tauri + Nuxt</h1>
        <p class="subtitle">Desktop apps with web technologies</p>
      </header>

      <main class="main">
        <div class="demo-card">
          <h2 class="demo-title">Echo Command</h2>
          <form class="input-form" @submit.prevent="callEcho">
            <input
              v-model="message"
              type="text"
              placeholder="Enter a message to echo"
              class="input-field"
            >
            <button type="submit" class="echo-button">Echo</button>
          </form>
          <div v-if="echoResult" class="result">
            {{ echoResult }}
          </div>
        </div>
      </main>

      <footer class="footer">
        <p>Built with Tauri 2, Nuxt, and TypeScript</p>
      </footer>
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

.header {
  text-align: center;
  padding: 2rem 0;
}

.title {
  font-size: 2.5rem;
  margin: 0 0 0.5rem;
  background: linear-gradient(45deg, #fff, #a8edea);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  font-weight: bold;
}

.subtitle {
  color: rgba(255, 255, 255, 0.8);
  font-size: 1.1rem;
  margin: 0;
}

.main {
  margin: 2rem 0;
}

.demo-card {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border-radius: 12px;
  padding: 2rem;
  border: 1px solid rgba(255, 255, 255, 0.2);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
}

.demo-title {
  margin-top: 0;
  font-size: 1.5rem;
  color: #fff;
  margin-bottom: 1.5rem;
}

.input-form {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.input-field {
  flex: 1;
  padding: 0.75rem;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-radius: 8px;
  font-size: 1rem;
  background: rgba(255, 255, 255, 0.9);
  color: #333;
  transition:
    border-color 0.3s,
    background 0.3s;
}

.input-field:focus {
  outline: none;
  border-color: #a8edea;
  background: #fff;
}

.echo-button {
  padding: 0.75rem 1.5rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition:
    transform 0.2s,
    box-shadow 0.2s;
}

.echo-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}

.echo-button:active {
  transform: translateY(0);
}

.result {
  padding: 1rem;
  background: rgba(255, 255, 255, 0.95);
  color: #333;
  border-radius: 8px;
  margin-top: 1rem;
  font-weight: 500;
  border-left: 4px solid #667eea;
  animation: slideIn 0.3s ease-out;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.footer {
  text-align: center;
  padding: 2rem;
  color: rgba(255, 255, 255, 0.7);
  font-size: 0.9rem;
}

.footer p {
  margin: 0;
}
</style>

<style>
html,
body {
  overscroll-behavior: none;
}
</style>
