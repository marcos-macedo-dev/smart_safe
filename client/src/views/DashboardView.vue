<template>
  <div class="container mx-auto py-5">
    <h1 class="text-xl font-bold text-zinc-900 dark:text-white mb-4">Dashboard</h1>

    <!-- Estatísticas -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      <!-- Total de Operadores -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
      >
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
              Operadores
            </p>
            <p class="text-2xl font-bold text-zinc-900 dark:text-white mt-1">
              {{ stats.totalOperadores }}
            </p>
          </div>
          <Users class="w-8 h-8 text-blue-500" />
        </div>
        <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-2">Total de operadores ativos</p>
      </div>

      <!-- SOS Recebidos (7 dias) -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
      >
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
              SOS Recentes
            </p>
            <p class="text-2xl font-bold text-zinc-900 dark:text-white mt-1">
              {{ stats.sos7dias }}
            </p>
          </div>
          <AlertTriangle class="w-8 h-8 text-yellow-500" />
        </div>
        <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-2">Últimos 7 dias</p>
      </div>

      <!-- Tempo Médio de Resposta -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
      >
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
              Tempo Médio
            </p>
            <p class="text-2xl font-bold text-zinc-900 dark:text-white mt-1">
              {{ stats.avgResponseTime }}min
            </p>
          </div>
          <Clock class="w-8 h-8 text-green-500" />
        </div>
        <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-2">Tempo médio de resposta</p>
      </div>

      <!-- Taxa de Resolução -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
      >
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
              Resolução
            </p>
            <p class="text-2xl font-bold text-zinc-900 dark:text-white mt-1">
              {{ stats.taxaResolucao }}%
            </p>
          </div>
          <CheckCircle class="w-8 h-8 text-purple-500" />
        </div>
        <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-2">Taxa de casos resolvidos</p>
      </div>
    </div>

    <!-- Gráficos e Tabelas -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
      <!-- Gráfico de SOS por dia -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
      >
        <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-4">
          SOS nos últimos 7 dias
        </h2>
        <div class="h-64">
          <SosChart :data="dadosGrafico" />
        </div>
      </div>

      <!-- Gráfico de Status dos SOS -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
      >
        <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-4">Status dos SOS</h2>
        <div class="h-64">
          <SosStatusPieChart :data="dadosStatusSos" />
        </div>
      </div>
    </div>

    <!-- Segunda linha de gráficos -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
      <!-- Gráfico de tendência por hora -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
      >
        <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-4">
          Tendência por Hora (24h)
        </h2>
        <div class="h-64">
          <SosAreaChart :data="dadosTendencia" title="SOS por Hora" />
        </div>
      </div>

      <!-- Gráfico de SOS por dia da semana -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
      >
        <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-4">
          SOS por Dia da Semana
        </h2>
        <div class="h-64">
          <SosAreaChart :data="dadosPorDiaSemana" title="SOS por Dia da Semana" />
        </div>
      </div>
    </div>

    <!-- Terceira linha de gráficos -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
      <!-- Gráfico de distribuição por hora -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
      >
        <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-4">
          Distribuição de SOS por Hora
        </h2>
        <div class="h-64">
          <SosAreaChart :data="dadosPorHora" title="SOS por Hora do Dia" />
        </div>
      </div>

      <!-- Tabela de últimas atividades -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
      >
        <h2 class="text-base font-semibold text-zinc-800 dark:text-white mb-4">
          Atividades Recentes
        </h2>
        <div class="space-y-3">
          <div
            v-for="atividade in atividadesRecentes"
            :key="atividade.id"
            class="flex items-start py-2 border-b border-zinc-100 dark:border-zinc-700 last:border-0"
          >
            <div class="flex-shrink-0 mt-1">
              <div
                class="w-8 h-8 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center"
              >
                <component
                  :is="getActivityIcon(atividade.titulo)"
                  class="w-4 h-4 text-blue-600 dark:text-blue-400"
                />
              </div>
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-zinc-900 dark:text-white">
                {{ atividade.titulo }}
              </p>
              <p class="text-xs text-zinc-500 dark:text-zinc-400">{{ atividade.descricao }}</p>
              <p class="text-xs text-zinc-400 dark:text-zinc-500 mt-1">{{ atividade.data }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Gráfico de SOS por mês (ocupando largura total) -->
    <div
      class="mt-6 bg-white dark:bg-zinc-800 rounded-md shadow-sm p-4 border border-zinc-200 dark:border-zinc-700"
    >
      <div class="flex justify-between items-center mb-4">
        <h2 class="text-base font-semibold text-zinc-800 dark:text-white">
          SOS por semana ({{ formatarMesAno(mesSelecionado) }})
        </h2>
        <div class="flex items-center gap-2">
          <select
            v-model="mesSelecionado"
            @change="carregarDadosMensais"
            class="px-2 py-1 border border-zinc-300 dark:border-zinc-600 rounded-md focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 dark:bg-zinc-700 dark:text-white text-sm"
          >
            <option v-for="mes in mesesDisponiveis" :key="mes.valor" :value="mes.valor">
              {{ mes.nome }}
            </option>
          </select>
        </div>
      </div>
      <div class="h-64">
        <SosMonthlyChart :data="dadosGraficoSemanal" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Users, AlertTriangle, CheckCircle, UserPlus, Clock } from 'lucide-vue-next'
import { listDelegaciaUsers, listSos, getDelegaciaStats, getDelegaciaSosByHour, getDelegaciaSosByDayOfWeek } from '@/services/http'
import { useToastStore } from '@/stores/toast'
import SosChart from '@/components/SosChart.vue'
import SosMonthlyChart from '@/components/SosMonthlyChart.vue'
import SosStatusPieChart from '@/components/SosStatusPieChart.vue'
import SosAreaChart from '@/components/SosAreaChart.vue'

// Stores
const toast = useToastStore()

// Estado
const stats = ref({
  totalOperadores: 0,
  totalDelegacias: 0,
  sos7dias: 0,
  taxaResolucao: 0,
  sosPendentes: 0,
  sosAtivos: 0,
  sosAguardando: 0,
  sosFechados: 0,
  sosCancelados: 0,
  avgResponseTime: 0,
  mediaPercentage: 0,
  sosLast7Days: 0
})

const atividadesRecentes = ref([])
const dadosGrafico = ref([])
const dadosGraficoSemanal = ref([])
const dadosStatusSos = ref([])
const dadosTendencia = ref([])
const dadosPorHora = ref([])
const dadosPorDiaSemana = ref([])

// Estado para seleção de mês
const mesesDisponiveis = ref([])
const mesSelecionado = ref(new Date().toISOString().slice(0, 7)) // Formato YYYY-MM

// ==================== FUNÇÕES DE CARREGAMENTO ====================
const carregarEstatisticas = async () => {
  try {
    const [operadoresResp, delegaciaStatsResp, sosPorHoraResp, sosPorDiaSemanaResp] = await Promise.all([
      listDelegaciaUsers(),
      getDelegaciaStats(),
      getDelegaciaSosByHour(),
      getDelegaciaSosByDayOfWeek()
    ])
    
    const operadores = operadoresResp.data || []
    const delegaciaStats = delegaciaStatsResp.data || {}
    const sosPorHora = sosPorHoraResp.data || {}
    const sosPorDiaSemana = sosPorDiaSemanaResp.data || {}
    
    // Atualizar estatísticas básicas
    stats.value.totalOperadores = operadores.filter((user) => user && user.ativo).length
    stats.value.totalDelegacias = 1 // Apenas a delegacia do usuário logado
    
    // Atualizar estatísticas da delegacia
    const overview = delegaciaStats.overview || {}
    stats.value.sos7dias = overview.sosLast7Days || 0
    stats.value.taxaResolucao = overview.resolutionRate || 0
    stats.value.sosPendentes = (delegaciaStats.byStatus && delegaciaStats.byStatus.pendente) || 0
    stats.value.sosAtivos = (delegaciaStats.byStatus && delegaciaStats.byStatus.ativo) || 0
    stats.value.sosAguardando = (delegaciaStats.byStatus && delegaciaStats.byStatus.aguardando_autoridade) || 0
    stats.value.sosFechados = (delegaciaStats.byStatus && delegaciaStats.byStatus.fechado) || 0
    stats.value.sosCancelados = (delegaciaStats.byStatus && delegaciaStats.byStatus.cancelado) || 0
    stats.value.avgResponseTime = overview.avgResponseTime || 0
    stats.value.mediaPercentage = overview.mediaPercentage || 0
    
    // Preparar dados para gráficos
    const latestSos = delegaciaStats.latestSos || []
    prepararDadosGrafico(latestSos)
    prepararDadosStatusSos()
    prepararDadosTendencia(latestSos)
    dadosPorHora.value = Object.entries(sosPorHora).map(([hora, quantidade]) => ({
      label: `${hora}:00`,
      value: quantidade
    }))
    dadosPorDiaSemana.value = Object.entries(sosPorDiaSemana).map(([dia, quantidade]) => ({
      label: dia,
      value: quantidade
    }))
    
    // Carregar atividades recentes
    carregarAtividadesRecentes(operadores, latestSos)
    
    return { operadores, delegaciaStats }
  } catch (error) {
    console.error('Erro ao carregar estatísticas:', error)
    toast.error('Erro ao carregar dados do dashboard')
    return { operadores: [], delegaciaStats: { latestSos: [] } }
  }
}

const carregarAtividadesRecentes = (operadores, sosList) => {
  try {
    // Verificar se os dados existem
    const operadoresValidos = Array.isArray(operadores) ? operadores : []
    const sosValidos = Array.isArray(sosList) ? sosList : []

    // Atividades de operadores
    const atividadesOperadores = operadoresValidos.slice(0, 3).map((operador) => ({
      id: `op-${operador.id}`,
      titulo: `Novo operador adicionado`,
      descricao: `${operador.nome} foi adicionado como ${operador.cargo}`,
      data: operador.createdAt,
    }))

    // Atividades de SOS
    const atividadesSos = sosValidos.slice(0, 3).map((sos) => ({
      id: `sos-${sos.id}`,
      titulo: `Novo SOS recebido`,
      descricao: `SOS #${sos.id} recebido`,
      data: sos.createdAt,
    }))

    // Combinar e ordenar por data
    const todasAtividades = [...atividadesSos, ...atividadesOperadores]
      .filter(a => a.data) // Filtrar atividades sem data
      .sort((a, b) => new Date(b.data) - new Date(a.data))
      .slice(0, 4)

    atividadesRecentes.value = todasAtividades.map((a) => ({ ...a, data: formatarData(a.data) }))
  } catch (error) {
    console.error('Erro ao carregar atividades recentes:', error)
    atividadesRecentes.value = []
  }
}

// ==================== FUNÇÕES DE PROCESSAMENTO ====================
const prepararDadosGrafico = (sosList) => {
  // Criar um mapa para contar SOS por dia
  const sosPorDia = new Map()

  // Inicializar os últimos 7 dias com 0
  for (let i = 6; i >= 0; i--) {
    const data = new Date()
    data.setDate(data.getDate() - i)
    const dataFormatada = data.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
    })
    sosPorDia.set(dataFormatada, 0)
  }

  // Contar SOS por dia
  sosList.forEach((sos) => {
    const data = new Date(sos.createdAt)
    const dataFormatada = data.toLocaleDateString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
    })

    if (sosPorDia.has(dataFormatada)) {
      sosPorDia.set(dataFormatada, sosPorDia.get(dataFormatada) + 1)
    }
  })

  // Converter mapa para array
  const dados = []
  sosPorDia.forEach((quantidade, data) => {
    dados.push({ data, quantidade })
  })

  dadosGrafico.value = dados
}

const prepararDadosStatusSos = () => {
  dadosStatusSos.value = [
    { status: 'Pendentes', quantidade: stats.value.sosPendentes, cor: '#f59e0b' },
    { status: 'Ativos', quantidade: stats.value.sosAtivos, cor: '#3b82f6' },
    { status: 'Aguardando', quantidade: stats.value.sosAguardando, cor: '#8b5cf6' },
    { status: 'Fechados', quantidade: stats.value.sosFechados, cor: '#10b981' },
    { status: 'Cancelados', quantidade: stats.value.sosCancelados, cor: '#ef4444' },
  ]
}

const prepararDadosTendencia = (sosList) => {
  // Agrupar SOS por hora nas últimas 24 horas
  const sosPorHora = new Map()

  // Inicializar as últimas 24 horas com 0
  for (let i = 23; i >= 0; i--) {
    const hora = new Date()
    hora.setHours(hora.getHours() - i)
    const horaFormatada = hora.getHours().toString().padStart(2, '0') + ':00'
    sosPorHora.set(horaFormatada, 0)
  }

  // Contar SOS por hora
  sosList.forEach((sos) => {
    const data = new Date(sos.createdAt)
    const agora = new Date()
    const diffHoras = Math.floor((agora - data) / (1000 * 60 * 60))

    if (diffHoras >= 0 && diffHoras < 24) {
      const horaFormatada = data.getHours().toString().padStart(2, '0') + ':00'
      if (sosPorHora.has(horaFormatada)) {
        sosPorHora.set(horaFormatada, sosPorHora.get(horaFormatada) + 1)
      }
    }
  })

  // Converter para array
  const dados = []
  sosPorHora.forEach((quantidade, hora) => {
    dados.push({ label: hora, value: quantidade })
  })

  dadosTendencia.value = dados
}

// ==================== FUNÇÕES AUXILIARES ====================
const formatarData = (dataString) => {
  const data = new Date(dataString)
  const agora = new Date()
  const diffMs = agora - data
  const diffMins = Math.floor(diffMs / 60000)
  const diffHoras = Math.floor(diffMs / 3600000)
  const diffDias = Math.floor(diffMs / 86400000)

  if (diffMins < 60) {
    return `Há ${diffMins} minutos`
  } else if (diffHoras < 24) {
    return `Há ${diffHoras} horas`
  } else {
    return `Há ${diffDias} dias`
  }
}

const getActivityIcon = (titulo) => {
  return titulo.includes('SOS') ? AlertTriangle : UserPlus
}

const formatarMesAno = (mesAno) => {
  if (!mesAno) return ''
  const [ano, mes] = mesAno.split('-')
  const data = new Date(ano, mes - 1, 1)
  return data.toLocaleDateString('pt-BR', {
    month: 'long',
    year: 'numeric',
  })
}

const gerarListaMeses = () => {
  const meses = []
  const hoje = new Date()

  // Gerar os últimos 12 meses
  for (let i = 0; i < 12; i++) {
    const data = new Date(hoje.getFullYear(), hoje.getMonth() - i, 1)
    const valor = data.toISOString().slice(0, 7) // Formato YYYY-MM
    const nome = data.toLocaleDateString('pt-BR', {
      month: 'long',
      year: 'numeric',
    })

    meses.push({ valor, nome })
  }

  // Ordenar do mais recente para o mais antigo
  meses.reverse()
  mesesDisponiveis.value = meses
}

const carregarDadosMensais = async () => {
  try {
    const [ano, mes] = mesSelecionado.value.split('-')
    const dataInicio = new Date(ano, mes - 1, 1)
    const dataFim = new Date(ano, mes, 0) // Último dia do mês

    const responseSos = await listSos({
      startDate: dataInicio.toISOString(),
      endDate: dataFim.toISOString(),
    })

    const sosList = responseSos.data

    // Criar um mapa para contar SOS por semana
    const sosPorSemana = new Map()

    // Inicializar semanas do mês
    const primeiroDia = new Date(dataInicio)
    const ultimoDia = new Date(dataFim)

    // Criar intervalos de uma semana
    let inicioSemana = new Date(primeiroDia)
    while (inicioSemana <= ultimoDia) {
      const fimSemana = new Date(inicioSemana)
      fimSemana.setDate(fimSemana.getDate() + 6)

      // Limitar ao último dia do mês
      if (fimSemana > ultimoDia) {
        fimSemana.setTime(ultimoDia.getTime())
      }

      const chave = `${inicioSemana.getDate()}-${fimSemana.getDate()}`
      sosPorSemana.set(chave, 0)

      inicioSemana.setDate(inicioSemana.getDate() + 7)
    }

    // Contar SOS por semana
    sosList.forEach((sos) => {
      const dataSos = new Date(sos.createdAt)

      // Determinar em qual semana o SOS se encaixa
      let inicioSemana = new Date(primeiroDia)
      while (inicioSemana <= ultimoDia) {
        const fimSemana = new Date(inicioSemana)
        fimSemana.setDate(fimSemana.getDate() + 6)

        // Limitar ao último dia do mês
        if (fimSemana > ultimoDia) {
          fimSemana.setTime(ultimoDia.getTime())
        }

        if (dataSos >= inicioSemana && dataSos <= fimSemana) {
          const chave = `${inicioSemana.getDate()}-${fimSemana.getDate()}`
          sosPorSemana.set(chave, (sosPorSemana.get(chave) || 0) + 1)
          break
        }

        inicioSemana.setDate(inicioSemana.getDate() + 7)
      }
    })

    // Converter mapa para array
    const dados = []
    sosPorSemana.forEach((quantidade, semana) => {
      dados.push({
        mes: `Semana ${semana}`,
        quantidade,
      })
    })

    dadosGraficoSemanal.value = dados
  } catch (error) {
    console.error('Erro ao carregar dados mensais:', error)
    toast.error('Erro ao carregar dados do mês selecionado')
  }
}

// ==================== LIFECYCLE ====================
onMounted(async () => {
  const { operadores, sosList } = await carregarEstatisticas()
  carregarAtividadesRecentes(operadores, sosList)
  gerarListaMeses()
  await carregarDadosMensais()
})
</script>
