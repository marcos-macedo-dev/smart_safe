<template>
  <div class="container mx-auto py-5">
    <h1 class="text-xl font-bold text-zinc-900 dark:text-white mb-4">Meu Perfil</h1>

    <div class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4">
      <div class="grid grid-cols-1 gap-4">
        <!-- Profile Details Section -->
        <div>
          <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-2.5">
            Informações Pessoais
          </h2>
          <div class="space-y-2.5">
            <div class="grid grid-cols-1 gap-2.5">
              <div>
                <label
                  class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
                  >Nome Completo</label
                >
                <input
                  v-model="user.nome"
                  type="text"
                  class="w-full px-2.5 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
                  placeholder="Seu nome completo"
                />
              </div>
              <div>
                <label
                  class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
                  >Email</label
                >
                <input
                  v-model="user.email"
                  type="email"
                  class="w-full px-2.5 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
                  placeholder="seu.email@exemplo.com"
                />
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-2.5">
              <div>
                <label
                  class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
                  >Telefone</label
                >
                <input
                  v-model="user.telefone"
                  type="text"
                  class="w-full px-2.5 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
                  placeholder="(00) 00000-0000"
                />
              </div>
              <div>
                <label
                  class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
                  >Cargo</label
                >
                <input
                  v-model="user.cargo"
                  type="text"
                  disabled
                  class="w-full px-2.5 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:text-white text-sm bg-zinc-100 dark:bg-zinc-700/30"
                />
              </div>
            </div>

            <div>
              <label
                class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
                >Endereço</label
              >
              <input
                v-model="user.endereco"
                type="text"
                class="w-full px-2.5 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
                placeholder="Seu endereço completo"
              />
            </div>
          </div>

          <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-2.5 mt-4">
            Segurança
          </h2>
          <div class="space-y-2.5">
            <div>
              <label
                class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
                >Senha Atual</label
              >
              <input
                v-model="passwordData.currentPassword"
                type="password"
                class="w-full px-2.5 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
                placeholder="••••••••"
              />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-2.5">
              <div>
                <label
                  class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
                  >Nova Senha</label
                >
                <input
                  v-model="passwordData.newPassword"
                  type="password"
                  class="w-full px-2.5 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
                  placeholder="••••••••"
                />
                <div v-if="passwordData.newPassword" class="mt-1">
                  <div class="w-full bg-zinc-600 rounded-full h-1">
                    <div
                      class="h-1 rounded-full"
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
                <label
                  class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
                  >Confirmar Nova Senha</label
                >
                <input
                  v-model="passwordData.confirmPassword"
                  type="password"
                  class="w-full px-2.5 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
                  placeholder="••••••••"
                />
                <div
                  v-if="
                    passwordData.confirmPassword &&
                    passwordData.newPassword !== passwordData.confirmPassword
                  "
                  class="mt-1 text-red-400 text-xs"
                >
                  As senhas não coincidem
                </div>
              </div>
            </div>
          </div>

          <div class="mt-5 flex justify-end space-x-2">
            <button
              type="button"
              class="inline-flex justify-center py-1.5 px-3 border border-zinc-300 dark:border-zinc-600 text-xs font-medium rounded-md text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-600 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-zinc-500 uppercase tracking-wide transition-colors"
              @click="resetForm"
            >
              Cancelar
            </button>
            <button
              type="button"
              class="inline-flex justify-center py-1.5 px-3 border border-transparent text-xs font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-indigo-500 uppercase tracking-wide transition-colors"
              @click="saveProfile"
              :disabled="!isFormValid"
            >
              Salvar Alterações
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { getLoggedInUser, updateUser } from '@/services/http'
import { useToastStore } from '@/stores/toast'

const toast = useToastStore()

// Dados do usuário
const user = ref({
  nome: '',
  email: '',
  telefone: '',
  cargo: '',
  endereco: '',
  avatar: '',
})

// Dados para alteração de senha
const passwordData = ref({
  currentPassword: '',
  newPassword: '',
  confirmPassword: '',
})

// Dados originais do usuário para reset
const originalUser = ref({})

// Funções para calcular a força da senha
const passwordStrength = computed(() => {
  const pass = passwordData.value.newPassword
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
  // Se não está tentando alterar a senha, o formulário é válido
  if (!passwordData.value.newPassword) return true

  // Se está tentando alterar a senha, validar os campos
  return (
    passwordData.value.currentPassword.length >= 6 &&
    passwordData.value.newPassword.length >= 6 &&
    passwordData.value.confirmPassword.length >= 6 &&
    passwordData.value.newPassword === passwordData.value.confirmPassword
  )
})

// Carregar dados do usuário logado
const loadUserProfile = async () => {
  try {
    const response = await getLoggedInUser()
    user.value = { ...response.data }
    originalUser.value = { ...response.data }
  } catch (error) {
    toast.error('Erro ao carregar perfil do usuário')
    console.error('Erro ao carregar perfil:', error)
  }
}

// Salvar alterações no perfil
const saveProfile = async () => {
  try {
    // Verificar se há alterações na senha
    if (passwordData.value.newPassword) {
      if (passwordData.value.newPassword !== passwordData.value.confirmPassword) {
        toast.error('As senhas não coincidem')
        return
      }

      if (passwordData.value.newPassword.length < 6) {
        toast.error('A nova senha deve ter pelo menos 6 caracteres')
        return
      }

      if (!passwordData.value.currentPassword) {
        toast.error('Por favor, informe sua senha atual')
        return
      }

      // Adicionar a senha ao payload
      user.value.senha = passwordData.value.newPassword
    }

    // Atualizar usuário (excluindo campos de senha do objeto principal)
    const { ...updateData } = user.value
    await updateUser(user.value.id, updateData)

    toast.success('Perfil atualizado com sucesso')

    // Resetar campos de senha
    passwordData.value = {
      currentPassword: '',
      newPassword: '',
      confirmPassword: '',
    }

    // Atualizar dados originais
    originalUser.value = { ...user.value }
  } catch (error) {
    toast.error('Erro ao atualizar perfil')
    console.error('Erro ao atualizar perfil:', error)
  }
}

// Resetar formulário
const resetForm = () => {
  user.value = { ...originalUser.value }
  passwordData.value = {
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  }
}

// Carregar perfil quando o componente for montado
onMounted(() => {
  loadUserProfile()
})
</script>
