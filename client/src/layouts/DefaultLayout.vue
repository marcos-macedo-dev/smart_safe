<template>
  <div class="flex h-screen overflow-hidden bg-zinc-50 dark:bg-zinc-950 relative">
    <!-- Sidebar -->
    <Sidebar />

    <!-- Manual Button -->
    <button
      @click="showManual = true"
      class="fixed right-0 top-1/2 -translate-y-1/2 z-40 bg-indigo-600 hover:bg-indigo-700 text-white px-2 py-4 rounded-l-lg shadow-lg transition-all duration-300 ease-in-out flex items-center gap-2 hover:shadow-xl hover:translate-x-1 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-zinc-900"
      aria-label="Abrir manual do usuário"
    >
      <span
        class="writing-mode-vertical text-sm font-semibold tracking-wide flex items-center gap-1"
      >
        <span class="rotate-180">Manual</span>
        <Info class="w-4 h-4 -rotate-90" />
      </span>
    </button>

    <!-- Main Content -->
    <div class="flex-1 flex flex-col overflow-hidden">
      <!-- Header -->
      <Header />

      <!-- Page Content -->
      <main class="flex-1 overflow-auto bg-zinc-50 dark:bg-zinc-950 transition-colors duration-300">
        <div class="p-4 md:p-6">
          <!-- Aqui vai o conteúdo das views filhas -->
          <router-view />
        </div>
      </main>
    </div>

    <!-- Manual Modal -->
    <ManualModal :show="showManual" @close="showManual = false" />
  </div>
</template>

<script setup>
import { ref } from 'vue'
import Header from '@/components/HeaderComp.vue'
import Sidebar from '@/components/SidebarComp.vue'
import ManualModal from '@/components/ManualModal.vue'
import { Info } from 'lucide-vue-next'

const showManual = ref(false)
</script>

<style scoped>
.writing-mode-vertical {
  writing-mode: vertical-lr;
  text-orientation: mixed;
}

/* Smooth transitions for dark mode */
.dark\:bg-zinc-950,
.bg-zinc-50 {
  transition: background-color 0.3s ease;
}
</style>
