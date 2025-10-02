<template>
  <div class="h-screen flex items-center justify-center bg-zinc-900 px-4">
    <div
      class="w-full max-w-md rounded-3xl p-10 bg-zinc-800 shadow-xl"
      role="main"
      aria-label="Redefinição de senha"
    >
      <header class="mb-8 text-center">
        <h1 class="text-3xl font-extrabold text-white mb-2">Redefinir Senha</h1>
        <p class="text-gray-300 text-sm">
          Digite sua nova senha abaixo
        </p>
      </header>

      <form @submit.prevent="handleResetPassword" class="space-y-6" novalidate>
        <!-- Email and OTP fields for users -->
        <div v-if="type === 'user'">
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
          
          <div>
            <label for="otp" class="form-label">Código de Verificação</label>
            <input
              id="otp"
              v-model="form.otp"
              type="text"
              required
              placeholder="Digite o código de 6 dígitos"
              class="form-input"
              maxlength="6"
            />
          </div>
        </div>
        
        <!-- Password fields -->
        <div>
          <label for="password" class="form-label">Nova Senha</label>
          <input
            id="password"
            v-model="form.password"
            type="password"
            required
            placeholder="Digite sua nova senha"
            autocomplete="new-password"
            class="form-input"
            minlength="6"
          />
          <div v-if="form.password" class="mt-1">
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
            v-model="form.confirmPassword"
            type="password"
            required
            placeholder="Confirme sua nova senha"
            autocomplete="new-password"
            class="form-input"
            minlength="6"
          />
        </div>

        <div v-if="form.password && form.confirmPassword && form.password !== form.confirmPassword" class="text-red-400 text-sm">
          As senhas não coincidem
        </div>

        <div class="flex gap-2">
          <button 
            type="submit" 
            class="form-button"
            :disabled="!isFormValid"
          >
            <Lock class="w-5 h-5" />
            <span>Redefinir Senha</span>
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
import { reactive, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { Lock } from 'lucide-vue-next'
import { useToastStore } from '@/stores/toast'
import { resetPasswordWithToken, resetPasswordWithOtp } from '@/services/http';

const router = useRouter()
const route = useRoute()
const toast = useToastStore()

// Get token from URL query parameters
const token = route.query.token
const type = route.query.type // 'autoridade' or 'user'

// Form data
const form = reactive({
  password: '',
  confirmPassword: '',
  email: '', // Needed for OTP reset
  otp: ''    // Needed for OTP reset
})

// Funções para calcular a força da senha
const passwordStrength = computed(() => {
  const pass = form.password
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

// Computed property to check if form is valid
const isFormValid = computed(() => {
  if (type === 'user') {
    // For users, we need email and OTP
    return form.email.length > 0 && 
           form.otp.length === 6 && 
           form.password.length >= 6 && 
           form.confirmPassword.length >= 6 && 
           form.password === form.confirmPassword
  } else {
    // For authorities, we need token
    return token &&
           form.password.length >= 6 && 
           form.confirmPassword.length >= 6 && 
           form.password === form.confirmPassword
  }
})

// Handle reset password form submission
const handleResetPassword = async () => {
  if (type === 'user') {
    // Reset password for user (cidadã) with OTP
    if (!isFormValid.value) {
      toast.error('Por favor, verifique os campos!')
      return
    }

    try {
      // Call reset password service for user
      await resetPasswordWithOtp(form.email, form.otp, form.password)

      // Show success message
      toast.success('Senha redefinida com sucesso!')

      // Redirect to login after 2 seconds
      setTimeout(() => {
        router.push('/login')
      }, 2000)
    } catch (error) {
      // Error handling is automatic through HTTP interceptor
      console.error('Failed to reset password for user:', error)
      toast.error('Erro ao redefinir senha. Tente novamente.')
    }
  } else {
    // Reset password for authority with token
    if (!token) {
      toast.error('Token inválido ou expirado!')
      return
    }

    if (!isFormValid.value) {
      toast.error('Por favor, verifique os campos da senha!')
      return
    }

    try {
      // Call reset password service for authority
      await resetPasswordWithToken(token, form.password)

      // Show success message
      toast.success('Senha redefinida com sucesso!')

      // Redirect to login after 2 seconds
      setTimeout(() => {
        router.push('/login')
      }, 2000)
    } catch (error) {
      // Error handling is automatic through HTTP interceptor
      console.error('Failed to reset password for authority:', error)
      toast.error('Erro ao redefinir senha. Tente novamente.')
    }
  }
}
</script>