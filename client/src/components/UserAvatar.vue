<template>
  <div class="relative">
    <div
      v-if="initials"
      class="w-24 h-24 rounded-full flex items-center justify-center border-2 border-zinc-200 dark:border-zinc-600 text-xl font-semibold"
      :style="{ backgroundColor: backgroundColor, color: textColor }"
    >
      {{ initials }}
    </div>
    <div
      v-else
      class="w-24 h-24 rounded-full bg-zinc-200 dark:bg-zinc-700 border-2 border-zinc-200 dark:border-zinc-600 flex items-center justify-center"
    >
      <User class="w-10 h-10 text-zinc-400 dark:text-zinc-500" />
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { User } from 'lucide-vue-next'

const props = defineProps({
  user: {
    type: Object,
    default: () => ({}),
  },
  backgroundColor: {
    type: String,
    default: '#e5e7eb', // bg-zinc-200
  },
  textColor: {
    type: String,
    default: '#3f3f46', // text-zinc-700
  },
})

const initials = computed(() => {
  const name = props.user?.nome
  if (!name) return ''

  const names = name.trim().split(' ')
  if (names.length === 0) return ''

  if (names.length === 1) {
    return names[0].substring(0, 2).toUpperCase()
  }

  return (names[0][0] + names[names.length - 1][0]).toUpperCase()
})
</script>
