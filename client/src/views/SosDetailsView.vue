<template>
  <div class="container mx-auto py-5">
    <div class="flex justify-between items-center mb-6">
      <div class="flex gap-2">
        <button
          @click="goBack"
          class="inline-flex items-center px-3 py-1.5 border border-zinc-300 dark:border-zinc-600 text-sm font-medium rounded-md text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-600 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-zinc-500 transition-colors"
        >
          <ArrowLeft class="w-4 h-4 mr-1" />
          Voltar
        </button>

        <button
          @click="goToTracking"
          class="inline-flex items-center px-3 py-1.5 border border-zinc-300 dark:border-zinc-600 text-sm font-medium rounded-md text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-600 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-zinc-500 transition-colors"
        >
          <MapPin class="w-4 h-4 mr-1" />
          Rastreamento
        </button>
      </div>

      <h1 class="text-xl font-bold text-zinc-900 dark:text-white">
        Detalhes do Chamado #{{ sos?.id }}
      </h1>

      <div v-if="sos" class="flex gap-2">
        <select
          v-model="sos.status"
          @change="updateStatus"
          class="px-3 py-1.5 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
        >
          <option value="pendente">Pendente</option>
          <option value="ativo">Ativo</option>
          <option value="aguardando_autoridade">Aguardando Autoridade</option>
          <option value="fechado">Fechado</option>
          <option value="cancelado">Cancelado</option>
        </select>
      </div>
    </div>

    <!-- Detalhes do SOS -->
    <div v-if="sos" class="space-y-6">
      <!-- Informações do Usuário -->
      <div class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4">
        <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-3">
          Informações do Solicitante
        </h2>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label
              class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
              >Nome</label
            >
            <p class="text-sm text-zinc-900 dark:text-white">
              {{ sos.usuario?.nome_completo || 'Não informado' }}
            </p>
          </div>
          <div>
            <label
              class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
              >Telefone</label
            >
            <p class="text-sm text-zinc-900 dark:text-white">
              {{ sos.usuario?.telefone || 'Não informado' }}
            </p>
          </div>
          <div>
            <label
              class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
              >Email</label
            >
            <p class="text-sm text-zinc-900 dark:text-white">
              {{ sos.usuario?.email || 'Não informado' }}
            </p>
          </div>
          <div>
            <label
              class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
              >Cidade</label
            >
            <p class="text-sm text-zinc-900 dark:text-white">
              {{ sos.usuario?.cidade || 'Não informado' }}
            </p>
          </div>
          <div>
            <label
              class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
              >Estado</label
            >
            <p class="text-sm text-zinc-900 dark:text-white">
              {{ sos.usuario?.estado || 'Não informado' }}
            </p>
          </div>
          <div>
            <label
              class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
              >Endereço</label
            >
            <p class="text-sm text-zinc-900 dark:text-white">
              {{ sos.usuario?.endereco || 'Não informado' }}
            </p>
          </div>
          <div>
            <label
              class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
              >Gênero</label
            >
            <p class="text-sm text-zinc-900 dark:text-white">
              {{ sos.usuario?.genero || 'Não informado' }}
            </p>
          </div>
          <div>
            <label
              class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
              >Cor</label
            >
            <p class="text-sm text-zinc-900 dark:text-white">
              {{ sos.usuario?.cor || 'Não informado' }}
            </p>
          </div>
          <div>
            <label
              class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
              >Documento de Identificação</label
            >
            <p class="text-sm text-zinc-900 dark:text-white">
              {{ sos.usuario?.documento_identificacao || 'Não informado' }}
            </p>
          </div>
        </div>
      </div>

      <!-- Status e Localização -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Status -->
        <div class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4">
          <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-3">
            Status do Chamado
          </h2>
          <div class="flex items-center gap-3">
            <span class="px-3 py-1 text-sm rounded-full" :class="getStatusClass(sos.status)">
              {{ formatStatus(sos.status) }}
            </span>
            <div>
              <p class="text-sm text-zinc-500 dark:text-zinc-400">Criado em</p>
              <p class="text-sm text-zinc-900 dark:text-white">{{ formatDate(sos.createdAt) }}</p>
            </div>
            <div v-if="sos.encerrado_em">
              <p class="text-sm text-zinc-500 dark:text-zinc-400">Encerrado em</p>
              <p class="text-sm text-zinc-900 dark:text-white">
                {{ formatDate(sos.encerrado_em) }}
              </p>
            </div>
          </div>
        </div>

        <!-- Localização -->
        <div class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4">
          <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-3">Localização</h2>
          <div class="flex flex-col gap-3">
            <div>
              <p class="text-sm text-zinc-500 dark:text-zinc-400">Delegacia</p>
              <p class="text-sm text-zinc-900 dark:text-white">
                {{ sos.delegacia?.nome || 'Não roteado' }}
              </p>
              <p class="text-xs text-zinc-500 dark:text-zinc-400">
                {{ sos.delegacia?.endereco || '' }}
              </p>
            </div>
            <div>
              <p class="text-sm text-zinc-500 dark:text-zinc-400">Coordenadas</p>
              <p class="text-sm text-zinc-900 dark:text-white" v-if="sos.latitude && sos.longitude">
                {{ sos.latitude }}, {{ sos.longitude }}
              </p>
              <p class="text-sm text-zinc-500 dark:text-zinc-400" v-else>Não disponível</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Mídia -->
      <div class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4">
        <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-3">Mídia</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label
              class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
              >Áudio</label
            >
            <div v-if="sos.caminho_audio" class="mt-1">
              <audio controls class="w-full">
                <source :src="sos.caminho_audio" type="audio/mpeg" />
                Seu navegador não suporta o elemento de áudio.
              </audio>
            </div>
            <p v-else class="text-sm text-zinc-500 dark:text-zinc-400">Nenhum áudio disponível</p>
          </div>
          <div>
            <label
              class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
              >Vídeo</label
            >
            <div v-if="sos.caminho_video" class="mt-1">
              <video controls class="w-full h-48 bg-black rounded">
                <source :src="sos.caminho_video" type="video/mp4" />
                Seu navegador não suporta o elemento de vídeo.
              </video>
            </div>
            <p v-else class="text-sm text-zinc-500 dark:text-zinc-400">Nenhum vídeo disponível</p>
          </div>
        </div>
      </div>

      <!-- Informações Adicionais -->
      <div class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4">
        <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-3">
          Informações Adicionais
        </h2>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label
              class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
              >ID do Usuário</label
            >
            <p class="text-sm text-zinc-900 dark:text-white">
              {{ sos.usuario_id || 'Não informado' }}
            </p>
          </div>
          <div>
            <label
              class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
              >ID da Delegacia</label
            >
            <p class="text-sm text-zinc-900 dark:text-white">
              {{ sos.delegacia_id || 'Não atribuído' }}
            </p>
          </div>
          <div>
            <label
              class="block text-xs font-medium text-zinc-700 dark:text-zinc-300 mb-1 uppercase tracking-wide"
              >Última Atualização</label
            >
            <p class="text-sm text-zinc-900 dark:text-white">{{ formatDate(sos.updatedAt) }}</p>
          </div>
        </div>
      </div>

      <!-- Mapa -->
      <div
        v-if="sos.latitude && sos.longitude"
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4"
      >
        <div class="flex justify-between items-center mb-3 flex-wrap">
          <h2 class="text-base font-semibold text-zinc-800 dark:text-white">Localização e Rota</h2>
          <div class="flex gap-2 flex-wrap">
            <button
              @click="copyCoordinates"
              class="inline-flex items-center px-2 py-1 text-xs font-medium rounded-md text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 border border-zinc-300 dark:border-zinc-600 hover:bg-zinc-50 dark:hover:bg-zinc-600 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-zinc-500 transition-colors"
            >
              <Copy class="w-3 h-3 mr-1" />
              Copiar Coordenadas
            </button>
            <button
              @click="openInGoogleMaps"
              class="inline-flex items-center px-2 py-1 text-xs font-medium rounded-md text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 border border-zinc-300 dark:border-zinc-600 hover:bg-zinc-50 dark:hover:bg-zinc-600 focus:outline-none focus:ring-1 focus:ring-offset-1 focus:ring-zinc-500 transition-colors"
            >
              <Map class="w-3 h-3 mr-1" />
              Abrir no Google Maps
            </button>
          </div>
        </div>
        <p class="text-sm text-zinc-600 dark:text-zinc-400 mb-3">
          O mapa abaixo mostra a rota otimizada (via OpenStreetMap) da delegacia até a localização
          do chamado, calculada automaticamente para auxiliar a equipe de atendimento.
        </p>
        <div
          id="sosMap"
          class="h-[600px] w-full rounded-md border dark:border-zinc-700 bg-gray-100 dark:bg-zinc-900"
        ></div>

        <div
          v-if="routeInfo"
          class="mt-3 p-3 bg-blue-50 dark:bg-zinc-700/50 rounded-lg text-sm border border-blue-200 dark:border-zinc-600"
        >
          <h3 class="font-semibold text-blue-800 dark:text-blue-300 mb-1">
            Detalhes da Rota Otimizada
          </h3>
          <div class="grid grid-cols-2 gap-2">
            <p class="text-zinc-700 dark:text-zinc-300">
              <strong class="font-medium">Distância:</strong> {{ routeInfo.distance }}
            </p>
            <p class="text-zinc-700 dark:text-zinc-300">
              <strong class="font-medium">Duração:</strong> {{ routeInfo.duration }}
            </p>
          </div>
          <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-2">
            A rota é uma estimativa e pode variar com as condições de trânsito.
          </p>
        </div>

        <div class="mt-2 text-xs text-zinc-500 dark:text-zinc-400">
          <strong>Coordenadas do Chamado:</strong> {{ sos.latitude || 'Não disponível' }},
          {{ sos.longitude || 'Não disponível' }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ArrowLeft, MapPin, Copy, Map } from 'lucide-vue-next'
import 'leaflet/dist/leaflet.css'
import * as L from 'leaflet'
import { getSosById, updateSos } from '@/services/http'
import socket from '@/services/socket'
import notificationService from '@/services/notification'
import { useToastStore } from '@/stores/toast'

const route = useRoute()
const router = useRouter()
const toast = useToastStore()

// State
const sos = ref(null)
const map = ref(null)
const marker = ref(null)
const routeLayer = ref(null)
const routeInfo = ref(null)
const delegaciaMarker = ref(null)

// --- Lógica de Ícone ---
import markerIconUrl from 'leaflet/dist/images/marker-icon.png'
import markerShadowUrl from 'leaflet/dist/images/marker-shadow.png'
const DefaultIcon = L.icon({
  iconUrl: markerIconUrl,
  shadowUrl: markerShadowUrl,
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
})
L.Marker.prototype.options.icon = DefaultIcon

// Carregar detalhes do SOS
const loadSosDetails = async () => {
  try {
    if (!route.params.id) throw new Error('ID do chamado não fornecido')
    const response = await getSosById(route.params.id)
    sos.value = response.data
    if (!sos.value) throw new Error('Dados do chamado não encontrados')
    if (sos.value.id) socket.joinSosRoom(sos.value.id)
    if (sos.value.latitude && sos.value.longitude) {
      const lat = parseFloat(sos.value.latitude)
      const lng = parseFloat(sos.value.longitude)
      if (!isNaN(lat) && !isNaN(lng)) {
        setTimeout(() => initializeMap(), 50)
      } else {
        toast.error('Coordenadas inválidas no chamado')
      }
    }
  } catch (err) {
    toast.error('Erro ao carregar detalhes do chamado')
    console.error('Erro ao carregar SOS:', err)
  }
}

// Inicializar o mapa
const initializeMap = () => {
  // Verificar se os dados do SOS estão disponíveis
  if (!sos.value) {
    toast.error('Dados do chamado não disponíveis para exibir o mapa.')
    return
  }

  // Verificar se as coordenadas estão disponíveis
  if (!sos.value.latitude || !sos.value.longitude) {
    toast.error('Coordenadas do chamado não disponíveis para exibir o mapa.')
    return
  }

  // Usar nextTick para garantir que o DOM foi renderizado
  nextTick(() => {
    // Verificar se o elemento do mapa existe no DOM
    const mapElement = document.getElementById('sosMap')
    if (!mapElement) {
      console.error('Elemento do mapa não encontrado')
      toast.error('Não foi possível inicializar o mapa. Elemento não encontrado.')
      return
    }

    // Verificar se o elemento tem dimensões válidas
    if (mapElement.offsetWidth === 0 || mapElement.offsetHeight === 0) {
      console.warn('Elemento do mapa tem dimensões inválidas')
      toast.warn('O mapa pode não ser exibido corretamente devido a dimensões inválidas.')
    }

    // Remover mapa existente se houver
    if (map.value) {
      try {
        map.value.remove()
      } catch (e) {
        console.warn('Erro ao remover mapa existente:', e)
      }
    }

    const lat = parseFloat(sos.value.latitude)
    const lng = parseFloat(sos.value.longitude)
    const latlng = [lat, lng]

    // Verificar se as coordenadas são válidas
    if (isNaN(lat) || isNaN(lng)) {
      toast.error('Coordenadas inválidas para exibir o mapa.')
      return
    }

    // Verificar se as coordenadas estão dentro dos limites válidos
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      toast.error('Coordenadas fora dos limites válidos para exibir o mapa.')
      return
    }

    try {
      map.value = L.map('sosMap').setView(latlng, 15)

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors',
        maxZoom: 19,
      }).addTo(map.value)

      marker.value = L.marker(latlng).addTo(map.value)

      // Invalidar o tamanho do mapa para garantir que ele seja renderizado corretamente
      setTimeout(() => {
        if (map.value) {
          map.value.invalidateSize()
        }
      }, 100)
    } catch (e) {
      console.error('Erro ao inicializar o mapa:', e)
      toast.error('Erro ao inicializar o mapa. Verifique o console para mais detalhes.')
      return
    }

    // Criar conteúdo do popup com mais informações
    const popupContent = `
      <div class="text-sm">
        <div class="font-semibold text-blue-600 dark:text-blue-400">Localização do Chamado</div>
        <div class="mt-1"><strong>ID:</strong> #${sos.value.id || 'Desconhecido'}</div>
        <div class="mt-1"><strong>Coordenadas:</strong> ${sos.value.latitude || 'Não disponível'}, ${sos.value.longitude || 'Não disponível'}</div>
        <div class="mt-1"><strong>Data:</strong> ${formatDate(sos.value.createdAt)}</div>
        ${sos.value.usuario?.nome_completo ? `<div class="mt-1"><strong>Solicitante:</strong> ${sos.value.usuario.nome_completo}</div>` : ''}
        ${sos.value.delegacia?.nome ? `<div class="mt-1"><strong>Delegacia:</strong> ${sos.value.delegacia.nome}</div>` : ''}
        <div class="mt-2 flex gap-2">
          <button onclick="copyCoordinatesFromPopup('${sos.value.latitude || 0}, ${sos.value.longitude || 0}')" class="px-2 py-1 text-xs bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200 rounded">
            Copiar Coordenadas
          </button>
          <button onclick="openInGoogleMapsFromPopup(${sos.value.latitude || 0}, ${sos.value.longitude || 0})" class="px-2 py-1 text-xs bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200 rounded">
            Google Maps
          </button>
        </div>
      </div>
    `

    marker.value.bindPopup(popupContent).openPopup()

    // Adicionar funções globais para os botões do popup
    window.copyCoordinatesFromPopup = (coordinates) => {
      // Verificar se as coordenadas são válidas
      if (coordinates && coordinates !== '0, 0') {
        navigator.clipboard
          .writeText(coordinates)
          .then(() => {
            toast.success('Coordenadas copiadas para a área de transferência')
          })
          .catch((err) => {
            toast.error('Erro ao copiar coordenadas')
            console.error('Erro ao copiar coordenadas:', err)
          })
      } else {
        toast.error('Coordenadas inválidas para copiar')
      }
    }

    window.openInGoogleMapsFromPopup = (lat, lng) => {
      // Verificar se as coordenadas são válidas
      if (!isNaN(parseFloat(lat)) && !isNaN(parseFloat(lng))) {
        const url = `https://www.google.com/maps?q=${lat},${lng}`
        window.open(url, '_blank')
      } else {
        toast.error('Coordenadas inválidas para abrir no Google Maps')
      }
    }

    // Calcular e desenhar a rota automaticamente após um pequeno atraso
    // para garantir que o mapa esteja completamente inicializado
    setTimeout(() => {
      if (map.value) {
        // Verificar se o mapa foi inicializado com sucesso
        calculateRoute()
      } else {
        console.error('Mapa não foi inicializado corretamente')
        toast.error('Erro ao calcular a rota: mapa não inicializado.')
      }
    }, 200) // Aumentar o tempo de espera para garantir que o mapa esteja completamente inicializado
  })
}

// Atualizar status do SOS
const updateStatus = async () => {
  if (!sos.value || !sos.value.id) {
    toast.error('Dados do chamado não disponíveis para atualizar o status.')
    return
  }
  try {
    await updateSos(sos.value.id, { status: sos.value.status })
    toast.success('Status atualizado com sucesso')
  } catch (err) {
    toast.error('Erro ao atualizar status')
    console.error('Erro ao atualizar status:', err)
  }
}

// Formatar status para exibição
const formatStatus = (status) => {
  // Verificar se o status está disponível
  if (!status) {
    return 'Não informado'
  }

  const statusMap = {
    pendente: 'Pendente',
    ativo: 'Ativo',
    aguardando_autoridade: 'Aguardando Autoridade',
    fechado: 'Fechado',
    cancelado: 'Cancelado',
  }

  return statusMap[status] || status
}

// Obter classe CSS para status
const getStatusClass = (status) => {
  // Verificar se o status está disponível
  if (!status) {
    return 'bg-zinc-100 text-zinc-800 dark:bg-zinc-700 dark:text-zinc-300'
  }

  const classMap = {
    pendente: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300',
    ativo: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300',
    aguardando_autoridade:
      'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-300',
    fechado: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300',
    cancelado: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300',
  }

  return classMap[status] || 'bg-zinc-100 text-zinc-800 dark:bg-zinc-700 dark:text-zinc-300'
}

// Formatar data
const formatDate = (dateString) => {
  if (!dateString) return 'Não informado'

  const date = new Date(dateString)
  // Verificar se a data é válida
  if (isNaN(date.getTime())) {
    return 'Data inválida'
  }

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

// Ir para a tela de rastreamento
const goToTracking = () => {
  // Verificar se os dados do SOS estão disponíveis
  if (!sos.value) {
    toast.error('Dados do chamado não disponíveis para acessar o rastreamento.')
    return
  }

  // Verificar se o ID do SOS está disponível
  if (!sos.value.id) {
    toast.error('ID do chamado não disponível para acessar o rastreamento.')
    return
  }

  router.push(`/sos/${sos.value.id}/tracking`)
}

// Copiar coordenadas para a área de transferência
const copyCoordinates = () => {
  // Verificar se os dados do SOS estão disponíveis
  if (!sos.value) {
    toast.error('Dados do chamado não disponíveis para copiar coordenadas.')
    return
  }

  // Verificar se as coordenadas estão disponíveis
  if (!sos.value.latitude || !sos.value.longitude) {
    toast.error('Coordenadas do chamado não disponíveis para copiar.')
    return
  }

  // Garantir que as coordenadas sejam números válidos
  const lat = parseFloat(sos.value.latitude)
  const lng = parseFloat(sos.value.longitude)

  if (!isNaN(lat) && !isNaN(lng)) {
    const coordinates = `${lat}, ${lng}`
    navigator.clipboard
      .writeText(coordinates)
      .then(() => {
        toast.success('Coordenadas copiadas para a área de transferência')
      })
      .catch((err) => {
        toast.error('Erro ao copiar coordenadas')
        console.error('Erro ao copiar coordenadas:', err)
      })
  } else {
    toast.error('Coordenadas inválidas para copiar')
  }
}

// Abrir localização no Google Maps
const openInGoogleMaps = () => {
  // Verificar se os dados do SOS estão disponíveis
  if (!sos.value) {
    toast.error('Dados do chamado não disponíveis para abrir no Google Maps.')
    return
  }

  // Verificar se as coordenadas estão disponíveis
  if (!sos.value.latitude || !sos.value.longitude) {
    toast.error('Coordenadas do chamado não disponíveis para abrir no Google Maps.')
    return
  }

  // Garantir que as coordenadas sejam números válidos
  const lat = parseFloat(sos.value.latitude)
  const lng = parseFloat(sos.value.longitude)

  if (!isNaN(lat) && !isNaN(lng)) {
    const url = `https://www.google.com/maps?q=${lat},${lng}`
    window.open(url, '_blank')
  } else {
    toast.error('Coordenadas inválidas para abrir no Google Maps')
  }
}

// Calcular e desenhar a rota
const calculateRoute = async () => {
  // Verificar se o mapa foi inicializado
  if (!map.value) {
    console.error('Tentativa de calcular rota com mapa não inicializado')
    toast.error('Erro ao calcular a rota: mapa não inicializado.')
    return
  }

  if (
    !sos.value ||
    !sos.value.delegacia ||
    !sos.value.delegacia.latitude ||
    !sos.value.delegacia.longitude ||
    !sos.value.latitude ||
    !sos.value.longitude
  ) {
    toast.error('Dados insuficientes para calcular a rota.')
    return
  }

  // Remover camadas existentes se o mapa estiver disponível
  if (routeLayer.value && map.value) {
    try {
      map.value.removeLayer(routeLayer.value)
    } catch (e) {
      console.warn('Erro ao remover camada de rota:', e)
    }
  }
  if (delegaciaMarker.value && map.value) {
    try {
      map.value.removeLayer(delegaciaMarker.value)
    } catch (e) {
      console.warn('Erro ao remover marcador da delegacia:', e)
    }
  }

  routeInfo.value = null
  const start = [
    parseFloat(sos.value.delegacia.longitude),
    parseFloat(sos.value.delegacia.latitude),
  ]
  const end = [parseFloat(sos.value.longitude), parseFloat(sos.value.latitude)]
  if (isNaN(start[0]) || isNaN(start[1]) || isNaN(end[0]) || isNaN(end[1])) {
    toast.error('Coordenadas inválidas para calcular a rota.')
    return
  }
  if (
    start[0] < -180 ||
    start[0] > 180 ||
    start[1] < -90 ||
    start[1] > 90 ||
    end[0] < -180 ||
    end[0] > 180 ||
    end[1] < -90 ||
    end[1] > 90
  ) {
    toast.error('Coordenadas fora dos limites válidos para calcular a rota.')
    return
  }
  start[0] = parseFloat(start[0].toFixed(6))
  start[1] = parseFloat(start[1].toFixed(6))
  end[0] = parseFloat(end[0].toFixed(6))
  end[1] = parseFloat(end[1].toFixed(6))

  // Validação de distância mínima (evitar rotas muito curtas)
  const distance =
    Math.sqrt(Math.pow(start[0] - end[0], 2) + Math.pow(start[1] - end[1], 2)) * 111000 // Aproximação em metros

  if (distance < 10) {
    toast.warning('Pontos muito próximos. Mostrando linha direta.')
    // Fallback: mostrar linha direta
    const directRoute = L.polyline([start, end], {
      color: '#ef4444',
      weight: 3,
      opacity: 0.7,
      dashArray: '5, 5',
    })
    directRoute.addTo(map.value)
    routeLayer.value = directRoute
    return
  }

  try {
    // Corrigir a URL para garantir que as coordenadas estejam no formato correto
    const coordinates = `${start[0]},${start[1]};${end[0]},${end[1]}`
    const url = `https://router.project-osrm.org/route/v1/driving/${coordinates}?overview=full&geometries=geojson&steps=true&alternatives=true&annotations=true`

    // Verificação de disponibilidade removida - não é necessária e pode causar erros
    // Requisição principal com retry e headers adequados (baseado na documentação OSRM)
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), 15000)

    let response
    let retryCount = 0
    const maxRetries = 2

    while (retryCount <= maxRetries) {
      try {
        response = await fetch(url, {
          signal: controller.signal,
        })
        break
      } catch (error) {
        retryCount++
        if (retryCount > maxRetries) throw error
        console.warn(`Tentativa ${retryCount} falhou, tentando novamente...`)
        await new Promise((resolve) => setTimeout(resolve, 1000 * retryCount))
      }
    }

    clearTimeout(timeoutId)

    if (!response.ok) {
      const errorText = await response.text()
      console.error('Erro OSRM:', response.status, errorText)

      // Tratamento específico de erros baseado na documentação OSRM
      if (response.status === 400) {
        throw new Error('Coordenadas inválidas ou formato incorreto.')
      } else if (response.status === 429) {
        throw new Error('Muitas requisições. Aguarde um momento e tente novamente.')
      } else if (response.status >= 500) {
        throw new Error(
          'Servidor OSRM temporariamente indisponível. Tente novamente em alguns minutos.',
        )
      } else {
        throw new Error(`Erro do servidor OSRM (${response.status}). Tente novamente.`)
      }
    }
    const data = await response.json()

    // Validação da resposta baseada na documentação OSRM
    if (data.code && data.code !== 'Ok') {
      throw new Error(`Erro OSRM: ${data.message || 'Código de erro desconhecido'}`)
    }

    if (!data.routes || data.routes.length === 0) {
      throw new Error('Nenhuma rota encontrada entre os pontos especificados.')
    }

    if (data.routes && data.routes.length > 0) {
      let bestRoute = data.routes[0]
      if (data.routes.length > 1)
        bestRoute = data.routes.reduce((fastest, current) =>
          current.duration < fastest.duration ? current : fastest,
        )
      if (!bestRoute.geometry || !bestRoute.geometry.coordinates)
        throw new Error('Geometria da rota inválida na resposta do OSRM.')
      const coordinates = bestRoute.geometry.coordinates.map((coord) => [coord[1], coord[0]])

      // Verificar novamente se o mapa está disponível antes de adicionar a camada
      if (!map.value) {
        console.error('Mapa não disponível ao tentar adicionar camada de rota')
        toast.error('Erro ao calcular a rota: mapa não disponível.')
        return
      }

      routeLayer.value = L.polyline(coordinates, {
        color: '#3b82f6',
        weight: 5,
        opacity: 0.8,
        lineCap: 'round',
        lineJoin: 'round',
      }).addTo(map.value)

      // Verificar novamente se o mapa está disponível antes de ajustar o zoom
      if (map.value && routeLayer.value) {
        map.value.fitBounds(routeLayer.value.getBounds(), { padding: [20, 20] })
      }

      const delegaciaLatLng = [
        parseFloat(sos.value.delegacia.latitude),
        parseFloat(sos.value.delegacia.longitude),
      ]
      if (!isNaN(delegaciaLatLng[0]) && !isNaN(delegaciaLatLng[1])) {
        // Verificar novamente se o mapa está disponível antes de adicionar o marcador
        if (map.value) {
          delegaciaMarker.value = L.marker(delegaciaLatLng)
            .addTo(map.value)
            .bindPopup(
              `<div class="font-semibold">Delegacia:</div>${sos.value.delegacia.nome || 'Desconhecida'}`,
            )
            .openPopup()
        }
      }
      routeInfo.value = {
        distance: `${(bestRoute.distance / 1000).toFixed(2)} km`,
        duration: `${Math.round(bestRoute.duration / 60)} minutos`,
      }
      toast.success('Rota calculada com sucesso!')
    } else {
      throw new Error('Nenhuma rota encontrada.')
    }
  } catch (err) {
    console.error('Erro de roteamento:', err)

    // Fallback: mostrar linha direta em caso de erro
    if (err.name === 'AbortError' || err.message.includes('timeout')) {
      toast.warning('Timeout na requisição. Mostrando linha direta.')
      const directRoute = L.polyline([start, end], {
        color: '#ef4444',
        weight: 3,
        opacity: 0.7,
        dashArray: '5, 5',
      })
      directRoute.addTo(map.value)
      routeLayer.value = directRoute
    } else if (err instanceof TypeError && err.message.includes('fetch')) {
      toast.error('Erro de conexão. Verifique sua internet e tente novamente.')
    } else {
      toast.error(err.message || 'Erro ao calcular a rota. Tente novamente.')
    }
  }
}

// Ciclo de vida
onMounted(() => {
  notificationService.requestNotificationPermission()
  socket.on('update_sos', (updatedSos) => {
    if (updatedSos.id === sos.value?.id) {
      sos.value = { ...sos.value, ...updatedSos }
      notificationService.notifySosUpdate(updatedSos)
    }
  })
  socket.on('rastreamento_update', (trackingPoint) => {
    if (trackingPoint.sos_id === sos.value?.id) {
      if (map.value && marker.value) {
        const latlng = [trackingPoint.latitude, trackingPoint.longitude]
        marker.value.setLatLng(latlng)
        map.value.setView(latlng, 15)
        notificationService.notifyNewTrackingPoint(trackingPoint)
      }
    }
  })
  loadSosDetails()
})

onBeforeUnmount(() => {
  // Remover listeners do WebSocket
  socket.off('update_sos')
  socket.off('rastreamento_update')

  // Remover o mapa se estiver inicializado
  if (map.value) {
    map.value.remove()
    map.value = null
  }

  // Limpar referências aos marcadores e camadas
  marker.value = null
  routeLayer.value = null
  delegaciaMarker.value = null
  routeInfo.value = null
})
</script>
