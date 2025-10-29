<template>
  <div class="container mx-auto py-5">
    <!-- Breadcrumbs -->
    <Breadcrumbs :breadcrumbs="breadcrumbs" />

    <!-- Cabeçalho -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-4">
      <h1 class="text-xl font-bold text-zinc-900 dark:text-white">Chamados de Emergência</h1>

      <!-- Filtros e ações -->
      <div class="flex flex-wrap gap-2 w-full md:w-auto">
        <!-- Filtro de data início -->
        <input
          v-model="filters.startDate"
          type="date"
          @change="applyFilters"
          class="px-3 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
        />

        <!-- Filtro de data fim -->
        <input
          v-model="filters.endDate"
          type="date"
          @change="applyFilters"
          class="px-3 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
        />

        <!-- Filtro de status -->
        <select
          v-model="filters.status"
          @change="applyFilters"
          class="px-3 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
        >
          <option value="">Todos os status</option>
          <option value="pendente">Pendente</option>
          <option value="ativo">Ativo</option>
          <option value="aguardando_autoridade">Aguardando Autoridade</option>
          <option value="fechado">Fechado</option>
          <option value="cancelado">Cancelado</option>
        </select>

        <!-- Campo de busca -->
        <div class="relative">
          <input
            v-model="filters.search"
            @input="debounceSearch"
            type="text"
            placeholder="Buscar..."
            class="px-3 py-1.5 pl-8 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
          />
          <Search class="w-4 h-4 absolute left-2.5 top-2 text-zinc-400" />
        </div>

        <!-- Botão de atualizar -->
        <button
          @click="loadSosList"
          :disabled="loading"
          class="inline-flex items-center px-3 py-1.5 border border-zinc-300 dark:border-zinc-600 text-sm font-medium rounded-md text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-600 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-zinc-500 transition-colors disabled:opacity-50"
        >
          <RefreshCw class="w-4 h-4 mr-1" :class="{ 'animate-spin': loading }" />
          Atualizar
        </button>
      </div>
    </div>

    <!-- Estatísticas -->
    <div class="grid grid-cols-1 md:grid-cols-5 gap-4 mb-6">
      <div
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
      >
        <div class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
          Total
        </div>
        <div class="text-2xl font-bold text-zinc-900 dark:text-white mt-1">{{ stats.total }}</div>
      </div>

      <div
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
      >
        <div class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
          Pendentes
        </div>
        <div class="text-2xl font-bold text-yellow-600 dark:text-yellow-400 mt-1">
          {{ stats.pendente }}
        </div>
      </div>

      <div
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
      >
        <div class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
          Ativos
        </div>
        <div class="text-2xl font-bold text-blue-600 dark:text-blue-400 mt-1">
          {{ stats.ativo }}
        </div>
      </div>

      <div
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
      >
        <div class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
          Fechados
        </div>
        <div class="text-2xl font-bold text-green-600 dark:text-green-400 mt-1">
          {{ stats.fechado }}
        </div>
      </div>

      <div
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
      >
        <div class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
          Cancelados
        </div>
        <div class="text-2xl font-bold text-red-600 dark:text-red-400 mt-1">
          {{ stats.cancelado }}
        </div>
      </div>
    </div>

    <!-- Lista de SOS -->
    <div class="bg-white dark:bg-zinc-800 rounded-md shadow-sm overflow-hidden">
      <!-- Cabeçalho da tabela -->
      <div
        class="hidden md:grid grid-cols-12 gap-4 px-4 py-3 bg-zinc-50 dark:bg-zinc-700/30 border-b border-zinc-200 dark:border-zinc-700 text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide"
      >
        <div class="col-span-1">ID</div>
        <div class="col-span-3">Solicitante</div>
        <div class="col-span-2">Status</div>
        <div class="col-span-3">Delegacia</div>
        <div class="col-span-2">Data/Hora</div>
        <div class="col-span-1 text-right">Ações</div>
      </div>

      <!-- Loading state -->
      <div v-if="loading" class="p-6 text-center">
        <p class="text-zinc-500 dark:text-zinc-400">Carregando chamados...</p>
      </div>

      <!-- Empty state -->
      <div v-else-if="filteredSosList.length === 0" class="p-6 text-center">
        <p class="text-zinc-500 dark:text-zinc-400">Nenhum chamado de emergência encontrado.</p>
      </div>

      <!-- Lista de SOS -->
      <div v-else class="divide-y divide-zinc-200 dark:divide-zinc-700">
        <div
          v-for="sos in paginatedSosList"
          :key="sos.id"
          class="p-4 hover:bg-zinc-50 dark:hover:bg-zinc-700/20 transition-colors"
        >
          <!-- Versão mobile -->
          <div class="md:hidden">
            <div class="flex justify-between items-start">
              <div>
                <div class="flex items-center gap-2">
                  <h3 class="font-medium text-zinc-900 dark:text-white">SOS #{{ sos.id }}</h3>
                  <span
                    class="px-2 py-0.5 text-xs rounded-full"
                    :class="getStatusClass(sos.status)"
                  >
                    {{ formatStatus(sos.status) }}
                  </span>
                </div>
                <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">
                  {{ sos.usuario?.nome_completo || 'Usuário não identificado' }}
                </p>
                <p class="text-xs text-zinc-400 dark:text-zinc-500 mt-1">
                  {{ formatDate(sos.createdAt) }}
                </p>
              </div>
              <div class="text-right">
                <p class="text-sm text-zinc-500 dark:text-zinc-400">
                  {{ sos.delegacia?.nome || 'Não roteado' }}
                </p>
                <div class="flex justify-end mt-2">
                  <button
                    @click.stop="viewSosDetails(sos.id)"
                    class="text-indigo-600 dark:text-indigo-400 hover:text-indigo-800 dark:hover:text-indigo-300 text-sm font-medium"
                  >
                    Ver detalhes
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Versão desktop -->
          <div class="hidden md:grid grid-cols-12 gap-4 items-center">
            <div class="col-span-1 font-medium text-zinc-900 dark:text-white">#{{ sos.id }}</div>
            <div class="col-span-3">
              <div class="font-medium text-zinc-900 dark:text-white">
                {{ sos.usuario?.nome_completo || 'Usuário não identificado' }}
              </div>
              <div class="text-xs text-zinc-500 dark:text-zinc-400 mt-1">
                {{ sos.usuario?.telefone || 'Telefone não informado' }}
              </div>
            </div>
            <div class="col-span-2">
              <span class="px-2 py-0.5 text-xs rounded-full" :class="getStatusClass(sos.status)">
                {{ formatStatus(sos.status) }}
              </span>
            </div>
            <div class="col-span-3">
              <div class="text-zinc-900 dark:text-white">
                {{ sos.delegacia?.nome || 'Não roteado' }}
              </div>
              <div class="text-xs text-zinc-500 dark:text-zinc-400 mt-1">
                {{
                  sos.latitude && sos.longitude
                    ? `${sos.latitude}, ${sos.longitude}`
                    : 'Localização indisponível'
                }}
              </div>
            </div>
            <div class="col-span-2 text-zinc-500 dark:text-zinc-400">
              {{ formatDate(sos.createdAt) }}
            </div>
            <div class="col-span-1 text-right">
              <button
                @click.stop="viewSosDetails(sos.id)"
                class="text-indigo-600 dark:text-indigo-400 hover:text-indigo-800 dark:hover:text-indigo-300 text-sm font-medium"
              >
                Ver
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Paginação -->
    <div class="flex justify-between items-center mt-6">
      <div class="text-sm text-zinc-500 dark:text-zinc-400">
        Mostrando {{ paginatedSosList.length }} de {{ filteredSosList.length }} chamados
      </div>
      <div class="flex gap-2">
        <button
          @click="previousPage"
          :disabled="currentPage === 1"
          class="px-3 py-1.5 text-sm border border-zinc-300 dark:border-zinc-600 rounded-md text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-600 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-zinc-500 disabled:opacity-50"
        >
          Anterior
        </button>
        <button
          @click="nextPage"
          :disabled="currentPage * itemsPerPage >= filteredSosList.length"
          class="px-3 py-1.5 text-sm border border-zinc-300 dark:border-zinc-600 rounded-md text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-600 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-zinc-500 disabled:opacity-50"
        >
          Próximo
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, computed } from 'vue'
import { useRouter } from 'vue-router'
import { RefreshCw, Search } from 'lucide-vue-next'
import { listSos } from '@/services/http'
import socket from '@/services/socket'
import notificationService from '@/services/notification'
import { useToastStore } from '@/stores/toast'
import Breadcrumbs from '@/components/Breadcrumbs.vue'

// Router
const router = useRouter()
const toast = useToastStore()

// Breadcrumbs
const breadcrumbs = ref([{ label: 'Chamados de Emergência', path: '/sos' }])

// Estados
const sosList = ref([])
const filteredSosList = ref([])
const loading = ref(false)
const searchTimeout = ref(null)

// Filtros
const filters = ref({
  status: '',
  search: '',
  startDate: '',
  endDate: '',
})

// Paginação
const currentPage = ref(1)
const itemsPerPage = ref(10)

// Estatísticas
const stats = ref({
  total: 0,
  pendente: 0,
  ativo: 0,
  fechado: 0,
  cancelado: 0,
})

// Dados paginados
const paginatedSosList = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage.value
  const end = start + itemsPerPage.value
  return filteredSosList.value.slice(start, end)
})

// Carregar lista de SOS
const loadSosList = async () => {
  try {
    loading.value = true

    const response = await listSos()
    sosList.value = response.data

    // Atualizar estatísticas
    updateStats()

    // Aplicar filtros
    applyFilters()
  } catch (error) {
    toast.error('Erro ao carregar chamados de emergência')
    console.error('Erro ao carregar SOS:', error)
  } finally {
    loading.value = false
  }
}

// Atualizar estatísticas
const updateStats = () => {
  stats.value.total = sosList.value.length
  stats.value.pendente = sosList.value.filter((sos) => sos.status === 'pendente').length
  stats.value.ativo = sosList.value.filter((sos) => sos.status === 'ativo').length
  stats.value.fechado = sosList.value.filter((sos) => sos.status === 'fechado').length
  stats.value.cancelado = sosList.value.filter((sos) => sos.status === 'cancelado').length
}

// Aplicar filtros
const applyFilters = () => {
  let filtered = [...sosList.value]

  // Filtrar por status
  if (filters.value.status) {
    filtered = filtered.filter((sos) => sos.status === filters.value.status)
  }

  // Filtrar por data
  if (filters.value.startDate) {
    const startDate = new Date(filters.value.startDate)
    filtered = filtered.filter((sos) => new Date(sos.createdAt) >= startDate)
  }
  if (filters.value.endDate) {
    const endDate = new Date(filters.value.endDate)
    endDate.setHours(23, 59, 59, 999) // Fim do dia
    filtered = filtered.filter((sos) => new Date(sos.createdAt) <= endDate)
  }

  // Filtrar por busca
  if (filters.value.search) {
    const searchTerm = filters.value.search.toLowerCase()
    filtered = filtered.filter(
      (sos) =>
        sos.id.toString().includes(searchTerm) ||
        (sos.usuario?.nome_completo &&
          sos.usuario.nome_completo.toLowerCase().includes(searchTerm)) ||
        (sos.delegacia?.nome && sos.delegacia.nome.toLowerCase().includes(searchTerm)),
    )
  }

  filteredSosList.value = filtered
  currentPage.value = 1 // Resetar para a primeira página
}

// Debounce para busca
const debounceSearch = () => {
  clearTimeout(searchTimeout.value)
  searchTimeout.value = setTimeout(() => {
    applyFilters()
  }, 300)
}

// Formatar status para exibição
const formatStatus = (status) => {
  const statusMap = {
    pendente: 'Pendente',
    ativo: 'Ativo',
    aguardando_autoridade: 'Aguardando Autoridade',
    fechado: 'Fechado',
    cancelado: 'Cancelado',
  }

  return statusMap[status] || status
}

// Obter classe CSS para status
const getStatusClass = (status) => {
  const classMap = {
    pendente: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300',
    ativo: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300',
    aguardando_autoridade:
      'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-300',
    fechado: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300',
    cancelado: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300',
  }

  return classMap[status] || 'bg-zinc-100 text-zinc-800 dark:bg-zinc-700 dark:text-zinc-300'
}

// Formatar data
const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

// Visualizar detalhes do SOS
const viewSosDetails = (id) => {
  router.push(`/sos/${id}`)
}

// Navegação de página
const previousPage = () => {
  if (currentPage.value > 1) {
    currentPage.value--
  }
}

const nextPage = () => {
  if (currentPage.value * itemsPerPage.value < filteredSosList.value.length) {
    currentPage.value++
  }
}

// Adicionar esta variável para rastrear notificações recentes
const recentSosNotifications = new Set()
const RECENT_SOS_TIMEOUT = 10000 // 10 segundos

// Criar uma função para notificar SOS deduplicada
const notifyNewSosDeduplicated = (novoSos) => {
  // Verificar se já notificamos sobre este SOS recentemente
  if (recentSosNotifications.has(novoSos.id)) {
    return
  }

  // Adicionar ao conjunto de notificações recentes
  recentSosNotifications.add(novoSos.id)

  // Remover após o tempo limite
  setTimeout(() => {
    recentSosNotifications.delete(novoSos.id)
  }, RECENT_SOS_TIMEOUT)

  console.log('Recebido novo SOS:', novoSos)
  // Adicionar o novo SOS à lista
  sosList.value.unshift(novoSos)
  // Atualizar estatísticas
  updateStats()
  // Aplicar filtros
  applyFilters()
  // Notificar usuário
  notificationService.notifyNewSos(novoSos)
}

// Carregar dados quando o componente for montado
onMounted(() => {
  // Solicitar permissão para notificações do navegador
  notificationService.requestNotificationPermission()

  // Carregar dados iniciais
  loadSosList()

  // Escutar eventos de novo SOS (eventos gerais)
  socket.on('novo_sos', notifyNewSosDeduplicated)

  // Escutar eventos de SOS não roteado
  socket.on('novo_sos_nao_roteado', notifyNewSosDeduplicated)

  // Escutar eventos de SOS global (para atualização em tempo real)
  socket.on('novo_sos_global', notifyNewSosDeduplicated)
})

onBeforeUnmount(() => {
  // Limpar timeout de busca
  clearTimeout(searchTimeout.value)

  // Remover listeners do WebSocket
  socket.off('novo_sos')
  socket.off('novo_sos_nao_roteado')
  socket.off('novo_sos_global')
})
</script>
