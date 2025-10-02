<template>
  <div class="h-screen flex items-center justify-center bg-zinc-900 px-4">
    <div
      class="w-full max-w-md rounded-3xl p-10 bg-zinc-800 shadow-xl"
      role="main"
      aria-label="Recuperação de senha"
    >
      <header class="mb-8 text-center">
        <h1 class="text-3xl font-extrabold text-white mb-2">Recuperar Senha</h1>
        <p class="text-gray-300 text-sm">
          Informe seu email para receber instruções de recuperação
        </p>
      </header>

      <form @submit.prevent="handleForgotPassword" class="space-y-6" novalidate>
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

        <div class="flex gap-2">
          <button type="submit" class="form-button">
            <Send class="w-5 h-5" />
            <span>Enviar Instruções</span>
          </button>
        </div>
      </form>

      <p class="mt-6 text-center text-zinc-400 text-sm">
        Lembrou da senha?
        <RouterLink to="/login" class="text-zinc-300 text-sm underline hover:text-primary-500">
          Faça login
        </RouterLink>
      </p>
    </div>
  </div>
</template>

<script setup>
import { reactive } from 'vue'
import { useRouter } from 'vue-router'
import { Send } from 'lucide-vue-next'
import { useToastStore } from '@/stores/toast'
import { requestPasswordResetUser } from '@/services/http';

const router = useRouter()
const toast = useToastStore()

// Form data
const form = reactive({
  email: '',
})

// Handle forgot password form submission
const handleForgotPassword = async () => {
  try {
    // Call forgot password service
    await requestPasswordResetUser(form.email)

    // Show success message
    toast.success('Instruções enviadas para seu email!')

    // Redirect to login after 2 seconds
    setTimeout(() => {
      router.push('/login')
    }, 2000)
  } catch (error) {
    // Error handling is automatic through HTTP interceptor
    console.error('Failed to send recovery instructions:', error)
  }
}
</script>