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
      class="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      @click="closeUserModal"
      @keydown.escape.prevent.stop="closeUserModal"
      tabindex="-1"
    >
      <div
        class="bg-white dark:bg-zinc-800 rounded-xl shadow-2xl w-full max-w-lg border border-zinc-200/60 dark:border-zinc-700/60"
        role="dialog"
        aria-modal="true"
        aria-labelledby="user-modal-title"
        @click.stop
      >
        <div class="px-6 py-4 border-b border-zinc-200 dark:border-zinc-700 flex items-start justify-between gap-4">
          <div>
            <h3 id="user-modal-title" class="text-lg font-semibold text-zinc-900 dark:text-white">
              {{ editingUser ? 'Editar Operador' : 'Adicionar Novo Operador' }}
            </h3>
            <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
              {{ editingUser
                ? 'Atualize os dados do operador selecionado. As alterações são sincronizadas imediatamente.'
                : 'Informe os dados básicos para enviar o convite de acesso ao novo operador.'
              }}
            </p>
          </div>
          <button
            type="button"
            class="text-zinc-400 hover:text-zinc-600 dark:text-zinc-500 dark:hover:text-zinc-300 transition-colors"
            @click="closeUserModal"
            aria-label="Fechar modal"
          >
            <X class="w-5 h-5" />
          </button>
        </div>
        <form @submit.prevent="saveUser" class="px-6 py-5 space-y-5">
          <div class="grid gap-4">
            <div>
              <label for="nome" class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Nome completo</label>
              <input
                v-model.trim="userForm.nome"
                type="text"
                id="nome"
                required
                autofocus
                @input="clearFieldError('nome')"
                :aria-invalid="Boolean(formErrors.nome)"
                :aria-describedby="formErrors.nome ? 'nome-error' : undefined"
                class="w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white transition-colors"
                :class="formErrors.nome
                  ? 'border-red-500 focus:ring-red-500 focus:border-red-500'
                  : 'border-zinc-300 dark:border-zinc-600'
                "
                placeholder="Ex.: Maria Silva"
              />
              <p v-if="formErrors.nome" id="nome-error" class="mt-1 text-xs text-red-500">
                {{ formErrors.nome }}
              </p>
              <p v-else class="mt-1 text-xs text-zinc-500 dark:text-zinc-400">
                Informe como o nome deve aparecer para os demais operadores.
              </p>
            </div>
            <div>
              <label for="email" class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Email corporativo</label>
              <input
                v-model.trim="userForm.email"
                type="email"
                id="email"
                required
                @input="clearFieldError('email')"
                :aria-invalid="Boolean(formErrors.email)"
                :aria-describedby="formErrors.email ? 'email-error' : 'email-hint'"
                class="w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white transition-colors"
                :class="formErrors.email
                  ? 'border-red-500 focus:ring-red-500 focus:border-red-500'
                  : 'border-zinc-300 dark:border-zinc-600'
                "
                placeholder="nome@delegacia.gov.br"
              />
              <p v-if="formErrors.email" id="email-error" class="mt-1 text-xs text-red-500">
                {{ formErrors.email }}
              </p>
              <p v-else id="email-hint" class="mt-1 text-xs text-zinc-500 dark:text-zinc-400">
                O convite será enviado para este endereço.
              </p>
            </div>
            <div>
              <label for="cargo" class="block text-sm font-medium text-zinc-700 dark:text-zinc-300 mb-1">Cargo</label>
              <div
                id="cargo"
                class="grid grid-cols-1 sm:grid-cols-2 gap-2"
                role="radiogroup"
                aria-label="Selecione o cargo"
              >
                <button
                  v-for="option in roleOptions"
                  :key="option.value"
                  type="button"
                  @click="setRole(option.value)"
                  role="radio"
                  :aria-checked="userForm.cargo === option.value"
                  class="flex items-center justify-between gap-2 rounded-md border px-3 py-2 text-sm transition-all"
                  :class="userForm.cargo === option.value
                    ? 'border-indigo-500 bg-indigo-50 text-indigo-700 dark:border-indigo-400 dark:bg-indigo-500/10 dark:text-indigo-200'
                    : 'border-zinc-300 text-zinc-600 hover:border-indigo-300 hover:text-indigo-600 dark:border-zinc-600 dark:text-zinc-300 dark:hover:border-indigo-400'
                  "
                >
                  <span class="font-medium">
                    {{ option.label }}
                  </span>
                  <span class="text-xs text-zinc-400 dark:text-zinc-500">{{ option.description }}</span>
                </button>
              </div>
              <p v-if="formErrors.cargo" class="mt-1 text-xs text-red-500">
                {{ formErrors.cargo }}
              </p>
            </div>
          </div>

          <div class="rounded-md border border-indigo-100 bg-indigo-50 px-4 py-3 text-sm text-indigo-700 dark:border-indigo-500/30 dark:bg-indigo-500/10 dark:text-indigo-200 flex items-start gap-3">
            <div class="mt-1 h-2 w-2 rounded-full bg-indigo-500 dark:bg-indigo-300"></div>
            <div>
              <p class="font-medium">Como funciona?</p>
              <p class="mt-1 leading-relaxed">
                {{ editingUser
                  ? 'As alterações entram em vigor imediatamente para este operador.'
                  : 'Enviaremos um email com link de ativação. O operador só terá acesso após aceitar o convite.'
                }}
              </p>
            </div>
          </div>

          <div class="flex flex-col sm:flex-row sm:justify-end sm:items-center gap-3 pt-4 border-t border-zinc-200 dark:border-zinc-700">
            <button
              type="button"
              @click="closeUserModal"
              class="w-full sm:w-auto px-4 py-2 text-sm font-medium text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 border border-zinc-300 dark:border-zinc-600 rounded-md hover:bg-zinc-50 dark:hover:bg-zinc-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Cancelar
            </button>
            <button
              type="submit"
              :disabled="saving"
              class="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-white bg-indigo-600 border border-transparent rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-60 disabled:cursor-not-allowed"
            >
              <Loader2 v-if="saving" class="w-4 h-4 animate-spin" />
              {{ saving ? 'Salvando...' : editingUser ? 'Atualizar' : 'Enviar convite' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, computed } from 'vue'
import { Plus, Edit, UserX, UserCheck, Search, RefreshCw, Trash2, X, Loader2 } from 'lucide-vue-next'
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
const saving = ref(false)
const formErrors = ref({})

const roleOptions = [
  {
    label: 'Operador',
    value: 'Operador',
    description: 'Acesso às ocorrências da delegacia',
  },
  {
    label: 'Admin',
    value: 'Admin',
    description: 'Gerencia operadores e configurações',
  },
]

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
  formErrors.value = {}
  saving.value = false
  showUserModal.value = true
}

const openEditUserModal = (user) => {
  editingUser.value = true
  userForm.value = { ...user }
  formErrors.value = {}
  saving.value = false
  showUserModal.value = true
}

const closeUserModal = () => {
  showUserModal.value = false
  saving.value = false
  formErrors.value = {}
}

const setRole = (role) => {
  userForm.value.cargo = role
  clearFieldError('cargo')
}

const clearFieldError = (field) => {
  if (formErrors.value[field]) {
    const { [field]: _removed, ...rest } = formErrors.value
    formErrors.value = rest
  }
}

const validateUserForm = () => {
  const errors = {}

  if (!userForm.value.nome || userForm.value.nome.trim().length < 3) {
    errors.nome = 'Informe pelo menos 3 caracteres.'
  }

  const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/
  if (!userForm.value.email || !emailPattern.test(userForm.value.email)) {
    errors.email = 'Digite um email corporativo válido.'
  }

  if (!userForm.value.cargo) {
    errors.cargo = 'Selecione um cargo.'
  }

  formErrors.value = errors
  return Object.keys(errors).length === 0
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
  if (!validateUserForm() || saving.value) {
    return
  }

  try {
    saving.value = true
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
  } finally {
    saving.value = false
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
