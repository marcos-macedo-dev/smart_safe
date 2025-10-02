<template>
  <transition name="slide-down" appear>
    <div
      v-if="show"
      class="fixed inset-0 z-50 flex items-start justify-center pt-6 pb-4 px-4 bg-black/40 dark:bg-black/60 backdrop-blur-sm"
      role="dialog"
      aria-modal="true"
      aria-labelledby="manual-title"
      @keydown.esc="$emit('close')"
    >
      <div
        ref="modalContainer"
        class="bg-white dark:bg-zinc-900 w-full max-w-6xl h-[92vh] rounded-2xl shadow-2xl overflow-hidden flex flex-col border border-zinc-200 dark:border-zinc-800 transition-all duration-300"
        tabindex="-1"
      >
        <!-- Header -->
        <div
          class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 p-5 border-b border-zinc-100 dark:border-zinc-800 bg-white/80 dark:bg-zinc-900/80 backdrop-blur-sm"
        >
          <div class="flex items-center gap-3">
            <div class="bg-indigo-100 dark:bg-indigo-900/30 p-2 rounded-lg">
              <BookOpen class="w-6 h-6 text-indigo-600 dark:text-indigo-400" />
            </div>
            <div>
              <h1 id="manual-title" class="text-xl font-bold text-zinc-900 dark:text-white">
                Manual do Sistema
              </h1>
              <p class="text-sm text-zinc-500 dark:text-zinc-400">Guia completo de utilização</p>
            </div>
          </div>

          <!-- Search Bar -->
          <div class="relative w-full sm:w-72">
            <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
              <Search class="w-4 h-4 text-zinc-400" />
            </div>
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Pesquisar no manual..."
              class="w-full pl-10 pr-10 py-2.5 text-sm rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 text-zinc-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all"
              aria-label="Pesquisar no manual"
            />
            <button
              v-if="searchQuery"
              @click="clearSearch"
              class="absolute inset-y-0 right-0 flex items-center pr-3 text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-300"
              aria-label="Limpar pesquisa"
            >
              <X class="w-4 h-4" />
            </button>
          </div>

          <button
            @click="$emit('close')"
            class="p-2.5 rounded-lg hover:bg-zinc-100 dark:hover:bg-zinc-800 text-zinc-500 hover:text-zinc-900 dark:hover:text-white transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:focus:ring-offset-zinc-900"
            aria-label="Fechar manual"
          >
            <X class="w-5 h-5" />
          </button>
        </div>

        <div class="flex flex-1 overflow-hidden">
          <!-- Sidebar -->
          <nav
            v-if="!searchQuery"
            class="w-52 min-w-48 border-r border-zinc-100 dark:border-zinc-800 bg-zinc-50/50 dark:bg-zinc-800/20 overflow-y-auto hidden lg:block transition-colors duration-300"
            aria-label="Seções do manual"
          >
            <div class="py-3 px-2">
              <ul class="space-y-1">
                <li v-for="section in sections" :key="section.id">
                  <a
                    :href="`#${section.id}`"
                    :class="[
                      'flex items-center gap-3 px-3 py-2.5 text-sm rounded-lg transition-all duration-200',
                      'text-zinc-600 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-white',
                      'hover:bg-zinc-100 dark:hover:bg-zinc-800',
                      'focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-inset',
                      currentSection === section.id
                        ? 'bg-indigo-50 dark:bg-indigo-900/20 text-indigo-700 dark:text-indigo-300 shadow-inner'
                        : '',
                    ]"
                    :aria-current="currentSection === section.id ? 'true' : 'false'"
                    @click="scrollToSection(section.id)"
                  >
                    <component :is="section.icon" class="w-4 h-4 flex-shrink-0" />
                    <span class="truncate font-medium">{{ section.title }}</span>
                  </a>
                </li>
              </ul>
            </div>
          </nav>

          <!-- Content -->
          <div ref="contentContainer" class="flex-1 overflow-y-auto transition-colors duration-300">
            <!-- Search Results -->
            <div v-if="searchQuery" class="p-5">
              <h2 class="text-lg font-semibold text-zinc-900 dark:text-white mb-5">
                Resultados para "{{ searchQuery }}"
                <span class="text-sm font-normal text-zinc-500"
                  >({{ filteredResults.length }} resultados)</span
                >
              </h2>

              <div v-if="filteredResults.length > 0" class="space-y-4">
                <div
                  v-for="result in filteredResults"
                  :key="result.id"
                  class="p-5 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 cursor-pointer transition-all duration-200 hover:shadow-md"
                  @click="navigateToResult(result)"
                >
                  <div class="flex items-start gap-4">
                    <div class="bg-indigo-100 dark:bg-indigo-900/30 p-2 rounded-lg flex-shrink-0">
                      <component
                        :is="getIconForSection(result.sectionId)"
                        class="w-5 h-5 text-indigo-600 dark:text-indigo-400"
                      />
                    </div>
                    <div class="flex-1">
                      <h3 class="font-semibold text-zinc-900 dark:text-white">
                        {{ result.title }}
                      </h3>
                      <p class="text-sm text-zinc-600 dark:text-zinc-400 mt-2 line-clamp-2">
                        {{ result.content }}
                      </p>
                      <div
                        class="text-xs text-zinc-500 dark:text-zinc-400 mt-3 flex items-center gap-1"
                      >
                        <FolderOpen class="w-3 h-3" />
                        Em: {{ getSectionTitle(result.sectionId) }}
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div v-else class="text-center py-16">
                <div
                  class="bg-zinc-100 dark:bg-zinc-800 p-4 rounded-full w-16 h-16 flex items-center justify-center mx-auto mb-5"
                >
                  <SearchX class="w-8 h-8 text-zinc-400 dark:text-zinc-500" />
                </div>
                <h3 class="text-lg font-semibold text-zinc-900 dark:text-white mb-2">
                  Nenhum resultado encontrado
                </h3>
                <p class="text-zinc-500 dark:text-zinc-400 max-w-md mx-auto">
                  Tente usar termos diferentes na pesquisa ou verifique a ortografia.
                </p>
              </div>
            </div>

            <!-- Regular Content -->
            <div v-else class="p-6 max-w-3xl mx-auto">
              <div
                v-for="section in sections"
                :key="section.id"
                :id="section.id"
                class="mb-12 scroll-mt-24"
              >
                <div class="flex items-center gap-3 mb-4">
                  <div class="bg-indigo-100 dark:bg-indigo-900/30 p-2 rounded-lg">
                    <component
                      :is="section.icon"
                      class="w-5 h-5 text-indigo-600 dark:text-indigo-400"
                    />
                  </div>
                  <h2 class="text-2xl font-bold text-zinc-900 dark:text-white">
                    {{ section.title }}
                  </h2>
                </div>

                <div class="space-y-4 text-zinc-600 dark:text-zinc-300 text-base leading-relaxed">
                  <p v-for="(paragraph, index) in section.content" :key="index" class="mb-3">
                    {{ paragraph }}
                  </p>

                  <ul v-if="section.list" class="list-disc pl-6 space-y-2 mt-3">
                    <li v-for="(item, index) in section.list" :key="index" class="pl-2">
                      {{ item }}
                    </li>
                  </ul>

                  <div
                    v-if="section.tips"
                    class="mt-5 p-5 bg-blue-50 dark:bg-blue-900/20 rounded-xl border border-blue-200 dark:border-blue-800"
                  >
                    <h3
                      class="font-semibold text-blue-800 dark:text-blue-200 flex items-center gap-2 mb-3"
                    >
                      <Lightbulb class="w-5 h-5" />
                      Dica
                    </h3>
                    <ul class="list-disc pl-6 space-y-2 text-blue-700 dark:text-blue-300">
                      <li v-for="(tip, index) in section.tips" :key="index" class="pl-2">
                        {{ tip }}
                      </li>
                    </ul>
                  </div>

                  <div
                    v-if="section.links"
                    class="mt-5 p-5 bg-green-50 dark:bg-green-900/20 rounded-xl border border-green-200 dark:border-green-800"
                  >
                    <h3
                      class="font-semibold text-green-800 dark:text-green-200 flex items-center gap-2 mb-3"
                    >
                      <Link class="w-5 h-5" />
                      Seções Relacionadas
                    </h3>
                    <div class="flex flex-wrap gap-2">
                      <a
                        v-for="(link, index) in section.links"
                        :key="index"
                        :href="`#${link.id}`"
                        @click="scrollToSection(link.id)"
                        class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-green-700 dark:text-green-300 bg-green-100 dark:bg-green-800/30 rounded-lg hover:bg-green-200 dark:hover:bg-green-800/50 transition-colors"
                      >
                        <component :is="getIconForSection(link.id)" class="w-3.5 h-3.5" />
                        {{ link.title }}
                      </a>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Footer with Progress -->
        <div
          v-if="!searchQuery"
          class="px-5 py-4 border-t border-zinc-100 dark:border-zinc-800 bg-white/80 dark:bg-zinc-900/80 backdrop-blur-sm text-xs text-zinc-500 dark:text-zinc-400 flex justify-between items-center"
        >
          <div class="flex items-center gap-2">
            <span v-if="currentSection" class="font-medium">
              Visualizando: {{ getSectionTitle(currentSection) }}
            </span>
          </div>
          <div class="flex items-center gap-3">
            <span class="font-medium">{{ Math.round(scrollProgress * 100) }}% completo</span>
            <div class="w-32 h-2 bg-zinc-200 dark:bg-zinc-700 rounded-full overflow-hidden">
              <div
                class="h-full bg-indigo-500 rounded-full transition-all duration-500 ease-out"
                :style="{ width: `${scrollProgress * 100}%` }"
              ></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch } from 'vue'
import {
  BookOpen,
  Navigation,
  Lightbulb,
  LifeBuoy,
  Bell,
  Map,
  Users,
  User,
  Lock,
  BarChart3,
  Eye,
  X,
  Search,
  SearchX,
  Link,
  Zap,
  AlertTriangle,
  FolderOpen,
  Shield,
  Building,
} from 'lucide-vue-next'

const props = defineProps({
  show: Boolean,
})

const emit = defineEmits(['close'])

const currentSection = ref('overview')
const scrollProgress = ref(0)
const searchQuery = ref('')
const modalContainer = ref(null)
const contentContainer = ref(null)

const sections = [
  {
    id: 'getting-started',
    title: 'Primeiros Passos',
    icon: Zap,
    content: [
      'Bem-vindo ao Smart Safe! Este guia rápido ajudará você a começar a usar o sistema efetivamente.',
      'O Smart Safe é um sistema de gestão de emergências que permite o monitoramento e resposta rápida a chamados de socorro.',
    ],
    list: [
      'Faça login com suas credenciais fornecidas',
      'Explore o dashboard para entender a visão geral do sistema',
      'Verifique as notificações para chamados urgentes',
      'Atualize seu perfil com informações de contato',
      'Familiarize-se com o menu de navegação lateral',
    ],
    tips: [
      'Mantenha seu perfil atualizado para receber notificações corretamente',
      'Explore todas as seções do menu para entender as funcionalidades disponíveis',
      'Utilize a barra de pesquisa deste manual para encontrar informações rapidamente',
    ],
    links: [
      { id: 'authentication', title: 'Autenticação' },
      { id: 'dashboard', title: 'Dashboard' },
      { id: 'navigation', title: 'Navegação' },
    ],
  },
  {
    id: 'authentication',
    title: 'Autenticação',
    icon: Lock,
    content: [
      'O sistema possui diferentes fluxos de autenticação para diferentes tipos de usuários:',
    ],
    list: [
      'Login: Tela inicial onde autoridades e operadores fazem login com email e senha',
      'Registro de Delegacia: Solicitação de registro de novas delegacias com dados da instituição e administrador',
      'Aceitar Convite: Tela para aceitação de convites enviados por email para novos usuários',
      'Recuperação de Senha: Fluxos separados para autoridades e usuários comuns',
      'Redefinição de Senha: Tela para definir nova senha após solicitação de recuperação',
    ],
    tips: [
      'Utilize senhas fortes com pelo menos 6 caracteres',
      'Mantenha seus dados de acesso em local seguro',
      'Solicite recuperação de senha caso esqueça sua credencial',
    ],
    links: [
      { id: 'getting-started', title: 'Primeiros Passos' },
      { id: 'profile', title: 'Meu Perfil' },
    ],
  },
  {
    id: 'navigation',
    title: 'Navegação',
    icon: Navigation,
    content: [
      'A navegação principal se dá através do menu lateral esquerdo, que contém os principais módulos do sistema:',
    ],
    list: [
      'Dashboard: Visão geral dos indicadores e estatísticas (Admin e Operador)',
      'Mapa: Visualização geográfica das delegacias (Admin e Operador)',
      'SOS: Listagem e detalhamento dos chamados de emergência (Admin e Operador)',
      'Usuários: Gerenciamento de operadores e administradores (apenas Admin)',
      'Relatórios: Estatísticas detalhadas e gráficos (apenas Admin)',
      'Perfil: Configurações pessoais e de segurança (Admin e Operador)',
    ],
    tips: [
      'Os itens do menu são organizados por frequência de uso',
      'Ícones ajudam a identificar rapidamente cada seção',
    ],
    links: [
      { id: 'dashboard', title: 'Dashboard' },
      { id: 'sos', title: 'Chamados SOS' },
      { id: 'users', title: 'Usuários' },
    ],
  },
  {
    id: 'dashboard',
    title: 'Dashboard',
    icon: BarChart3,
    content: [
      'A tela principal do sistema com visão geral das estatísticas e atividades recentes:',
    ],
    list: [
      'Estatísticas principais (operadores, delegacias, SOS, taxa de resolução)',
      'Gráfico de barras: SOS nos últimos 7 dias',
      'Gráfico de rosca: Status dos SOS (pendentes, ativos, aguardando, fechados, cancelados)',
      'Gráfico de área: Tendência por hora nas últimas 24 horas',
      'Gráfico de linha: SOS por semana do mês selecionado',
      'Tabela de atividades recentes',
      'Carregamento de dados em tempo real',
      'Seleção de período para visualização de dados',
    ],
    tips: [
      'Use o dashboard para monitorar o desempenho geral do sistema',
      'Identifique padrões de ocorrência através dos gráficos',
      'Acompanhe as atividades recentes para manter-se atualizado',
    ],
    links: [
      { id: 'reports', title: 'Relatórios' },
      { id: 'sos', title: 'Chamados SOS' },
    ],
  },
  {
    id: 'sos',
    title: 'Chamados de Emergência (SOS)',
    icon: Bell,
    content: ['Gerenciamento completo dos chamados de emergência recebidos:'],
    list: [
      'Listagem de todos os chamados SOS com filtros por status e busca textual',
      'Paginação de resultados para melhor navegação',
      'Exibição de estatísticas por status dos chamados',
      'Visualização detalhada de cada chamado com todas as informações',
      'Atualização em tempo real via WebSocket',
      'Notificações de novos chamados recebidos',
    ],
    tips: [
      'Utilize os filtros para encontrar chamados específicos rapidamente',
      'Mantenha-se atento às notificações de novos chamados',
      'Acompanhe o status dos chamados para garantir resolução adequada',
    ],
    links: [
      { id: 'sos-details', title: 'Detalhes do Chamado' },
      { id: 'tracking', title: 'Rastreamento' },
    ],
  },
  {
    id: 'sos-details',
    title: 'Detalhes do Chamado SOS',
    icon: Eye,
    content: ['Tela com informações detalhadas de um chamado SOS específico:'],
    list: [
      'Exibição completa das informações do solicitante',
      'Visualização do status atual e histórico de alterações',
      'Reprodução de mídias enviadas (áudio e vídeo)',
      'Mapa com localização exata do chamado',
      'Rota otimizada da delegacia até o local do chamado',
      'Atualização de status do chamado',
      'Rastreamento em tempo real via WebSocket',
      'Funções de cópia de coordenadas e abertura no Google Maps',
    ],
    tips: [
      'Verifique todas as informações do solicitante antes de atender',
      'Utilize o mapa para entender melhor a localização do chamado',
      'Atualize o status do chamado para manter o controle adequado',
    ],
    links: [
      { id: 'sos', title: 'Chamados SOS' },
      { id: 'tracking', title: 'Rastreamento' },
      { id: 'map', title: 'Mapa' },
    ],
  },
  {
    id: 'tracking',
    title: 'Rastreamento de Apuros',
    icon: Navigation,
    content: ['Visualização do rastreamento de apuros em tempo real:'],
    list: [
      'Mapa com histórico de pontos de rastreamento em tempo real',
      'Lista de pontos com data/hora e coordenadas',
      'Informações de precisão e nível de bateria',
      'Atualização automática via WebSocket',
      'Exibição de popups com informações detalhadas nos marcadores do mapa',
    ],
    tips: [
      'Acompanhe o rastreamento em tempo real para responder mais rapidamente',
      'Verifique o nível de bateria para planejar a resposta adequada',
      'Utilize o histórico de pontos para entender o trajeto da vítima',
    ],
    links: [
      { id: 'sos-details', title: 'Detalhes do Chamado' },
      { id: 'map', title: 'Mapa' },
    ],
  },
  {
    id: 'users',
    title: 'Gerenciamento de Operadores',
    icon: Users,
    content: ['Gerenciamento completo dos operadores da delegacia:'],
    list: [
      'Listagem de todos os operadores com filtros por status e cargo',
      'Busca textual para encontrar operadores específicos',
      'Paginação de resultados para melhor navegação',
      'Adição de novos operadores através de envio de convite por email',
      'Edição de informações pessoais dos operadores',
      'Ativação/desativação de operadores',
      'Exclusão de operadores com confirmação de segurança',
      'Modais para adicionar/editar operadores',
    ],
    tips: [
      'Mantenha os dados dos operadores sempre atualizados',
      'Utilize cargos diferentes para definir níveis de acesso',
      'Desative operadores que não estão mais ativos na instituição',
    ],
    links: [
      { id: 'profile', title: 'Meu Perfil' },
      { id: 'authentication', title: 'Autenticação' },
    ],
  },
  {
    id: 'profile',
    title: 'Meu Perfil',
    icon: User,
    content: ['Gerenciamento de perfil pessoal com diferenças entre autoridades e operadores:'],
    list: [
      'Visualização/edição de informações pessoais',
      'Para autoridades: Exibição de informações da delegacia (somente leitura) e link para alteração de senha dedicada',
      'Para operadores: Funcionalidade de alteração de senha integrada',
      'Cancelamento de alterações não salvas',
      'Salvamento de alterações com validação',
    ],
    tips: [
      'Mantenha seus dados pessoais atualizados',
      'Utilize uma foto de perfil para facilitar o reconhecimento',
      'Altere sua senha regularmente para manter a segurança',
    ],
    links: [
      { id: 'users', title: 'Usuários' },
      { id: 'authentication', title: 'Autenticação' },
    ],
  },
  {
    id: 'reports',
    title: 'Painel Administrativo',
    icon: BarChart3,
    content: ['Relatórios e estatísticas detalhadas do sistema:'],
    list: [
      'Visão geral do sistema (total de SOS, fechados, usuários, delegacias)',
      'Gráficos de status dos SOS e distribuição por período',
      'Tabela de últimos SOS registrados',
      'Tabela de delegacias com maior número de SOS',
      'Estatísticas detalhadas por status, período e usuários',
      'Estatísticas de mídia nos chamados',
      'Demografia dos usuários cadastrados',
      'Localização geográfica dos chamados',
      'Mapa de calor geográfico com distribuição de ocorrências',
      'Filtros por estado para análise regional',
    ],
    tips: [
      'Utilize os relatórios para identificar padrões e melhorar o atendimento',
      'Compare dados de diferentes períodos para medir desempenho',
      'Exporte informações importantes para relatórios externos',
    ],
    links: [
      { id: 'dashboard', title: 'Dashboard' },
      { id: 'sos', title: 'Chamados SOS' },
    ],
  },
  {
    id: 'map',
    title: 'Visualização de Mapa',
    icon: Map,
    content: ['Visualização geográfica completa com todas as delegacias registradas:'],
    list: [
      'Mapa com marcadores de todas as delegacias cadastradas',
      'Informações detalhadas das delegacias em popups (nome, endereço, telefone)',
      'Zoom automático para mostrar todas as delegacias',
      'Tratamento de erros de carregamento com fallback',
      'Interface intuitiva para navegação geográfica',
      'Carregamento assíncrono das delegacias via API',
    ],
    tips: [
      'Utilize o mapa para entender a distribuição geográfica das delegacias',
      'Identifique regiões com maior concentração de ocorrências',
      'Verifique a localização das delegacias para planejamento estratégico',
    ],
    links: [
      { id: 'sos-details', title: 'Detalhes do Chamado' },
      { id: 'tracking', title: 'Rastreamento' },
    ],
  },
  {
    id: 'troubleshooting',
    title: 'Solução de Problemas',
    icon: AlertTriangle,
    content: ['Soluções para problemas comuns que você pode encontrar no sistema:'],
    list: [
      'Problemas de login: Verifique suas credenciais e conexão com a internet',
      'Mapa não carrega: Verifique permissões de localização e conexão com a internet',
      'Notificações não chegam: Verifique configurações de notificação do navegador',
      'Lentidão no sistema: Limpe o cache do navegador e feche outras abas',
      'Erros ao salvar dados: Verifique sua conexão e tente novamente',
      'Vídeos não reproduzem: Verifique codecs de vídeo suportados pelo navegador',
    ],
    tips: [
      'Mantenha seu navegador atualizado para melhor compatibilidade',
      'Limpe o cache regularmente para evitar problemas de desempenho',
      'Verifique permissões do navegador para funcionalidades como localização',
    ],
    links: [
      { id: 'support', title: 'Suporte' },
      { id: 'authentication', title: 'Autenticação' },
    ],
  },
  {
    id: 'authentication',
    title: 'Sistema de Autenticação',
    icon: Shield,
    content: ['Sistema de autenticação robusto com diferentes níveis de acesso:'],
    list: [
      'Login com email e senha para autoridades',
      'Sistema de convites por email para novos operadores',
      'Recuperação de senha via email com token seguro',
      'Diferentes níveis de acesso: Admin e Operador',
      'Sessões seguras com tokens JWT',
      'Redirecionamento automático baseado no tipo de usuário',
      'Proteção de rotas sensíveis',
      'Logout seguro com limpeza de dados',
    ],
    tips: [
      'Mantenha suas credenciais seguras e não as compartilhe',
      'Use senhas fortes e as altere regularmente',
      'Faça logout sempre que terminar de usar o sistema',
    ],
    links: [
      { id: 'profile', title: 'Meu Perfil' },
      { id: 'users', title: 'Usuários' },
    ],
  },
  {
    id: 'delegacia-management',
    title: 'Gestão de Delegacias',
    icon: Building,
    content: ['Sistema completo para registro e aprovação de delegacias:'],
    list: [
      'Registro de novas delegacias com dados completos',
      'Sistema de aprovação por administradores',
      'Rejeição de registros com justificativa',
      'Visualização de delegacias pendentes de aprovação',
      'Dados geográficos precisos (latitude/longitude)',
      'Informações de contato e endereço',
      'Status de ativação das delegacias',
    ],
    tips: [
      'Verifique todos os dados antes de aprovar uma delegacia',
      'Mantenha as informações geográficas atualizadas',
      'Use o sistema de rejeição para delegacias com dados incorretos',
    ],
    links: [
      { id: 'map', title: 'Mapa' },
      { id: 'reports', title: 'Relatórios' },
    ],
  },
  {
    id: 'support',
    title: 'Suporte',
    icon: LifeBuoy,
    content: ['Em caso de dúvidas ou problemas, entre em contato com nossa equipe:'],
    list: [
      'Email: suporte@smartsafe.com',
      'Telefone: (11) 99999-9999',
      'Base de conhecimento: Acesse artigos e tutoriais',
      'Relatórios de bugs: Envie detalhes de problemas técnicos',
      'Feedback: Sua opinião é importante para melhorarmos o sistema',
    ],
    tips: [
      'Forneça detalhes ao relatar problemas, incluindo capturas de tela quando possível',
      'Inclua informações sobre o dispositivo e navegador utilizados',
      'Avalie as soluções fornecidas para ajudar outros usuários',
    ],
    links: [{ id: 'troubleshooting', title: 'Solução de Problemas' }],
  },
]

// Computed properties
const filteredResults = computed(() => {
  if (!searchQuery.value) return []

  const query = searchQuery.value.toLowerCase()
  const results = []

  sections.forEach((section) => {
    // Search in section title
    if (section.title.toLowerCase().includes(query)) {
      results.push({
        id: `${section.id}-title`,
        sectionId: section.id,
        title: section.title,
        content: section.content.join(' ').substring(0, 100) + '...',
        type: 'section',
      })
    }

    // Search in section content
    section.content.forEach((paragraph, index) => {
      if (paragraph.toLowerCase().includes(query)) {
        results.push({
          id: `${section.id}-content-${index}`,
          sectionId: section.id,
          title: section.title,
          content: paragraph,
          type: 'content',
        })
      }
    })

    // Search in section list items
    if (section.list) {
      section.list.forEach((item, index) => {
        if (item.toLowerCase().includes(query)) {
          results.push({
            id: `${section.id}-list-${index}`,
            sectionId: section.id,
            title: section.title,
            content: item,
            type: 'list',
          })
        }
      })
    }

    // Search in section tips
    if (section.tips) {
      section.tips.forEach((tip, index) => {
        if (tip.toLowerCase().includes(query)) {
          results.push({
            id: `${section.id}-tip-${index}`,
            sectionId: section.id,
            title: section.title,
            content: tip,
            type: 'tip',
          })
        }
      })
    }
  })

  return results.slice(0, 20) // Limit to 20 results
})

// Methods
const scrollToSection = (id) => {
  const element = document.getElementById(id)
  if (element) {
    element.scrollIntoView({ behavior: 'smooth', block: 'start' })
    currentSection.value = id
  }
}

const navigateToResult = (result) => {
  scrollToSection(result.sectionId)
  searchQuery.value = ''
}

const getSectionTitle = (sectionId) => {
  const section = sections.find((s) => s.id === sectionId)
  return section ? section.title : ''
}

const getIconForSection = (sectionId) => {
  const section = sections.find((s) => s.id === sectionId)
  return section ? section.icon : BookOpen
}

const handleScroll = () => {
  if (!contentContainer.value) return

  const { scrollTop, scrollHeight, clientHeight } = contentContainer.value
  scrollProgress.value = scrollHeight > clientHeight ? scrollTop / (scrollHeight - clientHeight) : 0

  if (searchQuery.value) return

  const scrollPosition = scrollTop + 100
  const sectionElements = document.querySelectorAll('[id]')

  for (let i = sectionElements.length - 1; i >= 0; i--) {
    const section = sectionElements[i]
    if (sections.some((s) => s.id === section.id) && section.offsetTop <= scrollPosition) {
      currentSection.value = section.id
      break
    }
  }
}

const clearSearch = () => {
  searchQuery.value = ''
}

const handleClickOutside = (event) => {
  // Verificar se o clique foi realmente fora do modal
  if (modalContainer.value && !modalContainer.value.contains(event.target)) {
    // Verificar se o target não é um elemento filho do modal
    if (!event.target.closest('.fixed')) {
      emit('close')
    }
  }
}

// Watchers
watch(
  () => props.show,
  (newVal) => {
    if (newVal) {
      document.body.style.overflow = 'hidden'
      setTimeout(() => {
        if (contentContainer.value) {
          contentContainer.value.addEventListener('scroll', handleScroll)
          handleScroll() // Initial scroll position
        }
      }, 100)
    } else {
      document.body.style.overflow = ''
      if (contentContainer.value) {
        contentContainer.value.removeEventListener('scroll', handleScroll)
      }
    }
  },
)

// Lifecycle
onMounted(() => {
  document.addEventListener('click', handleClickOutside, true) // Usar capturing para melhor detecção
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside, true)
  document.body.style.overflow = ''
})
</script>

<style scoped>
.slide-down-enter-active,
.slide-down-leave-active {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.slide-down-enter-from,
.slide-down-leave-to {
  opacity: 0;
  transform: translateY(-20px);
}

.slide-down-enter-to,
.slide-down-leave-from {
  opacity: 1;
  transform: translateY(0);
}

/* Scrollbar styling */
::-webkit-scrollbar {
  width: 6px;
}

::-webkit-scrollbar-track {
  background: transparent;
}

::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 3px;
}

.dark ::-webkit-scrollbar-thumb {
  background: #475569;
}

::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}

.dark ::-webkit-scrollbar-thumb:hover {
  background: #64748b;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
