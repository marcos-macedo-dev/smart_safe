import { computed } from 'vue'
import { useUserStore } from '@/stores/user'
import { login as httpLogin, logout as httpLogout } from '@/services/http'

export function useAuth() {
  const userStore = useUserStore()
  
  const isAuthenticated = computed(() => userStore.isAuthenticated)
  const isAdmin = computed(() => userStore.cargo === 'Admin')

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
    isAdmin,
    login,
    logout,
    refreshUser
  }
}
