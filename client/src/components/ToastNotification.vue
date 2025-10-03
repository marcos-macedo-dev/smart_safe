<template>
  <div class="pointer-events-none fixed bottom-6 right-6 z-[1100] flex w-full max-w-xs flex-col gap-3 sm:max-w-sm">
    <TransitionGroup name="toast-modern" tag="div">
      <article
        v-for="toast in visibleToasts"
        :key="toast.id"
        class="pointer-events-auto group relative overflow-hidden rounded-3xl border border-white/10 bg-zinc-900/80 p-4 shadow-2xl backdrop-blur-xl ring-1 ring-white/15"
        role="status"
        :aria-live="toast.type === 'error' ? 'assertive' : 'polite'"
      >
        <span
          class="absolute inset-y-0 left-0 w-1 bg-gradient-to-b"
          :class="accentStyles[toast.type]?.bar ?? accentStyles.info.bar"
        ></span>

        <div class="flex items-start gap-3 pl-3">
          <div
            :class="[
              'flex h-10 w-10 items-center justify-center rounded-2xl bg-gradient-to-br text-white shadow-inner shadow-zinc-950/40 ring-1 ring-white/10',
              accentStyles[toast.type]?.icon ?? accentStyles.info.icon,
            ]"
          >
            <component :is="iconMap[toast.type] || iconMap.info" class="h-5 w-5" />
          </div>

          <div class="flex-1 pr-2">
            <p class="text-sm font-semibold text-white/95">
              {{ typeTitles[toast.type] || typeTitles.info }}
            </p>
            <p class="mt-1 text-sm leading-snug text-zinc-200/90">
              {{ toast.message }}
            </p>
          </div>

          <button
            type="button"
            class="rounded-full border border-transparent p-1 text-zinc-400 transition hover:border-white/10 hover:text-white/90 focus:outline-none focus-visible:ring-2 focus-visible:ring-white/40"
            @click="toastStore.removeToast(toast.id)"
          >
            <X class="h-4 w-4" />
          </button>
        </div>

        <span
          class="toast-progress"
          :class="accentStyles[toast.type]?.progress ?? accentStyles.info.progress"
          :style="{ '--toast-duration': `${toast.duration ?? 5000}ms` }"
        ></span>
      </article>
    </TransitionGroup>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useToastStore } from '@/stores/toast'
import { Info, CheckCircle2, AlertTriangle, XCircle, X } from 'lucide-vue-next'

const toastStore = useToastStore()
const MAX_VISIBLE_TOASTS = 5

const iconMap = {
  info: Info,
  success: CheckCircle2,
  warning: AlertTriangle,
  error: XCircle,
}

const typeTitles = {
  info: 'Informação',
  success: 'Tudo certo',
  warning: 'Atenção',
  error: 'Ops! Algo deu errado',
}

const accentStyles = {
  info: {
    icon: 'from-sky-500/80 via-sky-400/80 to-sky-500/80 text-sky-50',
    bar: 'from-sky-400/90 via-sky-500/90 to-sky-600/80',
    progress: 'from-sky-400 to-sky-500',
  },
  success: {
    icon: 'from-emerald-500/85 via-emerald-400/80 to-emerald-500/80 text-emerald-50',
    bar: 'from-emerald-500/90 via-emerald-400/90 to-emerald-600/80',
    progress: 'from-emerald-400 to-emerald-500',
  },
  warning: {
    icon: 'from-amber-500/85 via-amber-400/80 to-amber-500/80 text-amber-50',
    bar: 'from-amber-500/90 via-amber-400/90 to-amber-600/80',
    progress: 'from-amber-400 to-amber-500',
  },
  error: {
    icon: 'from-rose-500/85 via-rose-400/80 to-rose-500/80 text-rose-50',
    bar: 'from-rose-500/90 via-rose-400/90 to-rose-600/80',
    progress: 'from-rose-400 to-rose-500',
  },
}

const visibleToasts = computed(() => toastStore.toasts.slice(-MAX_VISIBLE_TOASTS).reverse())
</script>

<style scoped>
.toast-modern-enter-active,
.toast-modern-leave-active {
  transition: all 0.38s cubic-bezier(0.22, 1, 0.36, 1);
}

.toast-modern-enter-from {
  opacity: 0;
  transform: translateY(16px) scale(0.95);
}

.toast-modern-leave-to {
  opacity: 0;
  transform: translateY(16px) scale(0.95);
}

.toast-progress {
  position: absolute;
  inset-inline: 0;
  bottom: 0;
  height: 2px;
  background-image: linear-gradient(90deg, var(--tw-gradient-stops));
  transform-origin: left;
  animation: toast-progress-bar var(--toast-duration, 5000ms) linear forwards;
}

@keyframes toast-progress-bar {
  from {
    transform: scaleX(1);
    opacity: 0.9;
  }

  to {
    transform: scaleX(0);
    opacity: 0.1;
  }
}
</style>
