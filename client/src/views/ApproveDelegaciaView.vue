<template>
  <div class="h-screen flex items-center justify-center bg-zinc-900 px-4">
    <div class="w-full max-w-md rounded-3xl p-8 bg-zinc-800 shadow-xl">
      <header class="mb-6 text-center">
        <h1 class="text-2xl font-extrabold text-white mb-2">Aprovação de Delegacia</h1>
        <p class="text-gray-300 text-sm">
          Verifique os dados da solicitação e aprove ou rejeite o registro
        </p>
      </header>

      <div v-if="loading" class="text-center py-8">
        <div class="flex justify-center">
          <Loader class="w-6 h-6 text-blue-600 dark:text-blue-400 animate-spin" />
        </div>
        <p class="mt-3 text-gray-400 dark:text-gray-300 text-sm">Verificando solicitação de registro...</p>
      </div>

      <div v-else-if="error" class="rounded-md bg-red-50 dark:bg-red-900 p-4 mb-4">
        <div class="flex">
          <div class="flex-shrink-0">
            <XCircle class="h-5 w-5 text-red-400" />
          </div>
          <div class="ml-3">
            <h3 class="text-sm font-medium text-red-800 dark:text-red-200">Erro</h3>
            <div class="mt-1 text-sm text-red-700 dark:text-red-300">
              <p>{{ error }}</p>
            </div>
          </div>
        </div>
      </div>

      <div v-else-if="requestData" class="space-y-6">
        <!-- Dados da Delegacia -->
        <div class="bg-zinc-700 border border-zinc-600 rounded-lg p-4">
          <h3 class="text-base font-bold text-white mb-4 flex items-center">
            <div class="w-2 h-2 bg-blue-500 rounded-full mr-2"></div>
            Dados da Delegacia
          </h3>

          <div class="space-y-4">
            <div>
              <label class="block text-zinc-300 dark:text-zinc-400 text-xs font-medium mb-1">
                Nome da Delegacia
              </label>
              <p class="text-white font-medium text-sm">
                {{ requestData.delegacia_nome }}
              </p>
            </div>

            <div>
              <label class="block text-zinc-300 dark:text-zinc-400 text-xs font-medium mb-1">
                Endereço Completo
              </label>
              <p class="text-white font-medium text-sm">
                {{ requestData.delegacia_endereco }}
              </p>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-zinc-300 dark:text-zinc-400 text-xs font-medium mb-1">
                  Latitude
                </label>
                <p class="text-white font-mono text-sm">
                  {{ requestData.delegacia_latitude }}
                </p>
              </div>
              <div>
                <label class="block text-zinc-300 dark:text-zinc-400 text-xs font-medium mb-1">
                  Longitude
                </label>
                <p class="text-white font-mono text-sm">
                  {{ requestData.delegacia_longitude }}
                </p>
              </div>
            </div>

            <div v-if="requestData.delegacia_telefone">
              <label class="block text-zinc-300 dark:text-zinc-400 text-xs font-medium mb-1">
                Telefone
              </label>
              <p class="text-white font-medium text-sm">
                {{ requestData.delegacia_telefone }}
              </p>
            </div>
          </div>
        </div>

        <!-- Dados do Administrador -->
        <div class="bg-zinc-700 border border-zinc-600 rounded-lg p-4">
          <h3 class="text-base font-bold text-white mb-4 flex items-center">
            <div class="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
            Dados do Administrador
          </h3>

          <div class="space-y-4">
            <div>
              <label class="block text-zinc-300 dark:text-zinc-400 text-xs font-medium mb-1">
                Nome Completo
              </label>
              <p class="text-white font-medium text-sm">
                {{ requestData.administrador_nome }}
              </p>
            </div>

            <div>
              <label class="block text-zinc-300 dark:text-zinc-400 text-xs font-medium mb-1">
                Email
              </label>
              <p class="text-white font-medium text-sm break-all">
                {{ requestData.administrador_email }}
              </p>
            </div>
          </div>
        </div>

        <div class="pt-2 space-y-3">
          <button
            @click="approveRequest"
            :disabled="processing"
            class="form-button"
          >
            <Loader v-if="processing" class="w-4 h-4 animate-spin" />
            <Check v-else class="w-4 h-4" />
            <span>{{ processing ? 'Aprovando...' : 'Aprovar Registro' }}</span>
          </button>

          <button
            @click="rejectRequest"
            :disabled="processing"
            class="w-full flex justify-center items-center gap-2 py-2.5 px-4 border border-zinc-300 dark:border-zinc-600 rounded-lg shadow-sm text-sm font-medium text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-800 hover:bg-zinc-50 dark:hover:bg-zinc-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 transition"
          >
            <Loader v-if="processing" class="w-4 h-4 animate-spin" />
            <X v-else class="w-4 h-4" />
            <span>{{ processing ? 'Rejeitando...' : 'Rejeitar Registro' }}</span>
          </button>
        </div>
      </div>

      <div v-else class="text-center py-8">
        <FileQuestion class="mx-auto h-10 w-10 text-gray-400 dark:text-gray-500" />
        <h3 class="mt-2 text-sm font-medium text-white">
          Nenhuma solicitação encontrada
        </h3>
        <p class="mt-1 text-xs text-gray-400">
          O link de aprovação pode estar expirado ou inválido.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Check, X, XCircle, FileQuestion, Loader } from 'lucide-vue-next'
import {
  approveDelegaciaRegistration,
  rejectDelegaciaRegistration,
  getPendingDelegaciaRegistration,
} from '@/services/http'
import { useToastStore } from '@/stores/toast'
import { useConfirmDialog } from '@/stores/confirm-dialog.store'

const confirmDialog = useConfirmDialog()
const route = useRoute()
const router = useRouter()
const toast = useToastStore()

const loading = ref(true)
const processing = ref(false)
const requestData = ref(null)
const error = ref(null)

const token = route.query.token

onMounted(async () => {
  try {
    loading.value = true
    const response = await getPendingDelegaciaRegistration(token)
    if (response.data) {
      requestData.value = response.data
    } else {
      error.value = 'Solicitação não encontrada'
    }
  } catch (err) {
    console.error('Erro ao buscar solicitação de registro de delegacia:', err)
    error.value = err.message || 'Erro ao carregar solicitação'
  } finally {
    loading.value = false
  }
})

async function approveRequest() {
  const confirm = await confirmDialog.confirm({
    titulo: 'Aprovar Registro',
    mensagem: `Tem certeza que deseja aprovar o registro da delegacia "${requestData.value.delegacia_nome}"?`,
  })
  if (!confirm) return

  try {
    processing.value = true
    await approveDelegaciaRegistration({ token })
    toast.success('Registro aprovado com sucesso! O convite foi enviado para o administrador.')
    router.push('/login')
  } catch (error) {
    toast.error(error.message || 'Erro ao aprovar registro')
  } finally {
    processing.value = false
  }
}

async function rejectRequest() {
  const confirm = await confirmDialog.confirm({
    titulo: 'Rejeitar Registro',
    mensagem: `Tem certeza que deseja rejeitar o registro da delegacia "${requestData.value.delegacia_nome}"?`,
  })
  if (!confirm) return

  try {
    processing.value = true
    await rejectDelegaciaRegistration({ token })
    toast.success('Registro rejeitado com sucesso!')
    router.push('/login')
  } catch (error) {
    toast.error(error.message || 'Erro ao rejeitar registro')
  } finally {
    processing.value = false
  }
}
</script>
