import { defineStore } from 'pinia'

export const useModalStore = defineStore('modal', {
  state: () => ({
    isOpen: false,
    title: 'Confirmação',
    message: 'Tem certeza que deseja continuar?',
    type: 'info', // 'info', 'warning', 'danger'
    confirmText: 'Confirmar',
    cancelText: 'Cancelar',
    showConfirmButton: true,
    showCancelButton: true,
    loading: false,
    onConfirm: null,
    onCancel: null
  }),

  actions: {
    open(options = {}) {
      this.isOpen = true
      this.title = options.title || this.title
      this.message = options.message || this.message
      this.type = options.type || this.type
      this.confirmText = options.confirmText || this.confirmText
      this.cancelText = options.cancelText || this.cancelText
      this.showConfirmButton = options.showConfirmButton !== undefined ? options.showConfirmButton : this.showConfirmButton
      this.showCancelButton = options.showCancelButton !== undefined ? options.showCancelButton : this.showCancelButton
      this.loading = options.loading || this.loading
      this.onConfirm = options.onConfirm || null
      this.onCancel = options.onCancel || null
    },

    close() {
      this.isOpen = false
      this.title = 'Confirmação'
      this.message = 'Tem certeza que deseja continuar?'
      this.type = 'info'
      this.confirmText = 'Confirmar'
      this.cancelText = 'Cancelar'
      this.showConfirmButton = true
      this.showCancelButton = true
      this.loading = false
      this.onConfirm = null
      this.onCancel = null
    },

    setLoading(loading) {
      this.loading = loading
    },

    async confirm() {
      if (this.onConfirm) {
        this.setLoading(true)
        try {
          await this.onConfirm()
          this.close()
        } finally {
          this.setLoading(false)
        }
      } else {
        this.close()
      }
    },

    cancel() {
      if (this.onCancel) {
        this.onCancel()
      }
      this.close()
    }
  }
})