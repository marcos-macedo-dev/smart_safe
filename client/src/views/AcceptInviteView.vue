<template>
  <div class="h-screen flex items-center justify-center bg-zinc-900 px-4">
    <div class="w-full max-w-md rounded-3xl p-8 bg-zinc-800 shadow-xl">
      <header class="mb-6 text-center">
        <h1 class="text-2xl font-extrabold text-white mb-2">Aceitar Convite</h1>
        <p class="text-gray-300 text-sm">Crie sua senha para acessar o sistema</p>
      </header>

      <div v-if="inviteValid">
        <div class="bg-zinc-700 border border-zinc-600 rounded-lg p-4 mb-5">
          <h3 class="text-base font-bold text-white mb-3">Detalhes do Convite</h3>
          <div class="space-y-3">
            <div>
              <label class="block text-zinc-300 dark:text-zinc-400 text-xs font-medium mb-1"
                >Nome</label
              >
              <p class="text-white font-medium text-sm">{{ inviteData.user.nome }}</p>
            </div>
            <div>
              <label class="block text-zinc-300 dark:text-zinc-400 text-xs font-medium mb-1"
                >Email</label
              >
              <p class="text-white font-medium text-sm">{{ inviteData.user.email }}</p>
            </div>
            <div>
              <label class="block text-zinc-300 dark:text-zinc-400 text-xs font-medium mb-1"
                >Cargo</label
              >
              <p class="text-white font-medium text-sm">{{ inviteData.user.cargo }}</p>
            </div>
            <div>
              <label class="block text-zinc-300 dark:text-zinc-400 text-xs font-medium mb-1"
                >Delegacia</label
              >
              <p class="text-white font-medium text-sm">{{ inviteData.user.delegacia }}</p>
            </div>
          </div>
        </div>

        <form @submit.prevent="handleAcceptInvite" class="space-y-4">
          <div>
            <label for="password" class="form-label">Senha</label>
            <input
              id="password"
              v-model="password"
              type="password"
              required
              minlength="6"
              placeholder="Digite sua senha"
              class="form-input"
            />
            <div v-if="password" class="mt-1">
              <div class="w-full bg-zinc-600 rounded-full h-1.5">
                <div
                  class="h-1.5 rounded-full"
                  :class="getPasswordStrengthClass(passwordStrength)"
                  :style="{ width: passwordStrength + '%' }"
                ></div>
              </div>
              <p class="text-xs mt-1" :class="getPasswordStrengthTextColor(passwordStrength)">
                {{ getPasswordStrengthText(passwordStrength) }}
              </p>
            </div>
          </div>

          <div>
            <label for="confirmPassword" class="form-label">Confirmar Senha</label>
            <input
              id="confirmPassword"
              v-model="confirmPassword"
              type="password"
              required
              placeholder="Confirme sua senha"
              class="form-input"
            />
            <div
              v-if="confirmPassword && password !== confirmPassword"
              class="mt-1 text-red-400 text-xs"
            >
              As senhas não coincidem
            </div>
          </div>

          <div v-if="formError" class="bg-red-500/20 border border-red-500 rounded-md p-3">
            <p class="text-red-300 text-sm">{{ formError }}</p>
          </div>

          <button type="submit" :disabled="submitting || !isFormValid" class="form-button">
            <Check class="w-4 h-4" />
            <span>{{ submitting ? 'Aceitando...' : 'Aceitar Convite' }}</span>
          </button>
        </form>
      </div>

      <div v-else class="text-center py-8">
        <h3 class="text-base font-medium text-white mt-3">Convite Inválido</h3>
        <p class="text-gray-400 mt-1 text-xs">O link de convite é inválido ou expirou.</p>
        <div class="mt-5">
          <router-link to="/login" class="form-button-secondary">
            <LogIn class="w-4 h-4" />
            <span>Ir para Login</span>
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { LogIn, Check } from 'lucide-vue-next'
import { verifyInviteToken, acceptInvite as httpAcceptInvite } from '@/services/http'
import { useToastStore } from '@/stores/toast'

const route = useRoute()
const router = useRouter()
const toast = useToastStore()

const token = route.query.token

const submitting = ref(false)
const formError = ref(null)
const inviteValid = ref(false)
const inviteData = ref(null)

const password = ref('')
const confirmPassword = ref('')

// Funções para calcular a força da senha
const passwordStrength = computed(() => {
  const pass = password.value
  if (!pass) return 0

  let strength = 0
  if (pass.length >= 6) strength += 25
  if (pass.length >= 8) strength += 25
  if (/[A-Z]/.test(pass)) strength += 25
  if (/[0-9]/.test(pass)) strength += 25

  return Math.min(strength, 100)
})

const getPasswordStrengthClass = (strength) => {
  if (strength < 30) return 'bg-red-500'
  if (strength < 70) return 'bg-yellow-500'
  return 'bg-green-500'
}

const getPasswordStrengthTextColor = (strength) => {
  if (strength < 30) return 'text-red-500'
  if (strength < 70) return 'text-yellow-500'
  return 'text-green-500'
}

const getPasswordStrengthText = (strength) => {
  if (strength < 30) return 'Fraca'
  if (strength < 70) return 'Média'
  return 'Forte'
}

const isFormValid = computed(() => {
  return password.value.length >= 6 && password.value === confirmPassword.value
})

onMounted(async () => {
  if (!token) {
    return
  }

  try {
    const response = await verifyInviteToken(token)
    inviteData.value = response.data
    inviteValid.value = true
  } catch {
    // Convite inválido ou expirado - será tratado pela UI
  }
})

const handleAcceptInvite = async () => {
  if (password.value !== confirmPassword.value) {
    formError.value = 'As senhas não coincidem.'
    return
  }

  if (password.value.length < 6) {
    formError.value = 'A senha deve ter pelo menos 6 caracteres.'
    return
  }

  submitting.value = true
  formError.value = null

  try {
    await httpAcceptInvite({
      token,
      senha: password.value,
    })

    // Redirecionar para login com mensagem de sucesso
    toast.success('Convite aceito com sucesso! Faça login com suas credenciais.')
    router.push({
      path: '/login',
      query: {
        message: 'Convite aceito com sucesso! Faça login com suas credenciais.',
        email: inviteData.value.user.email,
      },
    })
  } catch (err) {
    formError.value = err.response?.data?.error || 'Erro ao aceitar convite. Tente novamente.'
  } finally {
    submitting.value = false
  }
}
</script>

<style scoped>
.accept-invite {
  padding: 2rem 0;
}
</style>
