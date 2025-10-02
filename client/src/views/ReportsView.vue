<template>
  <div class="container mx-auto py-5">
    <!-- Cabeçalho -->
    <div class="flex flex-col lg:flex-row justify-between items-start lg:items-center mb-6 gap-4">
      <div>
        <div class="flex items-center gap-3">
          <h1 class="text-2xl font-bold text-zinc-900 dark:text-white">Painel Administrativo</h1>
          <div
            v-if="lastUpdate"
            class="flex items-center gap-2 text-xs text-zinc-500 dark:text-zinc-400"
          >
            <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
            <span>Atualizado {{ formatLastUpdate(lastUpdate) }}</span>
          </div>
        </div>
        <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">
          Relatórios e estatísticas detalhadas do sistema
        </p>
      </div>

      <!-- Filtros -->
      <div class="flex flex-wrap gap-3">
        <!-- Filtro por Estado -->
        <select
          v-model="filters.state"
          @change="loadAllData"
          class="px-3 py-2 border border-zinc-300 dark:border-zinc-600 rounded-md bg-white dark:bg-zinc-700 text-zinc-700 dark:text-zinc-300 text-sm"
        >
          <option value="">Todos os estados</option>
          <option v-for="state in availableStates" :key="state" :value="state">
            {{ state }}
          </option>
        </select>

        <!-- Filtro por Status -->
        <select
          v-model="filters.status"
          @change="loadAllData"
          class="px-3 py-2 border border-zinc-300 dark:border-zinc-600 rounded-md bg-white dark:bg-zinc-700 text-zinc-700 dark:text-zinc-300 text-sm"
        >
          <option value="">Todos os status</option>
          <option value="pendente">Pendente</option>
          <option value="ativo">Ativo</option>
          <option value="aguardando_autoridade">Aguardando Autoridade</option>
          <option value="fechado">Fechado</option>
          <option value="cancelado">Cancelado</option>
        </select>

        <!-- Filtro por Período -->
        <div class="flex gap-2">
          <input
            v-model="filters.startDate"
            type="date"
            @change="loadAllData"
            class="px-3 py-2 border border-zinc-300 dark:border-zinc-600 rounded-md bg-white dark:bg-zinc-700 text-zinc-700 dark:text-zinc-300 text-sm"
            title="Data inicial"
          />
          <input
            v-model="filters.endDate"
            type="date"
            @change="loadAllData"
            class="px-3 py-2 border border-zinc-300 dark:border-zinc-600 rounded-md bg-white dark:bg-zinc-700 text-zinc-700 dark:text-zinc-300 text-sm"
            title="Data final"
          />
        </div>

        <!-- Botões de Ação -->
        <div class="flex gap-2">
          <button
            @click="loadAllData"
            :disabled="loading"
            class="inline-flex items-center px-4 py-2 border border-zinc-300 dark:border-zinc-600 text-sm font-medium rounded-md text-zinc-700 dark:text-zinc-300 bg-white dark:bg-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-colors disabled:opacity-50"
          >
            <RefreshCw class="w-4 h-4 mr-2" :class="{ 'animate-spin': loading }" />
            Atualizar
          </button>
        </div>
      </div>
    </div>

    <!-- Visão Geral do Sistema -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      <!-- Total de SOS -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-lg shadow-md p-6 border border-zinc-200 dark:border-zinc-700 hover:shadow-lg transition-shadow"
      >
        <div class="flex items-center">
          <div class="rounded-full bg-blue-100 dark:bg-blue-900/30 p-3">
            <AlertTriangle class="w-6 h-6 text-blue-600 dark:text-blue-400" />
          </div>
          <div class="ml-4">
            <p class="text-sm font-medium text-zinc-500 dark:text-zinc-400">Total de SOS</p>
            <p class="text-2xl font-bold text-zinc-900 dark:text-white">
              {{ overviewStats.totalSos }}
            </p>
          </div>
        </div>
      </div>

      <!-- SOS Fechados -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-lg shadow-md p-6 border border-zinc-200 dark:border-zinc-700 hover:shadow-lg transition-shadow"
      >
        <div class="flex items-center">
          <div class="rounded-full bg-green-100 dark:bg-green-900/30 p-3">
            <CheckCircle class="w-6 h-6 text-green-600 dark:text-green-400" />
          </div>
          <div class="ml-4">
            <p class="text-sm font-medium text-zinc-500 dark:text-zinc-400">SOS Fechados</p>
            <p class="text-2xl font-bold text-zinc-900 dark:text-white">
              {{ overviewStats.closedSos }}
            </p>
          </div>
        </div>
      </div>

      <!-- Usuários -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-lg shadow-md p-6 border border-zinc-200 dark:border-zinc-700 hover:shadow-lg transition-shadow"
      >
        <div class="flex items-center">
          <div class="rounded-full bg-yellow-100 dark:bg-yellow-900/30 p-3">
            <Users class="w-6 h-6 text-yellow-600 dark:text-yellow-400" />
          </div>
          <div class="ml-4">
            <p class="text-sm font-medium text-zinc-500 dark:text-zinc-400">Usuários</p>
            <p class="text-2xl font-bold text-zinc-900 dark:text-white">
              {{ overviewStats.totalUsers }}
            </p>
          </div>
        </div>
      </div>

      <!-- Delegacias -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-lg shadow-md p-6 border border-zinc-200 dark:border-zinc-700 hover:shadow-lg transition-shadow"
      >
        <div class="flex items-center">
          <div class="rounded-full bg-purple-100 dark:bg-purple-900/30 p-3">
            <Building class="w-6 h-6 text-purple-600 dark:text-purple-400" />
          </div>
          <div class="ml-4">
            <p class="text-sm font-medium text-zinc-500 dark:text-zinc-400">Delegacias</p>
            <p class="text-2xl font-bold text-zinc-900 dark:text-white">
              {{ overviewStats.totalDelegacias }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Indicadores de Performance -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
      <div
        class="bg-white dark:bg-zinc-800 rounded-lg shadow-md p-6 border border-zinc-200 dark:border-zinc-700"
      >
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold text-zinc-900 dark:text-white">Taxa de Resolução</h3>
          <Activity class="w-5 h-5 text-zinc-500 dark:text-zinc-400" />
        </div>
        <div class="text-3xl font-bold text-zinc-900 dark:text-white mb-2">
          {{ performanceStats.resolutionRate }}%
        </div>
        <p class="text-sm text-zinc-500 dark:text-zinc-400">de chamados fechados</p>
      </div>

      <div
        class="bg-white dark:bg-zinc-800 rounded-lg shadow-md p-6 border border-zinc-200 dark:border-zinc-700"
      >
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold text-zinc-900 dark:text-white">SOS por Delegacia</h3>
          <Star class="w-5 h-5 text-zinc-500 dark:text-zinc-400" />
        </div>
        <div class="text-3xl font-bold text-zinc-900 dark:text-white mb-2">
          {{ performanceStats.avgSosPerDelegacia }}
        </div>
        <p class="text-sm text-zinc-500 dark:text-zinc-400">chamados em média</p>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="space-y-8">
      <!-- Skeleton para cards principais -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div
          v-for="i in 4"
          :key="i"
          class="bg-white dark:bg-zinc-800 rounded-lg shadow-md p-6 border border-zinc-200 dark:border-zinc-700 animate-pulse"
        >
          <div class="flex items-center">
            <div class="rounded-full bg-zinc-200 dark:bg-zinc-700 p-3 w-12 h-12"></div>
            <div class="ml-4 flex-1">
              <div class="h-4 bg-zinc-200 dark:bg-zinc-700 rounded w-20 mb-2"></div>
              <div class="h-8 bg-zinc-200 dark:bg-zinc-700 rounded w-16"></div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Conteúdo Principal -->
    <div v-else>
      <!-- Gráficos e Estatísticas -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <!-- Gráfico de Status dos SOS -->
        <div
          class="bg-white dark:bg-zinc-800 rounded-lg shadow-md p-6 border border-zinc-200 dark:border-zinc-700"
        >
          <h2 class="text-lg font-medium text-zinc-900 dark:text-white mb-4">
            Status dos Chamados de Emergência
          </h2>
          <div class="h-80 overflow-hidden">
            <Doughnut :data="statusChartData" :options="chartOptions" />
          </div>
        </div>

        <!-- Gráfico de SOS por Mês -->
        <div
          class="bg-white dark:bg-zinc-800 rounded-lg shadow-md p-6 border border-zinc-200 dark:border-zinc-700"
        >
          <h2 class="text-lg font-medium text-zinc-900 dark:text-white mb-4">Chamados por Mês</h2>
          <div class="h-80 overflow-hidden">
            <Bar :data="monthlyChartData" :options="chartOptions" />
          </div>
        </div>
      </div>

      <!-- Novas Estatísticas -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <!-- Estatísticas de Mídia -->
        <div
          class="bg-white dark:bg-zinc-800 rounded-lg shadow-md p-6 border border-zinc-200 dark:border-zinc-700"
        >
          <h2 class="text-lg font-medium text-zinc-900 dark:text-white mb-4">
            Mídias nos Chamados de Emergência
          </h2>
          <div class="h-64 mb-4 overflow-hidden">
            <Doughnut :data="mediaTypeChartData" :options="chartOptions" />
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="bg-zinc-50 dark:bg-zinc-700/30 p-4 rounded-lg">
              <p class="text-sm text-zinc-500 dark:text-zinc-400">Total de Mídias</p>
              <p class="text-2xl font-bold text-zinc-900 dark:text-white">
                {{ mediaStatsByType.totalMedia || 0 }}
              </p>
            </div>
            <div class="bg-zinc-50 dark:bg-zinc-700/30 p-4 rounded-lg">
              <p class="text-sm text-zinc-500 dark:text-zinc-400">SOS com Mídia</p>
              <p class="text-2xl font-bold text-zinc-900 dark:text-white">
                {{ mediaStats.sosWithMedia || 0 }}
              </p>
            </div>
          </div>
        </div>

        <!-- Demografia dos Usuários -->
        <div
          class="bg-white dark:bg-zinc-800 rounded-lg shadow-md p-6 border border-zinc-200 dark:border-zinc-700"
        >
          <h2 class="text-lg font-medium text-zinc-900 dark:text-white mb-4">
            Demografia dos Usuários
          </h2>
          <div class="h-64 mb-4 overflow-hidden">
            <Doughnut :data="genderDemographicsChartData" :options="chartOptions" />
          </div>
          <div class="space-y-2">
            <h3 class="text-md font-medium text-zinc-700 dark:text-zinc-300 mb-2">Por Gênero</h3>
            <ul class="space-y-2 max-h-48 overflow-y-auto">
              <li
                v-for="(count, gender) in userDemographics.byGender"
                :key="gender"
                class="flex justify-between"
              >
                <span class="text-sm text-zinc-500 dark:text-zinc-400">{{
                  formatGender(gender)
                }}</span>
                <span class="text-sm font-medium text-zinc-900 dark:text-white">{{ count }}</span>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Estatísticas de Localização -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-lg shadow-md p-6 border border-zinc-200 dark:border-zinc-700 mb-8"
      >
        <h2 class="text-lg font-medium text-zinc-900 dark:text-white mb-4">
          Localização dos Chamados
        </h2>
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Mapa de calor por estado -->
          <div class="bg-zinc-50 dark:bg-zinc-700/30 p-4 rounded-lg">
            <h3 class="text-md font-medium text-zinc-700 dark:text-zinc-300 mb-2">
              Distribuição por Estado
            </h3>
            <div class="space-y-2 max-h-80 overflow-y-auto">
              <div
                v-for="item in locationStats.byState"
                :key="item.estado"
                class="flex items-center"
              >
                <div class="w-24 text-sm text-zinc-600 dark:text-zinc-300 truncate">
                  {{ item.estado || 'Não identificado' }}
                </div>
                <div class="flex-1 ml-2">
                  <div
                    class="h-6 rounded bg-blue-500 dark:bg-blue-600 flex items-center justify-end pr-2 text-white text-xs"
                    :style="{
                      width:
                        locationStats.byState.length > 0
                          ? (item.count / Math.max(...locationStats.byState.map((s) => s.count))) *
                              100 +
                            '%'
                          : '0%',
                    }"
                  >
                    <span v-if="item.count > 0">{{ item.count }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Estatísticas gerais de localização -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="bg-zinc-50 dark:bg-zinc-700/30 p-4 rounded-lg">
              <p class="text-sm text-zinc-500 dark:text-zinc-400">Total de SOS</p>
              <p class="text-2xl font-bold text-zinc-900 dark:text-white">
                {{ locationStats.totalSos || 0 }}
              </p>
            </div>
            <div class="bg-zinc-50 dark:bg-zinc-700/30 p-4 rounded-lg">
              <p class="text-sm text-zinc-500 dark:text-zinc-400">SOS sem localização</p>
              <p class="text-2xl font-bold text-zinc-900 dark:text-white">
                {{ locationStats.sosWithoutLocation || 0 }}
              </p>
            </div>
            <div class="bg-zinc-50 dark:bg-zinc-700/30 p-4 rounded-lg md:col-span-2">
              <p class="text-sm text-zinc-500 dark:text-zinc-400">Porcentagem sem localização</p>
              <p class="text-2xl font-bold text-zinc-900 dark:text-white">
                {{ locationStats.percentageWithoutLocation || 0 }}%
              </p>
            </div>
          </div>
        </div>

        <!-- Mapa de calor geográfico -->
        <div class="mt-6 bg-zinc-50 dark:bg-zinc-700/30 p-4 rounded-lg">
          <h3 class="text-md font-medium text-zinc-700 dark:text-zinc-300 mb-2">
            Distribuição Geográfica (Mapa de Calor)
          </h3>
          <div
            class="bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-lg h-96"
          >
            <l-map
              v-if="geographicData.length > 0"
              :zoom="mapConfig.zoom"
              :center="mapConfig.center"
              style="height: 100%; width: 100%"
              @ready="initHeatmap"
            >
              <l-tile-layer
                :url="mapConfig.url"
                :attribution="mapConfig.attribution"
              ></l-tile-layer>
            </l-map>
            <div v-else class="h-full flex items-center justify-center">
              <p class="text-zinc-500 dark:text-zinc-400">
                Nenhum dado geográfico disponível ou carregando...
              </p>
            </div>
          </div>
          <div class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
            <p>
              Este mapa mostra a distribuição geográfica dos chamados de emergência. As áreas mais
              quentes indicam uma maior concentração de chamados.
            </p>
          </div>
        </div>
      </div>

      <!-- Tabelas de Dados -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <!-- Últimos SOS -->
        <div
          class="bg-white dark:bg-zinc-800 rounded-lg shadow-md border border-zinc-200 dark:border-zinc-700"
        >
          <div class="px-6 py-4 border-b border-zinc-200 dark:border-zinc-700">
            <h2 class="text-lg font-medium text-zinc-900 dark:text-white">
              Últimos Chamados de Emergência
            </h2>
          </div>
          <div class="overflow-x-auto max-h-96 overflow-y-auto">
            <table class="min-w-full divide-y divide-zinc-200 dark:divide-zinc-700">
              <thead class="bg-zinc-50 dark:bg-zinc-700/30">
                <tr>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider"
                  >
                    ID
                  </th>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider"
                  >
                    Solicitante
                  </th>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider"
                  >
                    Status
                  </th>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider"
                  >
                    Data
                  </th>
                </tr>
              </thead>
              <tbody
                class="bg-white dark:bg-zinc-800 divide-y divide-zinc-200 dark:divide-zinc-700"
              >
                <tr
                  v-for="sos in latestSos"
                  :key="sos.id"
                  class="hover:bg-zinc-50 dark:hover:bg-zinc-700/20"
                >
                  <td
                    class="px-6 py-4 whitespace-nowrap text-sm font-medium text-zinc-900 dark:text-white"
                  >
                    #{{ sos.id }}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-500 dark:text-zinc-400">
                    {{ sos.usuario?.nome_completo || sos.nome_completo || 'Não identificado' }}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span
                      class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                      :class="getStatusClass(sos.status)"
                    >
                      {{ formatStatus(sos.status) }}
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-500 dark:text-zinc-400">
                    {{ formatDate(sos.createdAt) }}
                  </td>
                </tr>
                <tr v-if="latestSos.length === 0">
                  <td
                    colspan="4"
                    class="px-6 py-4 text-center text-sm text-zinc-500 dark:text-zinc-400"
                  >
                    Nenhum chamado registrado ({{ latestSos.length }} itens) - Filtros:
                    {{ JSON.stringify(filters) }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Delegacias com Mais SOS -->
        <div
          class="bg-white dark:bg-zinc-800 rounded-lg shadow-md border border-zinc-200 dark:border-zinc-700"
        >
          <div class="px-6 py-4 border-b border-zinc-200 dark:border-zinc-700">
            <h2 class="text-lg font-medium text-zinc-900 dark:text-white">
              Delegacias com Mais Chamados
            </h2>
          </div>
          <div class="overflow-x-auto max-h-96 overflow-y-auto">
            <table class="min-w-full divide-y divide-zinc-200 dark:divide-zinc-700">
              <thead class="bg-zinc-50 dark:bg-zinc-700/30">
                <tr>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider"
                  >
                    Delegacia
                  </th>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider"
                  >
                    Total de SOS
                  </th>
                  <th
                    scope="col"
                    class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider"
                  >
                    Último SOS
                  </th>
                </tr>
              </thead>
              <tbody
                class="bg-white dark:bg-zinc-800 divide-y divide-zinc-200 dark:divide-zinc-700"
              >
                <tr
                  v-for="delegacia in topDelegacias"
                  :key="delegacia.id"
                  class="hover:bg-zinc-50 dark:hover:bg-zinc-700/20"
                >
                  <td
                    class="px-6 py-4 whitespace-nowrap text-sm font-medium text-zinc-900 dark:text-white"
                  >
                    {{ delegacia.nome }}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-500 dark:text-zinc-400">
                    {{ delegacia.sosCount }}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-500 dark:text-zinc-400">
                    {{ formatDate(delegacia.lastSos) }}
                  </td>
                </tr>
                <tr v-if="topDelegacias.length === 0">
                  <td
                    colspan="3"
                    class="px-6 py-4 text-center text-sm text-zinc-500 dark:text-zinc-400"
                  >
                    Nenhuma delegacia registrada
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Estatísticas Detalhadas -->
      <div
        class="bg-white dark:bg-zinc-800 rounded-lg shadow-md p-6 border border-zinc-200 dark:border-zinc-700 mb-8"
      >
        <h2 class="text-lg font-medium text-zinc-900 dark:text-white mb-4">
          Estatísticas Detalhadas
        </h2>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <h3 class="text-md font-medium text-zinc-700 dark:text-zinc-300 mb-2">Por Status</h3>
            <ul class="space-y-2 max-h-48 overflow-y-auto">
              <li
                v-for="(count, status) in detailedStats.byStatus"
                :key="status"
                class="flex justify-between"
              >
                <span class="text-sm text-zinc-500 dark:text-zinc-400">{{
                  formatStatus(status)
                }}</span>
                <span class="text-sm font-medium text-zinc-900 dark:text-white">{{ count }}</span>
              </li>
            </ul>
          </div>

          <div>
            <h3 class="text-md font-medium text-zinc-700 dark:text-zinc-300 mb-2">Por Período</h3>
            <ul class="space-y-2 max-h-48 overflow-y-auto">
              <li class="flex justify-between">
                <span class="text-sm text-zinc-500 dark:text-zinc-400">Últimas 24h</span>
                <span class="text-sm font-medium text-zinc-900 dark:text-white">{{
                  detailedStats.last24h
                }}</span>
              </li>
              <li class="flex justify-between">
                <span class="text-sm text-zinc-500 dark:text-zinc-400">Últimos 7 dias</span>
                <span class="text-sm font-medium text-zinc-900 dark:text-white">{{
                  detailedStats.last7Days
                }}</span>
              </li>
              <li class="flex justify-between">
                <span class="text-sm text-zinc-500 dark:text-zinc-400">Últimos 30 dias</span>
                <span class="text-sm font-medium text-zinc-900 dark:text-white">{{
                  detailedStats.last30Days
                }}</span>
              </li>
            </ul>
          </div>

          <div>
            <h3 class="text-md font-medium text-zinc-700 dark:text-zinc-300 mb-2">Usuários</h3>
            <ul class="space-y-2 max-h-48 overflow-y-auto">
              <li class="flex justify-between">
                <span class="text-sm text-zinc-500 dark:text-zinc-400">Total</span>
                <span class="text-sm font-medium text-zinc-900 dark:text-white">{{
                  detailedStats.totalUsers
                }}</span>
              </li>
              <li class="flex justify-between">
                <span class="text-sm text-zinc-500 dark:text-zinc-400">Ativos</span>
                <span class="text-sm font-medium text-zinc-900 dark:text-white">{{
                  detailedStats.activeUsers
                }}</span>
              </li>
              <li class="flex justify-between">
                <span class="text-sm text-zinc-500 dark:text-zinc-400">Novos (7 dias)</span>
                <span class="text-sm font-medium text-zinc-900 dark:text-white">{{
                  detailedStats.newUsers7Days
                }}</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, reactive } from 'vue'
import {
  RefreshCw,
  AlertTriangle,
  CheckCircle,
  Users,
  Building,
  Activity,
  Star,
} from 'lucide-vue-next'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
} from 'chart.js'
import { Bar, Doughnut } from 'vue-chartjs'
import { LMap, LTileLayer } from '@vue-leaflet/vue-leaflet'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import 'leaflet.heat'

import {
  getSystemOverview,
  getSosStats,
  getUserStats,
  getTopDelegacias,
  getMonthlyStats,
  getMediaStats,
  getUserDemographics,
  getSosLocationStats,
  getSosGeographicDistribution,
  getMediaStatsByType,
} from '@/services/http'
import { useToastStore } from '@/stores/toast'

// Registro de componentes externos
ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend, ArcElement)

// Funções de formatação
function useFormatters() {
  const formatStatus = (status) => {
    const statusMap = {
      pendente: 'Pendente',
      ativo: 'Ativo',
      aguardando_autoridade: 'Aguardando Autoridade',
      fechado: 'Fechado',
      cancelado: 'Cancelado',
    }
    return statusMap[status] || status
  }

  const getStatusClass = (status) => {
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

  const formatDate = (dateString) => {
    if (!dateString) return 'Não informado'
    return new Date(dateString).toLocaleString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  const formatMediaType = (type) => ({ video: 'Vídeo', audio: 'Áudio', foto: 'Foto' })[type] || type

  const formatGender = (gender) => {
    if (!gender) return 'Não informado'
    return { Feminino: 'Feminino', Nao_Binario: 'Não Binário', Outro: 'Outro' }[gender] || gender
  }

  return { formatStatus, getStatusClass, formatDate, formatMediaType, formatGender }
}

// Gerenciamento de dados da API
const useDashboardData = (toast) => {
  const loading = ref(false)
  const filters = reactive({
    state: '',
    status: '',
    startDate: '',
    endDate: '',
  })
  const overviewStats = ref({ totalSos: 0, closedSos: 0, totalUsers: 0, totalDelegacias: 0 })
  const latestSos = ref([])
  const topDelegacias = ref([])
  const monthlyStats = ref([])
  const mediaStats = ref({})
  const mediaStatsByType = ref({})
  const userDemographics = ref({})
  const locationStats = ref({})
  const geographicData = ref([])
  const detailedStats = ref({
    byStatus: {},
    last24h: 0,
    last7Days: 0,
    last30Days: 0,
    totalUsers: 0,
    activeUsers: 0,
    newUsers7Days: 0,
  })
  const responseStats = ref({
    avgResponseTime: 0,
    medianResponseTime: 0,
    totalClosedSos: 0,
  })
  const performanceStats = ref({
    resolutionRate: 0,
    avgSosPerDelegacia: 0,
  })
  const lastUpdate = ref(null)

  // availableStates agora é computed
  const availableStates = computed(() => {
    if (!locationStats.value.byState) return []
    return [...new Set(locationStats.value.byState.map((item) => item.estado).filter(Boolean))]
  })

  const loadAllData = async () => {
    loading.value = true
    try {
      // Log dos filtros atuais
      console.log('Filtros atuais:', filters)

      const params = {
        ...(filters.state && { state: filters.state }),
        ...(filters.status && { status: filters.status }),
        ...(filters.startDate && { startDate: filters.startDate }),
        ...(filters.endDate && { endDate: filters.endDate }),
      }

      // Log dos parâmetros que serão enviados para a API
      console.log('Parâmetros enviados para a API:', params)

      const [
        overviewRes,
        sosStatsRes,
        userStatsRes,
        topDelegaciasRes,
        monthlyStatsRes,
        mediaStatsRes,
        userDemographicsRes,
        locationStatsRes,
        geographicDataRes,
        mediaStatsByTypeRes,
      ] = await Promise.allSettled([
        getSystemOverview(),
        getSosStats(params),
        getUserStats(params),
        getTopDelegacias(params),
        getMonthlyStats(params),
        getMediaStats(params),
        getUserDemographics(params),
        getSosLocationStats(params),
        getSosGeographicDistribution(params),
        getMediaStatsByType(params),
      ])

      // Verificar se alguma chamada falhou
      const results = [
        overviewRes,
        sosStatsRes,
        userStatsRes,
        topDelegaciasRes,
        monthlyStatsRes,
        mediaStatsRes,
        userDemographicsRes,
        locationStatsRes,
        geographicDataRes,
        mediaStatsByTypeRes,
      ]

      results.forEach((result, index) => {
        if (result.status === 'rejected') {
          console.error(`Erro na chamada ${index}:`, result.reason)
        }
      })

      // Extrair dados das respostas bem-sucedidas
      const [
        overviewData,
        sosStatsData,
        userStatsData,
        topDelegaciasData,
        monthlyStatsData,
        mediaStatsData,
        userDemographicsData,
        locationStatsData,
        geographicDataData,
        mediaStatsByTypeData,
      ] = results.map((result) => (result.status === 'fulfilled' ? result.value : { data: null }))

      latestSos.value = sosStatsData?.data?.sosData || []
      console.log('Latest SOS após atribuição:', latestSos.value)
      console.log('Latest SOS length após atribuição:', latestSos.value.length)

      // Verificar se há dados e qual a estrutura
      if (latestSos.value.length > 0) {
        console.log('Primeiro item:', latestSos.value[0])
      }

      overviewStats.value = overviewData?.data || {
        totalSos: 0,
        closedSos: 0,
        totalUsers: 0,
        totalDelegacias: 0,
      }
      console.log('Latest SOS:', latestSos.value)
      console.log('Latest SOS length:', latestSos.value.length)
      detailedStats.value = {
        byStatus: sosStatsData?.data?.byStatus || {},
        last24h: sosStatsData?.data?.last24h || 0,
        last7Days: sosStatsData?.data?.last7Days || 0,
        last30Days: sosStatsData?.data?.last30Days || 0,
        totalUsers: userStatsData?.data?.totalUsers || 0,
        activeUsers: userStatsData?.data?.activeUsers || 0,
        newUsers7Days: userStatsData?.data?.newUsers7Days || 0,
      }
      topDelegacias.value = topDelegaciasData?.data || []
      monthlyStats.value = monthlyStatsData?.data || []
      mediaStats.value = mediaStatsData?.data || {}
      userDemographics.value = userDemographicsData?.data || {}
      locationStats.value = locationStatsData?.data || {}
      geographicData.value = geographicDataData?.data || []
      mediaStatsByType.value = mediaStatsByTypeData?.data || {}

      // Calcular indicadores de performance
      calculatePerformanceStats()

      // Atualizar timestamp da última atualização
      lastUpdate.value = new Date()
    } catch (error) {
      console.error('Erro ao carregar dados do painel:', error)
      toast.error('Erro ao carregar dados do painel')
    } finally {
      loading.value = false
    }
  }

  const calculatePerformanceStats = () => {
    // Taxa de resolução
    const totalSos = overviewStats.value.totalSos
    const closedSos = overviewStats.value.closedSos
    performanceStats.value.resolutionRate =
      totalSos > 0 ? Math.round((closedSos / totalSos) * 100) : 0

    // SOS por delegacia
    const totalDelegacias = overviewStats.value.totalDelegacias
    performanceStats.value.avgSosPerDelegacia =
      totalDelegacias > 0 ? Math.round(totalSos / totalDelegacias) : 0
  }

  const initHeatmap = (mapInstance) => {
    if (!mapInstance) return
    if (geographicData.value?.length > 0) {
      const heatmapData = geographicData.value.map((p) => [p.latitude, p.longitude, 1])
      L.heatLayer(heatmapData, { radius: 25, blur: 15, maxZoom: 10 }).addTo(mapInstance)
    }
  }

  const formatLastUpdate = (date) => {
    if (!date) return ''
    const now = new Date()
    const diff = Math.floor((now - date) / 1000)

    if (diff < 60) return 'agora mesmo'
    if (diff < 3600) return `há ${Math.floor(diff / 60)} min`
    if (diff < 86400) return `há ${Math.floor(diff / 3600)}h`
    return date.toLocaleString('pt-BR', {
      day: '2-digit',
      month: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  return {
    loading,
    filters,
    availableStates,
    overviewStats,
    latestSos,
    topDelegacias,
    monthlyStats,
    mediaStats,
    mediaStatsByType,
    userDemographics,
    locationStats,
    geographicData,
    detailedStats,
    responseStats,
    performanceStats,
    lastUpdate,
    loadAllData,
    initHeatmap,
    formatLastUpdate,
  }
}

// Gerenciamento dos gráficos
const useCharts = (data, formatters) => {
  const { detailedStats, monthlyStats, mediaStatsByType, userDemographics } = data
  const { formatStatus, formatMediaType, formatGender } = formatters

  const chartOptions = reactive({
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { position: 'top' } },
  })

  const statusChartData = computed(() => ({
    labels: Object.keys(detailedStats.value.byStatus || {}).map(formatStatus),
    datasets: [
      {
        data: Object.values(detailedStats.value.byStatus || {}),
        backgroundColor: ['#f59e0b', '#3b82f6', '#8b5cf6', '#10b981', '#ef4444'],
      },
    ],
  }))

  const monthlyChartData = computed(() => ({
    labels: monthlyStats.value?.map((item) => item.month) || [],
    datasets: [
      {
        label: 'Chamados',
        data: monthlyStats.value?.map((item) => item.count) || [],
        backgroundColor: '#4f46e5',
      },
    ],
  }))

  const mediaTypeChartData = computed(() => ({
    labels: Object.keys(mediaStatsByType.value.byType || {}).map(formatMediaType),
    datasets: [
      {
        data: Object.values(mediaStatsByType.value.byType || {}),
        backgroundColor: ['#3b82f6', '#10b981', '#8b5cf6'],
      },
    ],
  }))

  const genderDemographicsChartData = computed(() => ({
    labels: Object.keys(userDemographics.value.byGender || {}).map(formatGender),
    datasets: [
      {
        data: Object.values(userDemographics.value.byGender || {}),
        backgroundColor: ['#f59e0b', '#8b5cf6', '#3b82f6'],
      },
    ],
  }))

  return {
    chartOptions,
    statusChartData,
    monthlyChartData,
    mediaTypeChartData,
    genderDemographicsChartData,
  }
}

// Inicialização do script setup
const toast = useToastStore()
const { formatStatus, getStatusClass, formatDate, formatMediaType, formatGender } = useFormatters()

const {
  loading,
  filters,
  availableStates,
  overviewStats,
  latestSos,
  topDelegacias,
  monthlyStats,
  mediaStats,
  mediaStatsByType,
  userDemographics,
  locationStats,
  geographicData,
  detailedStats,
  performanceStats,
  lastUpdate,
  loadAllData,
  initHeatmap,
  formatLastUpdate,
} = useDashboardData(toast)

const {
  chartOptions,
  statusChartData,
  monthlyChartData,
  mediaTypeChartData,
  genderDemographicsChartData,
} = useCharts(
  { detailedStats, monthlyStats, mediaStatsByType, userDemographics },
  { formatStatus, formatMediaType, formatGender },
)

const mapConfig = {
  center: [-14.235, -51.9253],
  zoom: 4,
  url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
  attribution:
    '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
}

// Hooks de ciclo de vida
onMounted(loadAllData)
</script>
