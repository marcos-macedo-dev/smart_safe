<template>
  <header
    class="flex items-center justify-between h-14 sm:h-16 bg-white dark:bg-zinc-900 px-4 border-b border-zinc-200 dark:border-zinc-800 transition-colors duration-300"
  >
    <!-- Logo -->
    <div
      class="font-bold text-lg sm:text-xl text-zinc-800 dark:text-zinc-100 tracking-tight flex items-center gap-2"
    >
      <div
        class="bg-indigo-600 text-white w-8 h-8 rounded-lg flex items-center justify-center text-sm font-bold shadow-sm"
      >
        S
      </div>
      <span class="hidden sm:inline">Smart<span class="text-indigo-500">Safe</span></span>
    </div>

    <!-- Ações -->
    <div class="flex items-center gap-2 sm:gap-3">
      <!-- Dark mode toggle -->
      <button
        @click="toggleDark()"
        class="text-zinc-500 hover:text-indigo-500 dark:hover:text-indigo-400 transition-colors p-2 rounded-full hover:bg-zinc-100 dark:hover:bg-zinc-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-zinc-900"
        :aria-label="isDark ? 'Alternar para modo claro' : 'Alternar para modo escuro'"
      >
        <Moon v-if="isDark" class="w-5 h-5" />
        <Sun v-else class="w-5 h-5" />
      </button>

      <!-- Perfil -->
      <div class="relative">
        <button
          @click="toggleProfileDropdown"
          class="flex items-center gap-2 cursor-pointer hover:bg-zinc-100 dark:hover:bg-zinc-800 px-2 py-1 rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-zinc-900"
          ref="profileButton"
          aria-haspopup="true"
          :aria-expanded="showProfileDropdown"
          aria-label="Menu do usuário"
        >
          <div
            class="bg-indigo-600 text-white w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold"
          >
            {{ userInitials }}
          </div>
          <div class="hidden md:flex flex-col items-start">
            <span class="text-sm font-medium text-zinc-700 dark:text-zinc-200 truncate max-w-[120px]">
              {{ user?.nome || 'Usuário' }}
            </span>
            <span class="text-xs text-zinc-500 dark:text-zinc-400 truncate max-w-[120px]">
              {{ user?.cargo || 'Cargo' }}
            </span>
          </div>
          <ChevronDown
            class="hidden md:inline w-4 h-4 text-zinc-500 transition-transform duration-200"
            :class="{ 'rotate-180': showProfileDropdown }"
          />
        </button>

        <!-- Dropdown de perfil -->
        <transition
          enter-active-class="transition duration-150 ease-out"
          enter-from-class="translate-y-1 opacity-0 scale-95"
          enter-to-class="translate-y-0 opacity-100 scale-100"
          leave-active-class="transition duration-100 ease-in"
          leave-from-class="translate-y-0 opacity-100 scale-100"
          leave-to-class="translate-y-1 opacity-0 scale-95"
        >
          <div
            v-if="showProfileDropdown"
            class="absolute right-0 mt-1.5 w-56 bg-white dark:bg-zinc-800 rounded-lg shadow-lg border border-zinc-200 dark:border-zinc-700 z-50 py-1"
            ref="profileDropdown"
            role="menu"
            aria-orientation="vertical"
            aria-labelledby="profile-button"
          >
            <!-- Header do perfil -->
            <div class="px-3 py-2.5 border-b border-zinc-100 dark:border-zinc-700">
              <div class="flex items-center gap-2.5">
                <div class="bg-indigo-600 text-white w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold">
                  {{ userInitials }}
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium text-zinc-800 dark:text-zinc-100 truncate">
                    {{ user?.nome || 'Usuário' }}
                  </p>
                  <p class="text-xs text-zinc-500 dark:text-zinc-400 truncate">
                    {{ user?.email || 'email@smartsafe.com' }}
                  </p>
                </div>
              </div>
            </div>

            <!-- Opções do menu -->
            <div class="py-1">
              <RouterLink
                to="/profile"
                class="flex items-center px-3 py-2 text-sm text-zinc-700 dark:text-zinc-200 hover:bg-zinc-100 dark:hover:bg-zinc-700/30"
                role="menuitem"
                @click="showProfileDropdown = false"
              >
                <User class="w-4 h-4 mr-2 flex-shrink-0 text-zinc-500 dark:text-zinc-400" />
                <span class="truncate">Meu Perfil</span>
              </RouterLink>

              <RouterLink
                v-if="user?.cargo === 'Unidade'"
                to="/users"
                class="flex items-center px-3 py-2 text-sm text-zinc-700 dark:text-zinc-200 hover:bg-zinc-100 dark:hover:bg-zinc-700/30"
                role="menuitem"
                @click="showProfileDropdown = false"
              >
                <Users class="w-4 h-4 mr-2 flex-shrink-0 text-zinc-500 dark:text-zinc-400" />
                <span class="truncate">Gerenciar Usuários</span>
              </RouterLink>

              <RouterLink
                to="/dashboard"
                class="flex items-center px-3 py-2 text-sm text-zinc-700 dark:text-zinc-200 hover:bg-zinc-100 dark:hover:bg-zinc-700/30"
                role="menuitem"
                @click="showProfileDropdown = false"
              >
                <BarChart3 class="w-4 h-4 mr-2 flex-shrink-0 text-zinc-500 dark:text-zinc-400" />
                <span class="truncate">Dashboard</span>
              </RouterLink>
            </div>

            <div class="py-1 border-t border-zinc-100 dark:border-zinc-700">
              <button
                @click="handleLogout"
                class="w-full flex items-center px-3 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 text-left"
                role="menuitem"
              >
                <LogOut class="w-4 h-4 mr-2 flex-shrink-0" />
                <span class="truncate">Sair</span>
              </button>
            </div>
          </div>
        </transition>
      </div>
    </div>
  </header>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { Moon, Sun, User, LogOut, ChevronDown, BarChart3, Users } from 'lucide-vue-next'
import { useDark, useToggle } from '@vueuse/core'
import { useUserStore } from '@/stores/user'
import { useRouter } from 'vue-router'
import { logout } from '@/services/http'

// estado reativo para dark mode
const isDark = useDark({
  storageKey: 'smart-safe-theme', // salva no localStorage
  valueDark: 'dark',
  valueLight: 'light',
})

// função para alternar
const toggleDark = useToggle(isDark)

// store do usuário
const userStore = useUserStore()
const router = useRouter()

// carregar usuário do storage
userStore.loadUserFromStorage()

// computed para obter o usuário
const user = computed(() => userStore.user)

// computed para obter as iniciais do usuário
const userInitials = computed(() => {
  if (!user.value?.nome) return 'U'
  return user.value.nome
    .split(' ')
    .map((n) => n[0])
    .join('')
    .substring(0, 2)
    .toUpperCase()
})

// estado para o dropdown de perfil
const showProfileDropdown = ref(false)
const profileButton = ref(null)
const profileDropdown = ref(null)

// função para alternar visibilidade do dropdown de perfil
const toggleProfileDropdown = () => {
  showProfileDropdown.value = !showProfileDropdown.value
}

// função para fazer logout
const handleLogout = async () => {
  try {
    await logout()
    userStore.clearUser()
    router.replace('/login')
  } catch (error) {
    console.error('Erro ao fazer logout:', error)
  }
}

// função para fechar dropdown ao clicar fora
const handleClickOutside = (event) => {
  if (
    showProfileDropdown.value &&
    profileButton.value &&
    profileDropdown.value &&
    !profileButton.value.contains(event.target) &&
    !profileDropdown.value.contains(event.target)
  ) {
    showProfileDropdown.value = false
  }
}

// adicionar/remover event listeners
onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
