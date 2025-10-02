<template>
  <div class="container mx-auto py-5">
    <!-- Cabeçalho -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-4">
      <h1 class="text-xl font-bold text-zinc-900 dark:text-white">Gerenciamento de Operadores</h1>

      <!-- Filtros e ações -->
      <div class="flex flex-wrap gap-2 w-full md:w-auto">
        <!-- Filtro de status -->
        <select
          v-model="filters.status"
          @change="applyFilters"
          class="px-3 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
        >
          <option value="">Todos os status</option>
          <option value="ativo">Ativo</option>
          <option value="inativo">Inativo</option>
        </select>

        <!-- Filtro de cargo -->
        <select
          v-model="filters.cargo"
          @change="applyFilters"
          class="px-3 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
        >
          <option value="">Todos os cargos</option>
          <option value="Operador">Operador</option>
          <option value="Admin">Admin</option>
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

        <!-- Botão de adicionar operador -->
        <button
          @click="openAddUserModal"
          class="inline-flex items-center px-3 py-1.5 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-indigo-500 transition-colors"
        >
          <Plus class="w-4 h-4 mr-1" />
          Adicionar
        </button>

        <!-- Botão de atualizar -->
        <button
          @click="loadUsers"
          :disabled="loading"
          class="inline-flex items-center px-3 py-1.5 border border-zinc-300 dark:border-zinc-600 text-sm font-medium rounded-md text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-600 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-zinc-500 transition-colors disabled:opacity-50"
        >
          <RefreshCw class="w-4 h-4 mr-1" :class="{ 'animate-spin': loading }" />
          Atualizar
        </button>
      </div>
    </div>

    <!-- Lista de Operadores -->
    <div class="bg-white dark:bg-zinc-800 rounded-md shadow-sm overflow-hidden">
      <!-- Cabeçalho da tabela -->
      <div
        class="hidden md:grid grid-cols-12 gap-4 px-4 py-3 bg-zinc-50 dark:bg-zinc-700/30 border-b border-zinc-200 dark:border-zinc-700 text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide"
      >
        <div class="col-span-4">Nome</div>
        <div class="col-span-3">Email</div>
        <div class="col-span-2">Cargo</div>
        <div class="col-span-2">Status</div>
        <div class="col-span-1 text-right">Ações</div>
      </div>

      <!-- Loading state -->
      <div v-if="loading" class="p-6 text-center">
        <p class="text-zinc-500 dark:text-zinc-400">Carregando operadores...</p>
      </div>

      <!-- Empty state -->
      <div v-else-if="filteredUsers.length === 0" class="p-6 text-center">
        <p class="text-zinc-500 dark:text-zinc-400">Nenhum operador encontrado.</p>
      </div>

      <!-- Lista de Operadores -->
      <div v-else class="divide-y divide-zinc-200 dark:divide-zinc-700">
        <div
          v-for="user in paginatedUsers"
          :key="user.id"
          class="p-4 hover:bg-zinc-50 dark:hover:bg-zinc-700/20 transition-colors"
        >
          <!-- Versão mobile -->
          <div class="md:hidden">
            <div class="flex justify-between items-start">
              <div>
                <div class="flex items-center gap-2">
                  <h3 class="font-medium text-zinc-900 dark:text-white">{{ user.nome }}</h3>
                  <span
                    class="px-2 py-0.5 text-xs rounded-full"
                    :class="getStatusClass(user.ativo)"
                  >
                    {{ user.ativo ? 'Ativo' : 'Inativo' }}
                  </span>
                </div>
                <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">
                  {{ user.email }}
                </p>
                <p class="text-xs text-zinc-400 dark:text-zinc-500 mt-1">
                  {{ user.cargo }}
                </p>
              </div>
              <div class="flex gap-2">
                <button
                  @click.stop="openEditUserModal(user)"
                  class="text-indigo-600 dark:text-indigo-400 hover:text-indigo-800 dark:hover:text-indigo-300"
                >
                  <Edit class="w-4 h-4" />
                </button>
                <button
                  v-if="user.ativo"
                  @click.stop="deactivateUser(user.id)"
                  class="text-red-600 dark:text-red-400 hover:text-red-800 dark:hover:text-red-300"
                >
                  <UserX class="w-4 h-4" />
                </button>
                <button
                  v-else
                  @click.stop="reactivateUser(user.id)"
                  class="text-green-600 dark:text-green-400 hover:text-green-800 dark:hover:text-green-300"
                >
                  <UserCheck class="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>

          <!-- Versão desktop -->
          <div class="hidden md:grid grid-cols-12 gap-4 items-center">
            <div class="col-span-4 font-medium text-zinc-900 dark:text-white">
              {{ user.nome }}
            </div>
            <div class="col-span-3 text-zinc-500 dark:text-zinc-400">
              {{ user.email }}
            </div>
            <div class="col-span-2">
              <span
                :class="{
                  'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-100':
                    user.cargo === 'Admin',
                  'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-100':
                    user.cargo === 'Operador',
                }"
                class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
              >
                {{ user.cargo }}
              </span>
            </div>
            <div class="col-span-2">
              <span
                :class="getStatusClass(user.ativo)"
                class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
              >
                {{ user.ativo ? 'Ativo' : 'Inativo' }}
              </span>
            </div>
            <div class="col-span-1 flex justify-end gap-2">
              <button
                @click.stop="openEditUserModal(user)"
                class="text-indigo-600 dark:text-indigo-400 hover:text-indigo-800 dark:hover:text-indigo-300"
                title="Editar"
              >
                <Edit class="w-4 h-4" />
              </button>
              <button
                v-if="user.ativo"
                @click.stop="deactivateUser(user.id)"
                class="text-red-600 dark:text-red-400 hover:text-red-800 dark:hover:text-red-300"
                title="Desativar"
              >
                <UserX class="w-4 h-4" />
              </button>
              <button
                v-else
                @click.stop="reactivateUser(user.id)"
                class="text-green-600 dark:text-green-400 hover:text-green-800 dark:hover:text-green-300"
                title="Reativar"
              >
                <UserCheck class="w-4 h-4" />
              </button>
              <button
                @click.stop="openDeleteUserModal(user)"
                class="text-red-600 dark:text-red-400 hover:text-red-800 dark:hover:text-red-300"
                title="Deletar"
              >
                <Trash2 class="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Paginação -->
      <div
        v-if="filteredUsers.length > itemsPerPage"
        class="px-4 py-3 flex items-center justify-between border-t border-zinc-200 dark:border-zinc-700"
      >
        <div class="text-sm text-zinc-700 dark:text-zinc-300">
          Mostrando <span class="font-medium">{{ startIndex }}</span> a
          <span class="font-medium">{{ endIndex }}</span> de
          <span class="font-medium">{{ filteredUsers.length }}</span> resultados
        </div>
        <div class="flex gap-2">
          <button
            @click="previousPage"
            :disabled="currentPage === 1"
            class="px-3 py-1.5 text-sm font-medium rounded-md text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 border border-zinc-300 dark:border-zinc-600 hover:bg-zinc-50 dark:hover:bg-zinc-600 disabled:opacity-50"
          >
            Anterior
          </button>
          <button
            @click="nextPage"
            :disabled="currentPage * itemsPerPage >= filteredUsers.length"
            class="px-3 py-1.5 text-sm font-medium rounded-md text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 border border-zinc-300 dark:border-zinc-600 hover:bg-zinc-50 dark:hover:bg-zinc-600 disabled:opacity-50"
          >
            Próximo
          </button>
        </div>
      </div>
    </div>

    <!-- Modal para Adicionar/Editar Usuário -->
    <div
      v-if="showUserModal"
      class="fixed inset-0 bg-black/75 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      @click="closeUserModal"
    >
      <div class="bg-white dark:bg-zinc-800 rounded-lg shadow-xl w-full max-w-md" @click.stop>
        <div class="px-6 py-4 border-b border-zinc-200 dark:border-zinc-700">
          <h3 class="text-lg font-medium text-zinc-900 dark:text-white">
            {{ editingUser ? 'Editar Operador' : 'Adicionar Novo Operador' }}
          </h3>
        </div>
        <form @submit.prevent="saveUser" class="px-6 py-4">
          <div class="mb-4">
            <label
              for="nome"
              class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1"
              >Nome</label
            >
            <input
              v-model="userForm.nome"
              type="text"
              id="nome"
              required
              class="w-full px-3 py-2 border border-zinc-300 dark:border-zinc-600 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white"
            />
          </div>
          <div class="mb-4">
            <label
              for="email"
              class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1"
              >Email</label
            >
            <input
              v-model="userForm.email"
              type="email"
              id="email"
              required
              class="w-full px-3 py-2 border border-zinc-300 dark:border-zinc-600 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white"
            />
          </div>
          <div class="mb-4">
            <label
              for="cargo"
              class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1"
              >Cargo</label
            >
            <select
              v-model="userForm.cargo"
              id="cargo"
              required
              class="w-full px-3 py-2 border border-zinc-300 dark:border-zinc-600 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white"
            >
              <option value="Operador">Operador</option>
              <option value="Admin">Admin</option>
            </select>
          </div>
          <div class="flex justify-end space-x-3">
            <button
              type="button"
              @click="closeUserModal"
              class="px-4 py-2 text-sm font-medium text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 border border-zinc-300 dark:border-zinc-600 rounded-md hover:bg-zinc-50 dark:hover:bg-zinc-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Cancelar
            </button>
            <button
              type="submit"
              class="px-4 py-2 text-sm font-medium text-white bg-indigo-600 border border-transparent rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              {{ editingUser ? 'Atualizar' : 'Adicionar' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, computed } from 'vue'
import { Plus, Edit, UserX, UserCheck, Search, RefreshCw, Trash2 } from 'lucide-vue-next'
import { listDelegaciaUsers, updateDelegaciaUser, sendInvite, deactivateDelegaciaUser, reactivateDelegaciaUser, deleteAutoridade } from '@/services/http'
import { useToastStore } from '@/stores/toast'
import { useConfirmDialog } from '@/stores/confirm-dialog.store'

// Stores
const toast = useToastStore()

// Estado
const users = ref([])
const loading = ref(false)
const showUserModal = ref(false)
const editingUser = ref(false)
const userForm = ref({
  nome: '',
  email: '',
  cargo: 'Operador',
})

// Filtros e paginação
const filters = ref({
  search: '',
  status: '',
  cargo: '',
})

const currentPage = ref(1)
const itemsPerPage = ref(10)
let searchTimeout = ref(null)

// Propriedades computadas
const filteredUsers = computed(() => {
  let filtered = users.value

  // Filtro de busca
  if (filters.value.search) {
    const searchTerm = filters.value.search.toLowerCase()
    filtered = filtered.filter(
      (user) =>
        user.nome.toLowerCase().includes(searchTerm) ||
        user.email.toLowerCase().includes(searchTerm),
    )
  }

  // Filtro de status
  if (filters.value.status) {
    filtered = filtered.filter((user) => {
      if (filters.value.status === 'ativo') {
        return user.ativo
      } else if (filters.value.status === 'inativo') {
        return !user.ativo
      }
      return true
    })
  }

  // Filtro de cargo
  if (filters.value.cargo) {
    filtered = filtered.filter((user) => user.cargo === filters.value.cargo)
  }

  return filtered
})

const paginatedUsers = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage.value
  const end = start + itemsPerPage.value
  return filteredUsers.value.slice(start, end)
})

const startIndex = computed(() => {
  return (currentPage.value - 1) * itemsPerPage.value + 1
})

const endIndex = computed(() => {
  return Math.min(currentPage.value * itemsPerPage.value, filteredUsers.value.length)
})

// Funções
const loadUsers = async () => {
  try {
    loading.value = true
    const response = await listDelegaciaUsers()
    users.value = response.data
    applyFilters() // Aplicar filtros após carregar os dados
  } catch (error) {
    console.error('Erro ao buscar usuários:', error)
    toast.error('Erro ao carregar lista de operadores')
  } finally {
    loading.value = false
  }
}

const applyFilters = () => {
  currentPage.value = 1 // Resetar para a primeira página
}

const debounceSearch = () => {
  clearTimeout(searchTimeout.value)
  searchTimeout.value = setTimeout(() => {
    applyFilters()
  }, 300)
}

const getStatusClass = (ativo) => {
  if (ativo) {
    return 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
  } else {
    return 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300'
  }
}

const openAddUserModal = () => {
  editingUser.value = false
  userForm.value = { nome: '', email: '', cargo: 'Operador' }
  showUserModal.value = true
}

const openEditUserModal = (user) => {
  editingUser.value = true
  userForm.value = { ...user }
  showUserModal.value = true
}

const closeUserModal = () => {
  showUserModal.value = false
}

const openDeleteUserModal = async (user) => {
  const confirmDialog = useConfirmDialog()
  const confirm = await confirmDialog.confirm({
    titulo: 'Deletar Operador',
    mensagem: `Tem certeza que deseja deletar o operador "${user.nome}"? Esta ação não pode ser desfeita.`
  })

  if (confirm) {
    try {
      await deleteAutoridade(user.id)
      toast.success('Operador deletado com sucesso!')
      loadUsers() // Atualizar lista
    } catch (error) {
      console.error('Erro ao deletar usuário:', error)
      toast.error('Erro ao deletar operador')
    }
  }
}

const saveUser = async () => {
  try {
    if (editingUser.value) {
      // Editar usuário existente
      // Enviar apenas os campos que podem ser atualizados
      const { nome, email, cargo } = userForm.value
      await updateDelegaciaUser(userForm.value.id, { nome, email, cargo })
      toast.success('Operador atualizado com sucesso!')
    } else {
      // Adicionar novo usuário (enviar convite)
      await sendInvite({
        ...userForm.value,
        delegacia_id: 1, // TODO: Obter ID da delegacia do usuário logado
      })
      toast.success('Convite enviado com sucesso!')
    }
    closeUserModal()
    loadUsers() // Atualizar lista
  } catch (error) {
    console.error('Erro ao salvar usuário:', error)
    toast.error('Erro ao salvar operador')
  }
}

const deactivateUser = async (userId) => {
  try {
    await deactivateDelegaciaUser(userId)
    toast.success('Operador desativado com sucesso!')
    loadUsers() // Atualizar lista
  } catch (error) {
    console.error('Erro ao desativar usuário:', error)
    toast.error('Erro ao desativar operador')
  }
}

const reactivateUser = async (userId) => {
  try {
    await reactivateDelegaciaUser(userId)
    toast.success('Operador reativado com sucesso!')
    loadUsers() // Atualizar lista
  } catch (error) {
    console.error('Erro ao reativar usuário:', error)
    toast.error('Erro ao reativar operador')
  }
}

// Navegação de página
const previousPage = () => {
  if (currentPage.value > 1) {
    currentPage.value--
  }
}

const nextPage = () => {
  if (currentPage.value * itemsPerPage.value < filteredUsers.value.length) {
    currentPage.value++
  }
}

// Lifecycle
onMounted(() => {
  loadUsers()
})

onBeforeUnmount(() => {
  clearTimeout(searchTimeout.value)
})
</script>

<style scoped>
/* Adicione estilos específicos do componente aqui, se necessário */
</style>
