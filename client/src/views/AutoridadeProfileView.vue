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
                  >Nome</label
                >
                <input
                  v-model="autoridade.nome"
                  type="text"
                  class="w-full px-2.5 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
                  placeholder="Seu nome"
                />
              </div>
              <div>
                <label
                  class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
                  >Email</label
                >
                <input
                  v-model="autoridade.email"
                  type="email"
                  class="w-full px-2.5 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
                  placeholder="seu.email@exemplo.com"
                />
              </div>
            </div>

            <div>
              <label
                class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
                >Delegacia</label
              >
              <input
                :value="autoridade?.delegacia?.nome || 'Nome da delegacia'"
                type="text"
                disabled
                class="w-full px-2.5 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:text-white text-sm bg-zinc-100 dark:bg-zinc-700/30"
              />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-2.5">
              <div>
                <label
                  class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
                  >Telefone da Delegacia</label
                >
                <input
                  :value="autoridade?.delegacia?.telefone || 'Telefone da delegacia'"
                  type="text"
                  disabled
                  class="w-full px-2.5 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:text-white text-sm bg-zinc-100 dark:bg-zinc-700/30"
                />
              </div>
              <div>
                <label
                  class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
                  >Endereço da Delegacia</label
                >
                <input
                  :value="autoridade?.delegacia?.endereco || 'Endereço da delegacia'"
                  type="text"
                  disabled
                  class="w-full px-2.5 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:text-white text-sm bg-zinc-100 dark:bg-zinc-700/30"
                />
              </div>
            </div>
          </div>

          <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-2.5 mt-4">
            Segurança
          </h2>
          <div class="space-y-2.5">
            <div class="bg-blue-50 dark:bg-blue-900/20 rounded-md p-4">
              <p class="text-sm text-blue-800 dark:text-blue-200 mb-3">
                Para alterar sua senha, acesse a página dedicada de alteração de senha.
              </p>
              <router-link
                to="/change-password"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-colors"
              >
                Alterar Senha
              </router-link>
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
import { ref, onMounted } from 'vue'
import { getLoggedInAutoridade, updateLoggedInAutoridade } from '@/services/http'
import { useToastStore } from '@/stores/toast'

const toast = useToastStore()

// Dados da autoridade
const autoridade = ref({
  nome: '',
  email: '',
  cargo: '',
  delegacia: {
    nome: '',
    endereco: '',
    telefone: '',
  },
  avatar: '',
})

// Dados para alteração de senha (removido pois foi movido para página dedicada)

// Dados originais da autoridade para reset
const originalAutoridade = ref({})

// Carregar dados da autoridade logada
const loadAutoridadeProfile = async () => {
  try {
    const response = await getLoggedInAutoridade()
    autoridade.value = { ...response.data }
    originalAutoridade.value = { ...response.data }
  } catch (error) {
    toast.error('Erro ao carregar perfil da autoridade')
    console.error('Erro ao carregar perfil:', error)
  }
}

// Salvar alterações no perfil
const saveProfile = async () => {
  try {
    // Atualizar autoridade (excluindo campos de senha do objeto principal)
    const { ...updateData } = autoridade.value
    await updateLoggedInAutoridade(updateData)

    toast.success('Perfil atualizado com sucesso')

    // Atualizar dados originais
    originalAutoridade.value = { ...autoridade.value }
  } catch (error) {
    toast.error('Erro ao atualizar perfil')
    console.error('Erro ao atualizar perfil:', error)
  }
}

// Resetar formulário
const resetForm = () => {
  autoridade.value = { ...originalAutoridade.value }
}

// Carregar perfil quando o componente for montado
onMounted(() => {
  loadAutoridadeProfile()
})
</script>
