<template>
  <div v-if="loadingStore.isLoadingAny()" class="fixed inset-0 z-[9999] flex items-center justify-center bg-black/75 backdrop-blur-sm">
    <div class="flex flex-col items-center">
      <Loader2 class="h-12 w-12 animate-spin text-white" />
      <p class="mt-4 text-white">Carregando...</p>
    </div>
  </div>
</template>

<script setup>
import { useLoadingStore } from '@/stores/loading'
import { Loader2 } from 'lucide-vue-next'

const loadingStore = useLoadingStore()
</script>
