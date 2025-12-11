<template>
  <div class="h-screen flex items-center justify-center bg-zinc-900 px-4">
    <div class="w-full max-w-md rounded-3xl p-8 bg-zinc-800 shadow-xl">
      <header class="mb-6 text-center">
        <h1 class="text-2xl font-extrabold text-white mb-2">Registro de Delegacia</h1>
        <p class="text-gray-300 text-sm">
          Preencha os dados da delegacia e do administrador principal
        </p>
      </header>

      <form @submit.prevent="handleSubmit" class="space-y-5" novalidate>
        <div
          class="rounded-2xl border border-zinc-700 bg-zinc-800/40 px-4 py-3 text-xs text-gray-300"
        >
          <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div class="flex items-center gap-2">
              <MapPin class="h-3.5 w-3.5 text-emerald-400" />
              <span>Use o mapa para pegar coordenadas e preencher o endereço automaticamente.</span>
            </div>
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-xl bg-emerald-500 px-3 py-2 font-semibold text-white transition hover:bg-emerald-400"
              @click="openMapModal"
            >
              <MapPin class="h-4 w-4" />
              <span>Escolher no mapa</span>
            </button>
          </div>
        </div>

        <!-- Dados da Delegacia -->

        <div>
          <label for="nome_delegacia" class="form-label">
            Nome da Delegacia <span class="text-red-500">*</span>
          </label>
          <input
            id="nome_delegacia"
            v-model="formData.delegacia.nome"
            type="text"
            required
            placeholder="Digite o nome da delegacia"
            class="form-input"
          />
        </div>

        <div>
          <label for="endereco" class="form-label">
            Endereço <span class="text-red-500">*</span>
          </label>
          <input
            id="endereco"
            v-model="formData.delegacia.endereco"
            type="text"
            required
            placeholder="Digite o endereço completo"
            class="form-input"
          />
        </div>

        <div class="grid grid-cols-2 gap-3">
          <div>
            <label for="latitude" class="form-label">
              Latitude <span class="text-red-500">*</span>
            </label>
            <input
              id="latitude"
              v-model="formData.delegacia.latitude"
              type="number"
              step="any"
              required
              placeholder="Ex: -23.550520"
              class="form-input"
            />
          </div>

          <div>
            <label for="longitude" class="form-label">
              Longitude <span class="text-red-500">*</span>
            </label>
            <input
              id="longitude"
              v-model="formData.delegacia.longitude"
              type="number"
              step="any"
              required
              placeholder="Ex: -46.633308"
              class="form-input"
            />
          </div>
        </div>

        <div>
          <label for="telefone" class="form-label"> Telefone </label>
          <input
            id="telefone"
            v-model="formData.delegacia.telefone"
            v-maska="'(##) #####-####'"
            type="text"
            placeholder="Digite o telefone"
            class="form-input"
          />
        </div>

        <!-- Dados do Administrador -->
        <div>
          <label for="nome_admin" class="form-label">
            Nome do Responsável <span class="text-red-500">*</span>
          </label>
          <input
            id="nome_admin"
            v-model="formData.administrador.nome"
            type="text"
            required
            placeholder="Digite o nome completo"
            class="form-input"
          />
        </div>

        <div>
          <label for="email_admin" class="form-label">
            Email do Responsável <span class="text-red-500">*</span>
          </label>
          <input
            id="email_admin"
            v-model="formData.administrador.email"
            type="email"
            required
            placeholder="Digite o email"
            class="form-input"
          />
        </div>

        <button type="submit" class="form-button">
          <Send class="w-4 h-4" />
          <span>Enviar Solicitação</span>
        </button>
      </form>

      <Transition name="fade">
        <div
          v-if="showMapModal"
          class="fixed inset-0 z-50 flex items-center justify-center px-4"
          aria-modal="true"
          role="dialog"
        >
          <div class="absolute inset-0 bg-black/60" @click="closeMapModal"></div>
          <div
            class="relative w-full max-w-2xl rounded-3xl border border-zinc-700 bg-zinc-900 p-6 shadow-2xl"
          >
            <header class="mb-4 flex items-start justify-between gap-3">
              <div>
                <h2 class="text-lg font-semibold text-white">Selecionar localização</h2>
                <p class="text-xs text-gray-400">
                  Clique no mapa ou arraste o marcador para ajustar a posição da delegacia.
                </p>
              </div>
              <button
                type="button"
                class="text-xs font-semibold text-gray-400 transition hover:text-gray-200"
                @click="closeMapModal"
              >
                Fechar
              </button>
            </header>

            <div class="space-y-3">
              <form class="flex gap-2" @submit.prevent="handleSearch">
                <input
                  v-model="searchQuery"
                  type="text"
                  placeholder="Buscar endereço ou ponto de referência"
                  class="flex-1 rounded-xl border border-zinc-700 bg-zinc-900 px-3 py-2 text-sm text-white placeholder:text-gray-500 focus:border-emerald-400 focus:outline-none"
                />
                <button
                  type="submit"
                  class="rounded-xl bg-emerald-500 px-3 py-2 text-sm font-semibold text-white transition hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-60"
                  :disabled="isSearching"
                >
                  {{ isSearching ? 'Buscando...' : 'Pesquisar' }}
                </button>
              </form>

              <Transition name="fade">
                <template v-if="searchResults.length">
                  <ul
                    class="max-h-32 space-y-2 overflow-y-auto rounded-xl border border-zinc-700 bg-zinc-900/80 p-3 text-xs text-gray-200"
                  >
                    <li
                      v-for="result in searchResults"
                      :key="result.place_id"
                      class="cursor-pointer rounded-lg border border-transparent px-3 py-2 transition hover:border-emerald-500 hover:bg-emerald-500/10"
                      @click="handleResultSelect(result)"
                    >
                      <p class="font-semibold text-white">{{ result.title }}</p>
                      <p class="text-gray-400">{{ result.subtitle }}</p>
                    </li>
                  </ul>
                </template>
              </Transition>

              <p
                v-if="hasSearched && !isSearching && !searchResults.length"
                class="text-xs text-gray-500"
              >
                Nenhum resultado encontrado. Tente outros termos ou seja mais específico.
              </p>

              <div
                class="h-72 w-full overflow-hidden rounded-2xl border border-zinc-700 bg-zinc-900"
              >
                <LMap
                  ref="mapRef"
                  v-model:zoom="mapState.zoom"
                  :center="mapState.center"
                  :options="mapOptions"
                  @click="handleMapClick"
                >
                  <LTileLayer :url="tileUrl" :attribution="tileAttribution" />
                  <LMarker
                    v-if="mapState.marker"
                    :lat-lng="mapState.marker"
                    draggable
                    @moveend="handleMarkerMoved"
                  />
                </LMap>
              </div>
            </div>

            <footer
              class="mt-4 flex flex-col gap-2 text-xs text-gray-400 sm:flex-row sm:items-center sm:justify-between"
            >
              <span>
                Coordenadas atuais:
                <span class="font-semibold text-white">
                  {{ formData.delegacia.latitude || '-' }},
                  {{ formData.delegacia.longitude || '-' }}
                </span>
              </span>
              <button
                type="button"
                class="inline-flex items-center gap-2 rounded-xl bg-emerald-500 px-3 py-2 font-semibold text-white transition hover:bg-emerald-400"
                @click="closeMapModal"
              >
                Concluir
              </button>
            </footer>
          </div>
        </div>
      </Transition>

      <div class="mt-5 text-center text-gray-400 text-xs">
        <p>
          Após o envio, a solicitação será revisada pela equipe.<br />
          Se aprovada, um convite será enviado à unidade.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { nextTick, onMounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { MapPin, Send } from 'lucide-vue-next'
import { registerDelegacia } from '@/services/http'
import { vMaska } from 'maska/vue'
import { useToastStore } from '@/stores/toast'
import { LMap, LTileLayer, LMarker } from '@vue-leaflet/vue-leaflet'
import { Icon } from 'leaflet'
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png'
import markerIcon from 'leaflet/dist/images/marker-icon.png'
import markerShadow from 'leaflet/dist/images/marker-shadow.png'
import 'leaflet/dist/leaflet.css'

const router = useRouter()
const toast = useToastStore()

const formData = reactive({
  delegacia: {
    nome: '',
    endereco: '',
    latitude: '',
    longitude: '',
    telefone: '',
  },
  administrador: {
    nome: '',
    email: '',
  },
})

const showMapModal = ref(false)
const mapRef = ref(null)
const searchQuery = ref('')
const searchResults = ref([])
const isSearching = ref(false)
const hasSearched = ref(false)

const mapState = reactive({
  zoom: 5,
  center: [-15.793889, -47.882778],
  marker: null,
})

const tileUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
const tileAttribution = '© OpenStreetMap contributors'
const mapOptions = {
  zoomControl: true,
  attributionControl: true,
}

const SEARCH_KEYWORDS = ['delegacia', 'polícia', 'policia', 'police', 'civil', 'militar']
const MAX_SEARCH_RESULTS = 12
const MAX_QUERY_VARIATIONS = 8

Icon.Default.mergeOptions({
  iconRetinaUrl: markerIcon2x,
  iconUrl: markerIcon,
  shadowUrl: markerShadow,
})

onMounted(() => {
  syncMapWithForm()
})

function openMapModal() {
  showMapModal.value = true
  resetSearch()
  nextTick(() => {
    mapRef.value?.leafletObject?.invalidateSize?.()
    syncMapWithForm()
  })
}

function closeMapModal() {
  showMapModal.value = false
  resetSearch()
}

async function handleSearch() {
  const query = searchQuery.value.trim()

  if (query.length < 3) {
    toast.error('Digite ao menos 3 caracteres para pesquisar.')
    return
  }

  try {
    isSearching.value = true
    searchAbortController?.abort()
    searchAbortController = new AbortController()
    searchResults.value = []
    hasSearched.value = false

    const focus = getSearchFocus()
    const variations = buildSearchQueries(query)
    const aggregatedResults = new Map()
    let hadSuccessfulResponse = false

    for (let index = 0; index < variations.length; index += 1) {
      if (aggregatedResults.size >= MAX_SEARCH_RESULTS) {
        break
      }

      const variant = variations[index]
      const params = new URLSearchParams({
        format: 'jsonv2',
        q: variant,
        addressdetails: '1',
        limit: '6',
        dedupe: '1',
        namedetails: '1',
        extratags: '1',
        countrycodes: 'br',
      })

      if (focus) {
        const radius = 0.6
        const left = focus.lng - radius
        const right = focus.lng + radius
        const top = focus.lat + radius
        const bottom = focus.lat - radius
        params.set('viewbox', `${left},${top},${right},${bottom}`)
        params.set('bounded', '1')
      }

      const response = await fetch(
        `https://nominatim.openstreetmap.org/search?${params.toString()}`,
        {
          headers: {
            Accept: 'application/json',
            'Accept-Language': 'pt-BR',
          },
          signal: searchAbortController.signal,
        },
      )

      if (!response.ok) {
        continue
      }

      const data = await response.json()
      hadSuccessfulResponse = true

      data.forEach((item) => {
        if (aggregatedResults.size >= MAX_SEARCH_RESULTS) {
          return
        }
        if (aggregatedResults.has(item.place_id)) {
          return
        }
        const prepared = prepareSearchResult(item, index, focus)
        aggregatedResults.set(item.place_id, prepared)
      })
    }

    if (!hadSuccessfulResponse) {
      toast.error('Não foi possível buscar no mapa agora. Tente novamente.')
      return
    }

    const sortedResults = Array.from(aggregatedResults.values()).sort((a, b) => {
      if (a.matchRank !== b.matchRank) {
        return a.matchRank - b.matchRank
      }

      const distanceA = Number.isFinite(a.distanceKm) ? a.distanceKm : Number.POSITIVE_INFINITY
      const distanceB = Number.isFinite(b.distanceKm) ? b.distanceKm : Number.POSITIVE_INFINITY
      if (distanceA !== distanceB) {
        return distanceA - distanceB
      }

      if (a.variantIndex !== b.variantIndex) {
        return a.variantIndex - b.variantIndex
      }

      return (b.importance || 0) - (a.importance || 0)
    })

    searchResults.value = sortedResults.map((item) => {
      const distanceKm =
        Number.isFinite(item.distanceKm) && item.distanceKm > 0.1 ? item.distanceKm : null
      let subtitleText = item.subtitle

      if (distanceKm !== null) {
        subtitleText = subtitleText
          ? `${subtitleText} • aprox. ${distanceKm.toFixed(1)} km`
          : `Aprox. ${distanceKm.toFixed(1)} km do ponto selecionado`
      }

      return {
        place_id: item.place_id,
        lat: item.lat,
        lon: item.lon,
        title: item.title,
        subtitle: subtitleText.trim(),
      }
    })
    hasSearched.value = true
  } catch (error) {
    if (error.name === 'AbortError') {
      return
    }
    toast.error('Algo deu errado ao buscar esse endereço.')
  } finally {
    isSearching.value = false
    searchAbortController = null
  }
}

function handleResultSelect(result) {
  if (!result) return
  applyCoordinates(result.lat, result.lon, { fetchAddress: true, adjustZoom: true })
  searchQuery.value = result.title
  searchResults.value = []
  hasSearched.value = false
  toast.success('Local selecionado no mapa.')
}

function applyCoordinates(lat, lng, { fetchAddress = false, adjustZoom = false } = {}) {
  formData.delegacia.latitude = lat.toFixed(6)
  formData.delegacia.longitude = lng.toFixed(6)
  mapState.center = [lat, lng]
  mapState.marker = [lat, lng]

  if (adjustZoom && mapState.zoom < 14) {
    mapState.zoom = 14
  }

  if (fetchAddress) {
    reverseGeocode(lat, lng)
  }
}

function handleMapClick(event) {
  const { latlng } = event
  if (!latlng) return
  applyCoordinates(latlng.lat, latlng.lng, { fetchAddress: true, adjustZoom: true })
}

function handleMarkerMoved(event) {
  const latlng = event.target?.getLatLng?.()
  if (!latlng) return
  applyCoordinates(latlng.lat, latlng.lng, { fetchAddress: true })
}

function syncMapWithForm() {
  const lat = parseFloat(formData.delegacia.latitude)
  const lng = parseFloat(formData.delegacia.longitude)

  if (Number.isFinite(lat) && Number.isFinite(lng)) {
    mapState.center = [lat, lng]
    mapState.marker = [lat, lng]
    if (mapState.zoom < 14) {
      mapState.zoom = 14
    }
  }
}

watch(
  () => [formData.delegacia.latitude, formData.delegacia.longitude],
  ([lat, lng]) => {
    const parsedLat = parseFloat(lat)
    const parsedLng = parseFloat(lng)

    if (!Number.isFinite(parsedLat) || !Number.isFinite(parsedLng)) {
      return
    }

    const [currentLat, currentLng] = mapState.marker || []
    const deltaLat = Math.abs((currentLat ?? Infinity) - parsedLat)
    const deltaLng = Math.abs((currentLng ?? Infinity) - parsedLng)

    if (deltaLat < 1e-6 && deltaLng < 1e-6) {
      return
    }

    mapState.center = [parsedLat, parsedLng]
    mapState.marker = [parsedLat, parsedLng]
  },
)

watch(showMapModal, (visible) => {
  if (visible) {
    nextTick(() => {
      mapRef.value?.leafletObject?.invalidateSize?.()
      syncMapWithForm()
    })
  }
})

let reverseGeocodeAbortController = null
let searchAbortController = null

function normalizeQueryString(raw) {
  return raw
    .replace(/\s+/g, ' ')
    .replace(/\s*,\s*/g, ', ')
    .replace(/\s*-\s*/g, ' - ')                       
    .replace(/(\d+)\s*-\s*(\d+)/g, '$1-$2')
    .replace(/,\s*-\s*/g, ', ')
    .replace(/-\s*,/g, ', ')
    .replace(/,\s*$/, '')
    .replace(/-\s*$/, '')
    .trim()
}

function createAddressVariants(query) {
  const variants = new Set()
  const base = normalizeQueryString(query)
  if (!base) {
    return []
  }
  variants.add(base)

  const withoutCEP = normalizeQueryString(base.replace(/\b\d{5}(?:-?\d{3})?\b/gi, ''))
  if (withoutCEP && withoutCEP !== base) {
    variants.add(withoutCEP)
  }

  const singleNumber = normalizeQueryString(base.replace(/(\d+)\s*-\s*(\d+)/g, '$1'))
  if (singleNumber && singleNumber !== base) {
    variants.add(singleNumber)
    const singleNumberWithoutCEP = normalizeQueryString(
      singleNumber.replace(/\b\d{5}(?:-?\d{3})?\b/gi, ''),
    )
    if (singleNumberWithoutCEP && singleNumberWithoutCEP !== singleNumber) {
      variants.add(singleNumberWithoutCEP)
    }
  }

  const withoutNumbers = normalizeQueryString(base.replace(/\b\d+\b/g, '').replace(/\s*,\s*,/g, ','))
  if (withoutNumbers && withoutNumbers !== base) {
    variants.add(withoutNumbers)
  }

  const beforeDash = base.split(' - ')[0]
  if (beforeDash && beforeDash !== base) {
    variants.add(normalizeQueryString(beforeDash))
  }

  const components = base.split(',')
  if (components.length > 2) {
    const withoutLastComponent = normalizeQueryString(components.slice(0, -1).join(','))
    if (withoutLastComponent && withoutLastComponent !== base) {
      variants.add(withoutLastComponent)
    }
  }

  return Array.from(variants)
}

function buildSearchQueries(query) {
  const baseVariants = createAddressVariants(query)
  const finalVariants = []
  const seen = new Set()

  const pushVariant = (value) => {
    const normalized = normalizeQueryString(value)
    if (!normalized || seen.has(normalized.toLowerCase())) {
      return
    }
    seen.add(normalized.toLowerCase())
    finalVariants.push(normalized)
  }

  baseVariants.forEach(pushVariant)

  baseVariants.forEach((variant) => {
    const lower = variant.toLowerCase()
    if (lower.includes('delegacia')) {
      return
    }
    pushVariant(`${variant} delegacia`)
    pushVariant(`Delegacia ${variant}`)
  })

  baseVariants.forEach((variant) => {
    const lower = variant.toLowerCase()
    if (lower.includes('polícia') || lower.includes('policia')) {
      return
    }
    pushVariant(`${variant} polícia civil`)
  })

  return finalVariants.slice(0, MAX_QUERY_VARIATIONS)
}

function getSearchFocus() {
  const lat = parseFloat(formData.delegacia.latitude)
  const lng = parseFloat(formData.delegacia.longitude)

  if (Number.isFinite(lat) && Number.isFinite(lng)) {
    return { lat, lng }
  }

  if (Array.isArray(mapState.marker) && mapState.marker.length === 2) {
    const [markerLat, markerLng] = mapState.marker
    if (Number.isFinite(markerLat) && Number.isFinite(markerLng)) {
      return { lat: markerLat, lng: markerLng }
    }
  }

  return null
}

function computeDistanceKm(lat1, lon1, lat2, lon2) {
  if (!Number.isFinite(lat1) || !Number.isFinite(lon1) || !Number.isFinite(lat2) || !Number.isFinite(lon2)) {
    return null
  }

  const toRad = (deg) => (deg * Math.PI) / 180
  const R = 6371
  const dLat = toRad(lat2 - lat1)
  const dLon = toRad(lon2 - lon1)
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  return R * c
}

function prepareSearchResult(item, variantIndex, focus) {
  const lat = parseFloat(item.lat)
  const lon = parseFloat(item.lon)

  const rawParts = (item.display_name || '')
    .split(',')
    .map((part) => part.trim())
    .filter(Boolean)
  const [rawTitle, ...restParts] = rawParts

  const title =
    item.namedetails?.name ||
    rawTitle ||
    item.address?.police ||
    item.address?.amenity ||
    'Local encontrado'

  const subtitleRaw = restParts.join(', ') || item.address?.city || item.address?.state || ''
  const subtitle = subtitleRaw.trim()
  const combinedText = `${title} ${subtitle}`.toLowerCase()
  const hasKeyword = SEARCH_KEYWORDS.some((keyword) => combinedText.includes(keyword))
  const isPoliceAmenity = item.class === 'amenity' && item.type === 'police'
  const matchRank = isPoliceAmenity ? 0 : hasKeyword ? 1 : 2
  const importance = Number.isFinite(item.importance)
    ? item.importance
    : parseFloat(item.importance) || 0

  const distanceKm = focus ? computeDistanceKm(focus.lat, focus.lng, lat, lon) : null

  return {
    place_id: item.place_id,
    lat,
    lon,
    title,
    subtitle,
    matchRank,
    variantIndex,
    importance,
    distanceKm,
  }
}

function resetSearch() {
  searchAbortController?.abort()
  searchAbortController = null
  searchQuery.value = ''
  searchResults.value = []
  isSearching.value = false
  hasSearched.value = false
}

async function reverseGeocode(lat, lng) {
  try {
    reverseGeocodeAbortController?.abort()
    reverseGeocodeAbortController = new AbortController()

    const params = new URLSearchParams({
      format: 'jsonv2',
      lat: String(lat),
      lon: String(lng),
      addressdetails: '1',
    })

    const response = await fetch(
      `https://nominatim.openstreetmap.org/reverse?${params.toString()}`,
      {
        headers: {
          Accept: 'application/json',
          'Accept-Language': 'pt-BR',
        },
        signal: reverseGeocodeAbortController.signal,
      },
    )

    if (!response.ok) {
      return
    }

    const data = await response.json()
    const address = data.address || {}

    const cidade =
      address.city ||
      address.town ||
      address.municipality ||
      address.village ||
      address.state_district
    const uf = address.state || address.region
    const enderecoPartes = [
      address.road || address.pedestrian || address.cycleway,
      address.suburb || address.neighbourhood,
      cidade && uf ? `${cidade} - ${uf}` : cidade || uf,
    ].filter(Boolean)

    if (enderecoPartes.length) {
      formData.delegacia.endereco = enderecoPartes.join(', ')
    }
  } catch (error) {
    if (error.name === 'AbortError') {
      return
    }
    // Ignora falhas intermitentes de geocodificação sem interromper o usuário
  } finally {
    reverseGeocodeAbortController = null
  }
}

async function handleSubmit() {
  // Validar coordenadas
  const lat = parseFloat(formData.delegacia.latitude)
  const lng = parseFloat(formData.delegacia.longitude)

  if (isNaN(lat) || lat < -90 || lat > 90) {
    toast.error('Latitude inválida. Deve estar entre -90 e 90.')
    return
  }

  if (isNaN(lng) || lng < -180 || lng > 180) {
    toast.error('Longitude inválida. Deve estar entre -180 e 180.')
    return
  }

  try {
    await registerDelegacia({
      delegaciaData: {
        ...formData.delegacia,
        latitude: lat,
        longitude: lng,
      },
      administradorData: formData.administrador,
    })

    toast.success('Solicitação enviada com sucesso! Aguarde a aprovação.')
    router.push('/login')
  } catch (error) {
    toast.error(error.value)
  }
}
</script>
