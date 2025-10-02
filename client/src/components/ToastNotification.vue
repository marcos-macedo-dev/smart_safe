<template>
  <div class="fixed top-4 right-4 space-y-3 z-[1100]">
    <TransitionGroup name="toast" tag="div">
      <div
        v-for="toast in visibleToasts"
        :key="toast.id"
        :class="[
          'flex items-start p-4 rounded-md shadow-xl max-w-sm w-full transform transition-all duration-300 border backdrop-blur-sm',
          {
            'bg-white/95 border-zinc-200 dark:bg-zinc-800/95 dark:border-zinc-700':
              toast.type === 'info',
            'bg-green-50/95 border-green-200 dark:bg-green-900/25 dark:border-green-800/50':
              toast.type === 'success',
            'bg-yellow-50/95 border-yellow-200 dark:bg-yellow-900/25 dark:border-yellow-800/50':
              toast.type === 'warning',
            'bg-red-50/95 border-red-200 dark:bg-red-900/25 dark:border-red-800/50':
              toast.type === 'error',
          },
        ]"
      >
        <div class="flex-shrink-0 mt-0.5">
          <Info
            v-if="toast.type === 'info'"
            :class="[
              'h-5 w-5',
              {
                'text-zinc-500 dark:text-zinc-400': toast.type === 'info',
              },
            ]"
          />
          <CheckCircle
            v-if="toast.type === 'success'"
            :class="[
              'h-5 w-5',
              {
                'text-green-500 dark:text-green-400': toast.type === 'success',
              },
            ]"
          />
          <AlertTriangle
            v-if="toast.type === 'warning'"
            :class="[
              'h-5 w-5',
              {
                'text-yellow-500 dark:text-yellow-400': toast.type === 'warning',
              },
            ]"
          />
          <XCircle
            v-if="toast.type === 'error'"
            :class="[
              'h-5 w-5',
              {
                'text-red-500 dark:text-red-400': toast.type === 'error',
              },
            ]"
          />
        </div>
        <div class="ml-3 flex-1">
          <p
            :class="[
              'text-sm font-medium',
              {
                'text-zinc-800 dark:text-zinc-200': toast.type === 'info',
                'text-green-800 dark:text-green-200': toast.type === 'success',
                'text-yellow-800 dark:text-yellow-200': toast.type === 'warning',
                'text-red-800 dark:text-red-200': toast.type === 'error',
              },
            ]"
          >
            {{ toast.message }}
          </p>
        </div>
        <div class="ml-4 flex-shrink-0 flex">
          <button
            @click="toastStore.removeToast(toast.id)"
            :class="[
              'rounded-md inline-flex focus:outline-none transition-colors duration-200',
              {
                'text-zinc-400 hover:text-zinc-500 dark:text-zinc-400 dark:hover:text-zinc-300': true,
              },
            ]"
          >
            <X class="h-5 w-5" />
          </button>
        </div>
      </div>
    </TransitionGroup>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useToastStore } from '@/stores/toast'
import { Info, CheckCircle, AlertTriangle, XCircle, X } from 'lucide-vue-next'

const toastStore = useToastStore()
const MAX_VISIBLE_TOASTS = 5

// Show only the most recent toasts up to the maximum
const visibleToasts = computed(() => {
  return toastStore.toasts.slice(-MAX_VISIBLE_TOASTS).reverse()
})
</script>

<style scoped>
.toast-enter-active,
.toast-leave-active {
  transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

.toast-enter-from {
  opacity: 0;
  transform: translateX(100%) scale(0.95);
}

.toast-leave-to {
  opacity: 0;
  transform: translateX(100%) scale(0.95);
}
</style>
