import { defineStore } from 'pinia'

const TOKEN_KEY = 'authToken'
const USER_KEY = 'authUser'

export const useUserStore = defineStore('user', {
  state: () => ({
    currentUser: null
  }),
  
  getters: {
    isAuthenticated: (state) => !!state.currentUser,
    user: (state) => state.currentUser,
    cargo: (state) => {
      if (!state.currentUser) return null
      // Retorna o cargo explícito ou o tipo de usuário como fallback
      return state.currentUser.cargo || state.currentUser.tipo || null
    }
  },
  
  actions: {
    setUser(user) {
      console.log('UserStore: Setting user:', user)
      this.currentUser = user
      if (user) {
        localStorage.setItem(USER_KEY, JSON.stringify(user))
      }
    },
    
    loadUserFromStorage() {
      const token = localStorage.getItem(TOKEN_KEY)
      if (token) {
        const user = localStorage.getItem(USER_KEY)
        this.setUser(user ? JSON.parse(user) : null)
      } else {
        this.currentUser = null
      }
    },
    
    clearUser() {
      this.currentUser = null
      localStorage.removeItem(USER_KEY)
    }
  }
})