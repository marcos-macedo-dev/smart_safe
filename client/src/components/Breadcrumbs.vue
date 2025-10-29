<template>
  <nav aria-label="Breadcrumb" class="flex mb-4">
    <ol class="inline-flex items-center space-x-1 md:space-x-3">
      <li class="inline-flex items-center">
        <router-link
          to="/"
          class="inline-flex items-center text-sm font-medium text-zinc-700 hover:text-indigo-600 dark:text-zinc-400 dark:hover:text-white"
        >
          <Home class="w-4 h-4 mr-2" />
          Dashboard
        </router-link>
      </li>
      <li v-for="(crumb, index) in breadcrumbs" :key="index">
        <div class="flex items-center">
          <ChevronRight class="w-4 h-4 text-zinc-400 mx-1" />
          <span
            v-if="index === breadcrumbs.length - 1"
            class="text-sm font-medium text-zinc-500 dark:text-zinc-400 cursor-default"
          >
            {{ crumb.label }}
          </span>
          <router-link
            v-else
            :to="crumb.path"
            class="text-sm font-medium text-zinc-700 hover:text-indigo-600 dark:text-zinc-400 dark:hover:text-white"
          >
            {{ crumb.label }}
          </router-link>
        </div>
      </li>
    </ol>
  </nav>
</template>

<script setup>
import { Home, ChevronRight } from 'lucide-vue-next'

defineProps({
  breadcrumbs: {
    type: Array,
    default: () => []
  }
})
</script>