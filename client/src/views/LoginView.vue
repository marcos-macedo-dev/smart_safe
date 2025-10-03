<template>
  <div class="h-screen flex items-center justify-center bg-zinc-900 px-4">
    <div class="w-full max-w-md rounded-3xl p-10 bg-zinc-800 shadow-xl">
      <header class="mb-8 text-center">
        <h1 class="text-3xl font-extrabold text-white mb-2">Smart Safe</h1>
        <p class="text-gray-300 text-sm">Sistema de gerenciamento de segurança</p>
      </header>

      <form @submit.prevent="handleLogin" class="space-y-6" novalidate>
        <div>
          <label for="email" class="form-label">Email</label>
          <input
            id="email"
            v-model="form.email"
            type="email"
            required
            placeholder="Digite seu email"
            autocomplete="email"
            class="form-input"
          />
        </div>

        <div class="flex items-center justify-between m-0">
          <label for="senha" class="form-label">Senha</label>
          <RouterLink
            to="/forgot-password"
            class="text-gray-300 text-sm underline hover:text-primary-500"
            >Esqueceu a senha?</RouterLink
          >
        </div>

        <div>
          <input
            id="senha"
            v-model="form.senha"
            type="password"
            required
            placeholder="Digite sua senha"
            autocomplete="current-password"
            class="form-input"
          />
        </div>

        <button type="submit" class="form-button">
          <LogIn class="w-5 h-5" />
          <span>Entrar</span>
        </button>
      </form>

      <p class="mt-6 text-center text-gray-400 text-sm">
        &copy; {{ new Date().getFullYear() }} Smart Safe. Todos os direitos reservados.
      </p>
    </div>
  </div>
</template>

<script setup>
import { reactive } from 'vue'
import { useRouter } from 'vue-router'
import { LogIn } from 'lucide-vue-next'
import { login } from '@/services/http'
import { useToastStore } from '@/stores/toast'

const router = useRouter()
const toast = useToastStore()

// Form data
const form = reactive({
  email: '',
  senha: '',
})

// Handle login form submission
const handleLogin = async () => {
  try {
    // Attempt to login with provided credentials
    await login({ email: form.email, senha: form.senha })

    // Show success message and redirect to dashboard
    toast.success('Login realizado com sucesso!')
    router.push('/dashboard')
  } catch (error) {
    // Error handling is automatic through HTTP interceptor
    // No need to manually handle the error here
    console.error('Login failed:', error)
  }
}
</script>
