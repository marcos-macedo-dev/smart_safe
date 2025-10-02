import { ref } from 'vue'
import { defineStore } from 'pinia'

export const useLoadingStore = defineStore('loading', () => {
  const loadingStates = ref({})

  function start(key) {
    loadingStates.value[key] = true
  }

  function stop(key) {
    loadingStates.value[key] = false
  }

  function isLoading(key) {
    return loadingStates.value[key] || false
  }

  function isLoadingAny() {
    return Object.values(loadingStates.value).some(state => state)
  }

  return { loadingStates, start, stop, isLoading, isLoadingAny }
})