import { computed } from 'vue'
import { useUserStore } from '@/stores/user'
import { login as httpLogin, logout as httpLogout } from '@/services/http'

export function useAuth() {
  const userStore = useUserStore()
  
  const isAuthenticated = computed(() => userStore.isAuthenticated)
  const isUnidade = computed(() => userStore.cargo === 'Unidade')

  const login = async (email, senha) => {
    const authData = await httpLogin({ email, senha })
    userStore.setUser(authData.user)
    return authData
  }

  const logout = () => {
    httpLogout()
    userStore.clearUser()
  }

  const refreshUser = () => {
    userStore.loadUserFromStorage()
  }

  return {
    user: computed(() => userStore.user),
    isAuthenticated,
    isUnidade,
    login,
    logout,
    refreshUser
  }
}
