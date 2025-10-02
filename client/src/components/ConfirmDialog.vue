<template>
  <transition name="fade-scale">
    <div
      v-if="dialog.isOpen"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm"
      role="dialog"
      aria-modal="true"
      :aria-labelledby="'dialog-title'"
      :aria-describedby="'dialog-desc'"
    >
      <div
        class="bg-white dark:bg-zinc-900 text-zinc-900 dark:text-zinc-100 w-full max-w-md rounded-2xl shadow-2xl px-6 py-6 sm:px-8 sm:py-7 relative"
        tabindex="-1"
      >
        <div class="flex items-center gap-3 mb-4">
          <svg class="text-yellow-500 w-7 h-7 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
          <h2 id="dialog-title" class="text-xl font-semibold leading-snug">
            {{ dialog.title }}
          </h2>
        </div>

        <p id="dialog-desc" class="text-sm text-zinc-700 dark:text-zinc-300 mb-6 leading-relaxed">
          {{ dialog.message }}
        </p>

        <div class="flex justify-end gap-3">
          <button
            @click="dialog.cancel"
            class="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-zinc-100 dark:bg-zinc-700 hover:bg-zinc-200 dark:hover:bg-zinc-600 text-sm font-medium transition"
          >
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
            Cancelar
          </button>

          <button
            @click="dialog.accept"
            class="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold shadow-md transition focus:outline-none focus:ring-2 focus:ring-indigo-400"
          >
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Confirmar
          </button>
        </div>

        <!-- Botão de fechar opcional -->
        <button
          @click="dialog.cancel"
          class="absolute top-3 right-3 text-zinc-500 hover:text-zinc-800 dark:hover:text-white transition"
          aria-label="Fechar"
        >
          <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { useConfirmDialog } from '@/stores/confirm-dialog.store'

const dialog = useConfirmDialog()
</script>

<style scoped>
.fade-scale-enter-active,
.fade-scale-leave-active {
  transition: all 0.25s ease;
}
.fade-scale-enter-from,
.fade-scale-leave-to {
  opacity: 0;
  transform: scale(0.95);
}
</style>