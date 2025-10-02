import { ref } from 'vue'
import { defineStore } from 'pinia'

export const useToastStore = defineStore('toast', () => {
  const toasts = ref([])

  function success(message) {
    addToast(message, 'success')
  }

  function error(message) {
    addToast(message, 'error')
  }

  function warning(message) {
    addToast(message, 'warning')
  }

  function info(message) {
    addToast(message, 'info')
  }

  function addToast(message, type = 'info') {
    const id = Date.now() + Math.random()
    toasts.value.push({ id, message, type })
    
    // Auto remove toast after 5 seconds
    setTimeout(() => {
      removeToast(id)
    }, 5000)
  }

  function removeToast(id) {
    const index = toasts.value.findIndex(toast => toast.id === id)
    if (index !== -1) {
      toasts.value.splice(index, 1)
    }
  }

  return { toasts, success, error, warning, info, addToast, removeToast }
})