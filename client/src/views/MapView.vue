<template>
  <div class="relative h-full w-full">
    <!-- Botão para centralizar no Brasil -->
    <button
      @click="centerOnBrazil"
      class="absolute top-4 right-4 z-[1001] bg-white dark:bg-zinc-800 hover:bg-zinc-100 dark:hover:bg-zinc-700 text-zinc-800 dark:text-white px-3 py-2 rounded-md shadow-md border border-zinc-200 dark:border-zinc-700 transition-colors"
      title="Centralizar no Brasil"
    >
      <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd" />
      </svg>
    </button>

    <!-- Overlay de carregamento/erro -->
    <div
      v-if="loading || error"
      class="absolute inset-0 z-[1000] flex items-center justify-center bg-white bg-opacity-80 dark:bg-zinc-900 dark:bg-opacity-80"
    >
      <div
        class="text-center rounded-lg bg-white dark:bg-zinc-800 p-6 shadow-lg border border-zinc-200 dark:border-zinc-700"
      >
        <p class="text-lg font-semibold text-zinc-700 dark:text-zinc-200">
          {{ loading ? 'Carregando mapa...' : error }}
        </p>
        <button
          v-if="error"
          @click="retryLoadMap"
          class="mt-4 px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 transition-colors"
        >
          Tentar novamente
        </button>
      </div>
    </div>

    <!-- Container do mapa -->
    <div id="mapContainer" class="h-full w-full rounded-lg overflow-hidden relative"></div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import 'leaflet/dist/leaflet.css'
import * as L from 'leaflet'
import 'leaflet.markercluster/dist/leaflet.markercluster.js'
import 'leaflet.markercluster/dist/MarkerCluster.css'
import 'leaflet.markercluster/dist/MarkerCluster.Default.css'
import { listDelegacias } from '@/services/http'
import { useToastStore } from '@/stores/toast'

// --- Correção para os ícones do Leaflet ---
import markerIcon from 'leaflet/dist/images/marker-icon.png'
import markerShadow from 'leaflet/dist/images/marker-shadow.png'
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png'

// Corrigir problema com os ícones do Leaflet
delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: markerIcon2x,
  iconUrl: markerIcon,
  shadowUrl: markerShadow,
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
})

// --- Estado da Aplicação ---
const map = ref(null)
const loading = ref(true)
const error = ref(null)
const toast = useToastStore()

// Centro e zoom padrão (Brasil)
const DEFAULT_CENTER = [-14.235004, -51.92528]
const DEFAULT_ZOOM = 4

const centerOnBrazil = () => {
  if (map.value) {
    map.value.setView(DEFAULT_CENTER, DEFAULT_ZOOM)
  }
}

const ensureMapInitialized = (center = DEFAULT_CENTER, zoom = DEFAULT_ZOOM) => {
  if (map.value) return

  const mapContainer = document.getElementById('mapContainer')
  if (!mapContainer) {
    throw new Error('Container do mapa não encontrado')
  }

  // Garantir tamanho do container (fallback)
  mapContainer.style.height = mapContainer.style.height || '100vh'
  mapContainer.style.width = mapContainer.style.width || '100%'

  map.value = L.map('mapContainer', {
    center,
    zoom,
    zoomControl: true,
  })

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap contributors',
    maxZoom: 19,
  }).addTo(map.value)
}

// --- Função para carregar o mapa ---
const loadMap = async () => {
  loading.value = true
  error.value = null

  try {
    // Pequeno atraso para garantir que o DOM está pronto
    await new Promise((resolve) => setTimeout(resolve, 100))

    // Inicializa o mapa com fallback padrão
    ensureMapInitialized()

    // Buscar delegacias e adicionar marcadores
    console.log('Carregando delegacias...')
    const response = await listDelegacias({ ativa: true })
    const delegacias = Array.isArray(response?.data?.delegacias) ? response.data.delegacias : (Array.isArray(response?.data) ? response.data : [])
    console.log('Delegacias carregadas:', delegacias)

    // Criar grupo de marcadores com cluster
    const markers = L.markerClusterGroup({
      chunkedLoading: true,
      maxClusterRadius: 80,
      spiderfyOnMaxZoom: true,
      showCoverageOnHover: false,
      zoomToBoundsOnClick: true
    })

    delegacias.forEach((delegacia) => {
      const hasCoords =
        delegacia &&
        delegacia.latitude != null &&
        delegacia.longitude != null &&
        !Number.isNaN(parseFloat(delegacia.latitude)) &&
        !Number.isNaN(parseFloat(delegacia.longitude))

      if (hasCoords) {
        const marker = L.marker([
          parseFloat(delegacia.latitude),
          parseFloat(delegacia.longitude),
        ])

        marker.bindPopup(`
          <div class="p-2">
            <h3 class="font-bold text-lg mb-1">${delegacia.nome ?? 'Delegacia'}</h3>
            <p class="mb-1">${delegacia.endereco || 'Endereço não informado'}</p>
            ${delegacia.telefone ? `<p class="mb-1">Telefone: ${delegacia.telefone}</p>` : ''}
            ${delegacia.ativa !== undefined ? `<p class="mb-1">Status: ${delegacia.ativa ? 'Ativa' : 'Inativa'}</p>` : ''}
          </div>
        `)

        markers.addLayer(marker)
      }
    })

    map.value.addLayer(markers)

    if (markers.getLayers().length > 0) {
      map.value.fitBounds(markers.getBounds())
    }
  } catch (err) {
    console.error('Erro ao carregar delegacias:', err)
    toast.error('Erro ao carregar delegacias: ' + (err?.message || 'Falha desconhecida'))
  } finally {
    // Garantir atualização do tamanho do mapa
    setTimeout(() => {
      if (map.value) {
        map.value.invalidateSize()
      }
    }, 300)

    loading.value = false
  }
}

// --- Função para tentar novamente ---
const retryLoadMap = () => {
  loadMap()
}

// --- Ciclo de Vida do Componente ---
onMounted(() => {
  // Pequeno atraso para garantir que o DOM está pronto
  setTimeout(() => {
    loadMap()
  }, 200)
})

onBeforeUnmount(() => {
  if (map.value) {
    map.value.remove()
    map.value = null
  }
})
</script>

<style scoped>
#mapContainer {
  height: 100%;
  width: 100%;
  z-index: 1;
}
</style>
