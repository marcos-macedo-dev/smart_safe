<template>
  <aside
    class="bg-white dark:bg-zinc-900 border-r border-zinc-200 dark:border-zinc-800 text-zinc-600 dark:text-zinc-400 h-screen transition-all duration-300 ease-in-out shadow-sm"
    :class="collapsed ? 'w-16' : 'w-52'"
  >
    <div class="flex flex-col h-full">
      <!-- Header -->
      <div
        class="flex items-center gap-3 p-4 border-b border-zinc-200 dark:border-zinc-800 transition-all duration-300"
        :class="{ 'justify-center': collapsed }"
      >
        <div
          class="bg-indigo-600 text-white w-9 h-9 rounded-lg flex items-center justify-center font-bold text-sm shadow-sm"
        >
          S
        </div>
        <transition
          enter-active-class="transition duration-300 ease-out"
          enter-from-class="opacity-0 translate-x-2"
          enter-to-class="opacity-100 translate-x-0"
          leave-active-class="transition duration-200 ease-in"
          leave-from-class="opacity-100 translate-x-0"
          leave-to-class="opacity-0 -translate-x-2"
        >
          <span v-if="!collapsed" class="font-bold text-lg text-zinc-800 dark:text-zinc-100 whitespace-nowrap">
            Smart<span class="text-indigo-500">Safe</span>
          </span>
        </transition>
      </div>

      <!-- Collapse Button -->
      <div
        class="flex items-center justify-center p-2 my-2 cursor-pointer hover:bg-zinc-100 dark:hover:bg-zinc-800 rounded-lg transition-colors duration-200 group"
        @click="collapsed = !collapsed"
        aria-label="Alternar sidebar"
      >
        <ChevronsLeft 
          v-if="!collapsed" 
          class="w-5 h-5 text-zinc-500 dark:text-zinc-400 group-hover:text-zinc-700 dark:group-hover:text-zinc-300 transition-colors" 
        />
        <ChevronsRight 
          v-else 
          class="w-5 h-5 text-zinc-500 dark:text-zinc-400 group-hover:text-zinc-700 dark:group-hover:text-zinc-300 transition-colors" 
        />
      </div>

      <!-- Navigation -->
      <nav class="flex-1 mt-4 px-2">
        <ul class="space-y-1">
          <li v-for="item in filteredMenu" :key="item.name">
            <router-link
              :to="item.path"
              class="flex items-center gap-3 px-3 py-3 rounded-lg transition-all duration-200 hover:bg-zinc-100 dark:hover:bg-zinc-800 relative group"
              :class="{
                'justify-center': collapsed,
                'bg-indigo-50 text-indigo-700 dark:bg-indigo-500/20 dark:text-indigo-300 shadow-inner':
                  route.name === item.name,
              }"
              :title="collapsed ? item.label : undefined"
            >
              <component 
                :is="item.icon" 
                class="w-5 h-5 flex-shrink-0 transition-transform group-hover:scale-110" 
              />
              <transition
                enter-active-class="transition duration-300 ease-out"
                enter-from-class="opacity-0 translate-x-2"
                enter-to-class="opacity-100 translate-x-0"
                leave-active-class="transition duration-200 ease-in"
                leave-from-class="opacity-100 translate-x-0"
                leave-to-class="opacity-0 -translate-x-2"
              >
                <span v-if="!collapsed" class="font-medium text-sm">{{ item.label }}</span>
              </transition>

              <!-- Notification badge -->
              <transition
                enter-active-class="transition duration-300 ease-out"
                enter-from-class="opacity-0 scale-0"
                enter-to-class="opacity-100 scale-100"
                leave-active-class="transition duration-200 ease-in"
                leave-from-class="opacity-100 scale-100"
                leave-to-class="opacity-0 scale-0"
              >
                <div
                  v-if="item.name === 'sos' && sosNotificationCount > 0 && !collapsed"
                  class="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center shadow-sm"
                >
                  {{ sosNotificationCount > 99 ? '99+' : sosNotificationCount }}
                </div>
                
                <div
                  v-else-if="item.name === 'sos' && sosNotificationCount > 0 && collapsed"
                  class="absolute top-1 right-1 bg-red-500 text-white text-xs rounded-full h-2.5 w-2.5 flex items-center justify-center shadow-sm"
                ></div>
              </transition>
            </router-link>
          </li>
        </ul>
      </nav>

      <!-- Footer (logout) -->
      <div class="p-3 border-t border-zinc-200 dark:border-zinc-800">
        <div
          class="flex items-center gap-3 cursor-pointer hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg p-3 transition-all duration-200 group"
          :class="{ 'justify-center': collapsed }"
          @click="handleLogout"
          aria-label="Sair"
        >
          <LogOut 
            class="w-5 h-5 text-red-500 dark:text-red-400 transition-transform group-hover:scale-110" 
          />
          <transition
            enter-active-class="transition duration-300 ease-out"
            enter-from-class="opacity-0 translate-x-2"
            enter-to-class="opacity-100 translate-x-0"
            leave-active-class="transition duration-200 ease-in"
            leave-from-class="opacity-100 translate-x-0"
            leave-to-class="opacity-0 -translate-x-2"
          >
            <span v-if="!collapsed" class="text-sm font-medium text-red-500 dark:text-red-400">Sair</span>
          </transition>
        </div>
      </div>
    </div>
  </aside>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  Home,
  Map,
  AlertTriangle,
  Users,
  BarChart,
  LogOut,
  ChevronsLeft,
  ChevronsRight,
} from 'lucide-vue-next'
import { logout } from '@/services/http'
import { useUserStore } from '@/stores/user'
import socket from '@/services/socket'
import notificationService from '@/services/notification'

const collapsed = ref(true)
const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

// Load user from storage on component mount
userStore.loadUserFromStorage()

// SOS notification count
const sosNotificationCount = ref(0)

// Menu items
const menuItems = [
  // Página inicial
  {
    label: 'Dashboard',
    icon: Home,
    path: '/dashboard',
    name: 'dashboard',
    cargos: ['Unidade', 'Agente'],
  },

  // Navegação principal
  {
    label: 'Mapa',
    icon: Map,
    path: '/map',
    name: 'map',
    cargos: ['Unidade', 'Agente'],
  },
  {
    label: 'SOS',
    icon: AlertTriangle,
    path: '/sos',
    name: 'sos',
    cargos: ['Unidade', 'Agente'],
  },

  // Gestão de usuários
  {
    label: 'Usuários',
    icon: Users,
    path: '/users',
    name: 'users',
    cargos: ['Unidade'],
  },

  // Relatórios e análises
  {
    label: 'Relatórios',
    icon: BarChart,
    path: '/reports',
    name: 'reports',
    cargos: ['Unidade'],
  },
]

// Filter menu based on user role
const filteredMenu = computed(() => {
  if (!userStore.isAuthenticated) return []

  // Filter menu items based on user cargo
  return menuItems.filter((item) => item.cargos.includes(userStore.cargo))
})

// Adicionar esta variável para rastrear notificações recentes no sidebar também
const recentSosNotificationsSidebar = new Set();
const RECENT_SOS_TIMEOUT_SIDEBAR = 10000; // 10 segundos

// Listen for new SOS events
const handleNewSos = (novoSos) => {
  // Verificar se já notificamos sobre este SOS recentemente
  if (recentSosNotificationsSidebar.has(novoSos.id)) {
    return;
  }
  
  // Adicionar ao conjunto de notificações recentes
  recentSosNotificationsSidebar.add(novoSos.id);
  
  // Remover após o tempo limite
  setTimeout(() => {
    recentSosNotificationsSidebar.delete(novoSos.id);
  }, RECENT_SOS_TIMEOUT_SIDEBAR);

  console.log('Recebido novo SOS no sidebar:', novoSos)

  // Only increment notification count if user is NOT on the SOS page
  if (route.name !== 'sos') {
    sosNotificationCount.value++
    console.log('Contagem de notificações atualizada para:', sosNotificationCount.value)
  }
  
  // Only show notification if user is NOT on the SOS page
  // The SosView component handles notifications when user is on the SOS page
  if (route.name !== 'sos') {
    notificationService.notifyNewSos(novoSos)
  }
}

// Reset notification count when user visits SOS page
const resetSosNotificationCount = () => {
  sosNotificationCount.value = 0
}

// Watch for notification count changes
watch(sosNotificationCount, (newCount) => {
  console.log('Contagem de notificações alterada para:', newCount)
})

// Watch for route changes
watch(
  () => route.name,
  (newRouteName) => {
    // If user enters the SOS page, reset the notification count
    if (newRouteName === 'sos') {
      resetSosNotificationCount()
    }
  },
)

onMounted(() => {
  // Listen for new SOS events
  socket.on('novo_sos', handleNewSos);
  socket.on('novo_sos_nao_roteado', handleNewSos);
  socket.on('novo_sos_global', handleNewSos);

  // Reset notification count if user is already on SOS page when component mounts
  if (route.name === 'sos') {
    resetSosNotificationCount();
  }
});

onBeforeUnmount(() => {
  // Remove event listeners
  socket.off('novo_sos', handleNewSos);
  socket.off('novo_sos_nao_roteado', handleNewSos);
  socket.off('novo_sos_global', handleNewSos);
});

const handleLogout = async () => {
  try {
    await logout()
    userStore.clearUser()
    router.replace('/login')
  } catch (error) {
    console.error('Erro ao fazer logout:', error)
  }
}
</script>
