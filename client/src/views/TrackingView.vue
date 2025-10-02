<template>
  <div class="container mx-auto py-5">
    <div class="flex justify-between items-center mb-6">
      <button
        @click="goBack"
        class="inline-flex items-center px-3 py-1.5 border border-zinc-300 dark:border-zinc-600 text-sm font-medium rounded-md text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-600 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-zinc-500 transition-colors"
      >
        <ArrowLeft class="w-4 h-4 mr-1" />
        Voltar
      </button>

      <h1 class="text-xl font-bold text-zinc-900 dark:text-white">
        Rastreamento de Apuros #{{ sosId }}
      </h1>

      <button
        @click="loadTrackingData"
        :disabled="loading"
        class="inline-flex items-center px-3 py-1.5 border border-zinc-300 dark:border-zinc-600 text-sm font-medium rounded-md text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-600 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-zinc-500 transition-colors disabled:opacity-50"
      >
        <RefreshCw class="w-4 h-4 mr-1" :class="{ 'animate-spin': loading }" />
        Atualizar
      </button>
    </div>

    <!-- Mapa e histórico -->
    <div v-if="loading" class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-6">
      <p class="text-zinc-500 dark:text-zinc-400 text-center">
        Carregando dados de rastreamento...
      </p>
    </div>

    <div v-else-if="error" class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-6">
      <p class="text-red-500 dark:text-red-400 text-center">{{ error }}</p>
    </div>

    <div v-else class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Mapa -->
      <div class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4">
        <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-3">
          Mapa de Rastreamento
        </h2>
        <div
          id="trackingMap"
          class="w-full h-96 rounded-md"
          style="min-height: 384px; position: relative"
        ></div>
      </div>

      <!-- Histórico de pontos -->
      <div class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4">
        <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-3">
          Histórico de Pontos
        </h2>
        <div
          v-if="trackingPoints.length === 0"
          class="text-zinc-500 dark:text-zinc-400 text-center py-8"
        >
          Nenhum ponto de rastreamento registrado
        </div>
        <div v-else class="space-y-3 max-h-96 overflow-y-auto">
          <div
            v-for="(point, index) in trackingPoints"
            :key="point.id"
            class="flex items-start p-3 border border-zinc-200 dark:border-zinc-700 rounded-md"
          >
            <div
              class="flex-shrink-0 w-8 h-8 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center"
            >
              <span class="text-xs font-medium text-blue-800 dark:text-blue-300">{{
                trackingPoints.length - index
              }}</span>
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-zinc-900 dark:text-white">
                Ponto #{{ trackingPoints.length - index }}
              </p>
              <p class="text-xs text-zinc-500 dark:text-zinc-400">
                {{ formatDate(point.registrado_em) }}
              </p>
              <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-1">
                Coordenadas: {{ point.latitude }}, {{ point.longitude }}
              </p>
              <div v-if="point.precisao || point.nivel_bateria" class="flex gap-2 mt-1">
                <span
                  v-if="point.precisao"
                  class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-zinc-100 dark:bg-zinc-700 text-zinc-800 dark:text-zinc-300"
                >
                  Precisão: {{ point.precisao }}m
                </span>
                <span
                  v-if="point.nivel_bateria"
                  class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-zinc-100 dark:bg-zinc-700 text-zinc-800 dark:text-zinc-300"
                >
                  Bateria: {{ point.nivel_bateria }}%
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ArrowLeft, RefreshCw } from 'lucide-vue-next'
import { getTrackingBySosId } from '@/services/http'
import { useToastStore } from '@/stores/toast'
import socket from '@/services/socket'

// Router
const route = useRoute()
const router = useRouter()

// Stores
const toast = useToastStore()

// Estado
const sosId = ref(route.params.sosId)
const trackingPoints = ref([])
const loading = ref(false)
const error = ref(null)

// Mapa
let map = null
let markers = []

// Carregar dados de rastreamento
const loadTrackingData = async () => {
  try {
    loading.value = true
    error.value = null

    const response = await getTrackingBySosId(sosId.value)
    trackingPoints.value = response.data

    // Aguardar um pouco para garantir que o DOM foi atualizado
    await nextTick()

    // Inicializar o mapa após carregar os dados
    if (trackingPoints.value.length > 0) {
      // Aguardar um pouco mais para garantir que o elemento está disponível
      setTimeout(() => {
        initializeMap()
      }, 200)
    } else {
      console.log('Nenhum ponto de rastreamento encontrado')
    }
  } catch (err) {
    error.value = 'Erro ao carregar dados de rastreamento'
    toast.error('Erro ao carregar dados de rastreamento')
    console.error('Erro ao carregar rastreamento:', err)
  } finally {
    loading.value = false
  }
}

// Inicializar o mapa
const initializeMap = () => {
  // Verificar se há pontos de rastreamento
  if (!trackingPoints.value || trackingPoints.value.length === 0) {
    console.error('Nenhum ponto de rastreamento disponível para inicializar o mapa')
    return
  }

  // Usar nextTick para garantir que o DOM foi renderizado
  nextTick(() => {
    // Aguardar um pouco mais para garantir que o elemento está disponível
    setTimeout(() => {
      const mapElement = document.getElementById('trackingMap')
      if (!mapElement) {
        console.error('Elemento do mapa não encontrado após timeout')
        // Tentar novamente após um delay maior
        setTimeout(() => {
          const retryElement = document.getElementById('trackingMap')
          if (!retryElement) {
            console.error('Elemento do mapa ainda não encontrado após retry')
            return
          }
          initializeMapWithElement(retryElement)
        }, 500)
        return
      }
      initializeMapWithElement(mapElement)
    }, 100)
  })
}

// Função separada para inicializar o mapa com elemento garantido
const initializeMapWithElement = (mapElement) => {
  // Verificar se o elemento tem dimensões válidas
  if (mapElement.offsetWidth === 0 || mapElement.offsetHeight === 0) {
    console.warn('Elemento do mapa não tem dimensões válidas, aguardando...')
    setTimeout(() => initializeMapWithElement(mapElement), 200)
    return
  }

  // Importar Leaflet dinamicamente
  import('leaflet')
    .then((L) => {
      // Remover mapa existente se houver
      if (map) {
        try {
          map.remove()
        } catch (e) {
          console.warn('Erro ao remover mapa existente:', e)
        }
      }

      // Configurar ícone padrão
      const DefaultIcon = L.icon({
        iconUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-icon.png',
        shadowUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-shadow.png',
        iconAnchor: [12, 41],
        popupAnchor: [1, -34],
        shadowSize: [41, 41],
      })
      L.Marker.prototype.options.icon = DefaultIcon

      // Criar mapa
      const firstPoint = trackingPoints.value[0]
      const latlng = [parseFloat(firstPoint.latitude), parseFloat(firstPoint.longitude)]

      try {
        map = L.map('trackingMap', {
          // Configurações adicionais para melhor compatibilidade
          preferCanvas: false,
          zoomControl: true,
          attributionControl: true,
        }).setView(latlng, 15)
      } catch (e) {
        console.error('Erro ao criar o mapa:', e)
        return
      }

      // Adicionar camada de tiles
      try {
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '&copy; OpenStreetMap contributors',
          maxZoom: 19,
        }).addTo(map)
      } catch (e) {
        console.error('Erro ao adicionar camada de tiles:', e)
      }

      // Adicionar marcadores para cada ponto
      markers = []
      trackingPoints.value.forEach((point, index) => {
        const markerLatlng = [parseFloat(point.latitude), parseFloat(point.longitude)]
        let marker
        try {
          marker = L.marker(markerLatlng).addTo(map)
        } catch (e) {
          console.error('Erro ao adicionar marcador:', e)
          return
        }

        // Adicionar popup com informações
        const pointNumber = trackingPoints.value.length - index
        try {
          marker.bindPopup(`
          <div class="text-sm">
            <div class="font-semibold">Ponto #${pointNumber}</div>
            <div class="mt-1">${formatDate(point.registrado_em)}</div>
            <div class="mt-1">Coordenadas: ${point.latitude}, ${point.longitude}</div>
            ${point.precisao ? `<div class="mt-1">Precisão: ${point.precisao}m</div>` : ''}
            ${point.nivel_bateria ? `<div class="mt-1">Bateria: ${point.nivel_bateria}%</div>` : ''}
          </div>
        `)
        } catch (e) {
          console.error('Erro ao adicionar popup ao marcador:', e)
        }

        markers.push(marker)
      })

      // Ajustar o zoom para mostrar todos os marcadores
      if (markers.length > 1) {
        try {
          const group = new L.featureGroup(markers)
          map.fitBounds(group.getBounds().pad(0.1))
        } catch (e) {
          console.error('Erro ao ajustar o zoom do mapa:', e)
        }
      }

      console.log('Mapa inicializado com sucesso')
    })
    .catch((e) => {
      console.error('Erro ao importar Leaflet:', e)
    })
}

// Formatar data
const formatDate = (dateString) => {
  if (!dateString) return 'Não informado'

  const date = new Date(dateString)
  return date.toLocaleString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

// Voltar para a lista
const goBack = () => {
  router.push('/sos')
}

// Ciclo de vida
onMounted(() => {
  loadTrackingData()

  // Escutar eventos de novo ponto de rastreamento
  socket.on('rastreamento_update', (trackingPoint) => {
    if (trackingPoint.sos_id === sosId.value) {
      // Adicionar o novo ponto ao histórico
      trackingPoints.value.push(trackingPoint)

      // Atualizar o mapa com o novo ponto
      if (map) {
        import('leaflet')
          .then((L) => {
            const latlng = [trackingPoint.latitude, trackingPoint.longitude]
            let marker
            try {
              marker = L.marker(latlng).addTo(map)
            } catch (e) {
              console.error('Erro ao adicionar marcador para novo ponto:', e)
              return
            }

            // Adicionar popup com informações
            const pointNumber = trackingPoints.value.length
            try {
              marker.bindPopup(`
              <div class="text-sm">
                <div class="font-semibold">Ponto #${pointNumber}</div>
                <div class="mt-1">${formatDate(trackingPoint.registrado_em)}</div>
                <div class="mt-1">Coordenadas: ${trackingPoint.latitude}, ${trackingPoint.longitude}</div>
                ${trackingPoint.precisao ? `<div class="mt-1">Precisão: ${trackingPoint.precisao}m</div>` : ''}
                ${trackingPoint.nivel_bateria ? `<div class="mt-1">Bateria: ${trackingPoint.nivel_bateria}%</div>` : ''}
              </div>
            `)
            } catch (e) {
              console.error('Erro ao adicionar popup ao novo marcador:', e)
            }

            markers.push(marker)

            // Ajustar o zoom para mostrar todos os marcadores
            if (markers.length > 1) {
              try {
                const group = new L.featureGroup(markers)
                map.fitBounds(group.getBounds().pad(0.1))
              } catch (e) {
                console.error('Erro ao ajustar o zoom do mapa para novo ponto:', e)
              }
            } else {
              try {
                map.setView(latlng, 15)
              } catch (e) {
                console.error('Erro ao ajustar a visão do mapa para novo ponto:', e)
              }
            }
          })
          .catch((e) => {
            console.error('Erro ao importar Leaflet para novo ponto:', e)
          })
      }

      toast.info('Novo ponto de rastreamento adicionado')
    }
  })
})

onBeforeUnmount(() => {
  // Remover listeners do WebSocket
  socket.off('rastreamento_update')

  if (map) {
    try {
      map.remove()
    } catch (e) {
      console.warn('Erro ao remover o mapa:', e)
    }
  }
})
</script>

<style scoped>
@import 'leaflet/dist/leaflet.css';
</style>
