import { ref } from 'vue'
import { defineStore } from 'pinia'

export const useToastStore = defineStore('toast', () => {
  const toasts = ref([])

  function success(message, options) {
    addToast(message, 'success', options)
  }

  function error(message, options) {
    addToast(message, 'error', options)
  }

  function warning(message, options) {
    addToast(message, 'warning', options)
  }

  function info(message, options) {
    addToast(message, 'info', options)
  }

  function addToast(message, type = 'info', options = {}) {
    const id = Date.now() + Math.random()
    const duration = Number.isFinite(options.duration) ? options.duration : 5000

    const toast = {
      id,
      message,
      type,
      duration,
      createdAt: Date.now(),
    }

    toasts.value.push(toast)

    const timeoutId = setTimeout(() => {
      removeToast(id)
    }, duration)

    // Guard against lingering timers after manual dismissal
    toast.cleanup = () => clearTimeout(timeoutId)
  }

  function removeToast(id) {
    const index = toasts.value.findIndex((toast) => toast.id === id)
    if (index !== -1) {
      const [toast] = toasts.value.splice(index, 1)
      toast?.cleanup?.()
    }
  }

  return { toasts, success, error, warning, info, addToast, removeToast }
})
