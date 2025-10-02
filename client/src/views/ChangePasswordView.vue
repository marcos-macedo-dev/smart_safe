<template>
  <div class="container mx-auto py-5">
    <div class="flex items-center mb-6">
      <button
        @click="$router.back()"
        class="flex items-center text-indigo-600 hover:text-indigo-800 dark:text-indigo-400 dark:hover:text-indigo-300 transition-colors"
      >
        <ChevronLeft class="w-5 h-5 mr-2" />
        Voltar
      </button>
      <h1 class="text-2xl font-bold text-zinc-900 dark:text-white mx-auto">Alterar Senha</h1>
      <div class="w-20"></div>
      <!-- Spacer for alignment -->
    </div>

    <div class="max-w-2xl mx-auto bg-white dark:bg-zinc-800 rounded-md shadow-sm p-6">
      <div class="text-center mb-8">
        <div
          class="mx-auto bg-indigo-100 dark:bg-indigo-900/30 w-16 h-16 rounded-full flex items-center justify-center mb-4"
        >
          <Lock class="w-8 h-8 text-indigo-600 dark:text-indigo-400" />
        </div>
        <h2 class="text-xl font-semibold text-zinc-800 dark:text-white mb-2">Alterar sua senha</h2>
        <p class="text-zinc-600 dark:text-zinc-400">
          Digite sua senha atual e a nova senha desejada
        </p>
      </div>

      <form @submit.prevent="changePassword" class="space-y-6">
        <div>
          <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-2">
            Senha Atual
          </label>
          <div class="relative">
            <input
              v-model="form.currentPassword"
              :type="showCurrentPassword ? 'text' : 'password'"
              class="w-full px-4 py-2.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white"
              placeholder="Digite sua senha atual"
              required
            />
            <button
              type="button"
              @click="showCurrentPassword = !showCurrentPassword"
              class="absolute inset-y-0 right-0 pr-3 flex items-center"
            >
              <Eye v-if="!showCurrentPassword" class="w-5 h-5 text-zinc-500 dark:text-zinc-400" />
              <EyeOff v-else class="w-5 h-5 text-zinc-500 dark:text-zinc-400" />
            </button>
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-2">
            Nova Senha
          </label>
          <div class="relative">
            <input
              v-model="form.newPassword"
              :type="showNewPassword ? 'text' : 'password'"
              class="w-full px-4 py-2.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white"
              placeholder="Digite sua nova senha"
              required
            />
            <button
              type="button"
              @click="showNewPassword = !showNewPassword"
              class="absolute inset-y-0 right-0 pr-3 flex items-center"
            >
              <Eye v-if="!showNewPassword" class="w-5 h-5 text-zinc-500 dark:text-zinc-400" />
              <EyeOff v-else class="w-5 h-5 text-zinc-500 dark:text-zinc-400" />
            </button>
          </div>
          <div v-if="form.newPassword" class="mt-1">
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
          <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
            A senha deve ter pelo menos 6 caracteres
          </p>
        </div>

        <div>
          <label class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-2">
            Confirmar Nova Senha
          </label>
          <div class="relative">
            <input
              v-model="form.confirmPassword"
              :type="showConfirmPassword ? 'text' : 'password'"
              class="w-full px-4 py-2.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white"
              placeholder="Confirme sua nova senha"
              required
            />
            <button
              type="button"
              @click="showConfirmPassword = !showConfirmPassword"
              class="absolute inset-y-0 right-0 pr-3 flex items-center"
            >
              <Eye v-if="!showConfirmPassword" class="w-5 h-5 text-zinc-500 dark:text-zinc-400" />
              <EyeOff v-else class="w-5 h-5 text-zinc-500 dark:text-zinc-400" />
            </button>
          </div>
          <div v-if="form.confirmPassword && form.newPassword !== form.confirmPassword" class="mt-1 text-red-400 text-xs">
            As senhas não coincidem
          </div>
        </div>

        <div class="flex justify-end space-x-3 pt-4">
          <button
            type="button"
            @click="resetForm"
            class="px-5 py-2.5 border border-zinc-300 dark:border-zinc-600 text-sm font-medium rounded-md text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-zinc-500 transition-colors"
          >
            Cancelar
          </button>
          <button
            type="submit"
            :disabled="loading || !isFormValid"
            class="px-5 py-2.5 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
          >
            <Loader class="w-4 h-4 mr-2 animate-spin" v-if="loading" />
            {{ loading ? 'Alterando...' : 'Alterar Senha' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed } from 'vue'
import { Lock, Eye, EyeOff, Loader, ChevronLeft } from 'lucide-vue-next'
import { useToastStore } from '@/stores/toast'
import http from '@/services/http'

const toast = useToastStore()

// Form data
const form = reactive({
  currentPassword: '',
  newPassword: '',
  confirmPassword: '',
})

// UI state
const showCurrentPassword = ref(false)
const showNewPassword = ref(false)
const showConfirmPassword = ref(false)
const loading = ref(false)

// Funções para calcular a força da senha
const passwordStrength = computed(() => {
  const pass = form.newPassword
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
  return form.currentPassword.length >= 6 && 
         form.newPassword.length >= 6 && 
         form.confirmPassword.length >= 6 && 
         form.newPassword === form.confirmPassword
})

// Reset form
const resetForm = () => {
  form.currentPassword = ''
  form.newPassword = ''
  form.confirmPassword = ''
  showCurrentPassword.value = false
  showNewPassword.value = false
  showConfirmPassword.value = false
}

// Change password
const changePassword = async () => {
  // Validation
  if (!form.currentPassword || !form.newPassword || !form.confirmPassword) {
    toast.error('Por favor, preencha todos os campos')
    return
  }

  if (form.newPassword !== form.confirmPassword) {
    toast.error('As senhas não coincidem')
    return
  }

  if (form.newPassword.length < 6) {
    toast.error('A nova senha deve ter pelo menos 6 caracteres')
    return
  }

  try {
    loading.value = true

    // Call API to change password
    await http.post('/auth/change-password', {
      currentPassword: form.currentPassword,
      newPassword: form.newPassword,
    })

    toast.success('Senha alterada com sucesso!')
    resetForm()

    // Optionally redirect to profile after success
    // router.push('/autoridade/profile')
  } catch (error) {
    const message = error.response?.data?.message || 'Erro ao alterar senha'
    toast.error(message)
  } finally {
    loading.value = false
  }
}
</script>
