# Smart Safe - Detalhes das Telas do Cliente

## Índice
1. [Telas de Autenticação](#telas-de-autenticação)
   - [Login](#login)
   - [Registro de Delegacia](#registro-de-delegacia)
   - [Aceitar Convite](#aceitar-convite)
   - [Recuperar Senha (Autoridade)](#recuperar-senha-autoridade)
   - [Recuperar Senha (Usuário)](#recuperar-senha-usuário)
   - [Redefinir Senha](#redefinir-senha)
2. [Telas do Painel](#telas-do-painel)
   - [Dashboard](#dashboard)
   - [Chamados de Emergência (SOS)](#chamados-de-emergência-sos)
   - [Detalhes do Chamado SOS](#detalhes-do-chamado-sos)
   - [Rastreamento de Apuros](#rastreamento-de-apuros)
   - [Gerenciamento de Operadores](#gerenciamento-de-operadores)
   - [Meu Perfil (Autoridade)](#meu-perfil-autoridade)
   - [Meu Perfil (Operador)](#meu-perfil-operador)
   - [Alterar Senha](#alterar-senha)
   - [Painel Administrativo](#painel-administrativo)
   - [Visualização de Mapa](#visualização-de-mapa)

## Telas de Autenticação

### Login
**Arquivo:** `LoginView.vue`

**Descrição:**
Tela inicial do sistema onde os usuários fazem login com email e senha. Possui link para recuperação de senha.

**Funcionalidades:**
- Autenticação de usuários
- Validação de campos obrigatórios
- Exibição de mensagens de erro/sucesso via toast
- Redirecionamento para dashboard após login bem-sucedido
- Link para recuperação de senha

**Componentes/Ícones:**
- LogIn (lucide-vue-next)

### Registro de Delegacia
**Arquivo:** `RegisterDelegaciaView.vue`

**Descrição:**
Tela para solicitação de registro de novas delegacias no sistema. Coleta informações da delegacia e do administrador principal.

**Funcionalidades:**
- Formulário para dados da delegacia (nome, endereço, coordenadas, telefone)
- Formulário para dados do administrador (nome, email)
- Validação de campos obrigatórios
- Exibição de mensagens de erro/sucesso via toast
- Máscara para telefone
- Redirecionamento para login após envio

**Componentes/Ícones:**
- UserPlus, Loader (lucide-vue-next)
- vMaska (para máscara de telefone)

### Aceitar Convite
**Arquivo:** `AcceptInviteView.vue`

**Descrição:**
Tela para aceitação de convites enviados por email para novos usuários. Permite criar senha e ativar conta.

**Funcionalidades:**
- Verificação de token de convite
- Exibição de detalhes do convite (nome, email, cargo, delegacia)
- Criação de senha (com confirmação)
- Validação de senha (mínimo 6 caracteres)
- Exibição de mensagens de erro/sucesso via toast
- Redirecionamento para login após aceitação

**Componentes/Ícones:**
- Loader2, LogIn, XCircle (lucide-vue-next)

### Recuperar Senha (Autoridade)
**Arquivo:** `ForgotPassword.vue`

**Descrição:**
Tela para solicitação de recuperação de senha por autoridades. Envia instruções por email.

**Funcionalidades:**
- Solicitação de recuperação de senha via email
- Validação de email
- Exibição de mensagens de erro/sucesso via toast
- Redirecionamento automático para login após envio

**Componentes/Ícones:**
- Send (lucide-vue-next)

### Recuperar Senha (Usuário)
**Arquivo:** `ForgotPasswordUser.vue`

**Descrição:**
Tela para solicitação de recuperação de senha por usuários comuns. Envia instruções por email.

**Funcionalidades:**
- Solicitação de recuperação de senha via email
- Validação de email
- Exibição de mensagens de erro/sucesso via toast
- Redirecionamento automático para login após envio

**Componentes/Ícones:**
- Send (lucide-vue-next)

### Redefinir Senha
**Arquivo:** `ResetPassword.vue`

**Descrição:**
Tela para redefinição de senha após solicitação de recuperação. Funciona tanto para autoridades (com token) quanto para usuários (com OTP).

**Funcionalidades:**
- Redefinição de senha para autoridades usando token
- Redefinição de senha para usuários usando OTP
- Validação de senha (mínimo 6 caracteres)
- Confirmação de senha
- Exibição de mensagens de erro/sucesso via toast
- Redirecionamento automático para login após redefinição

**Componentes/Ícones:**
- Lock (lucide-vue-next)

## Telas do Painel

### Dashboard
**Arquivo:** `DashboardView.vue`

**Descrição:**
Tela principal do sistema com visão geral das estatísticas e atividades recentes.

**Funcionalidades:**
- Exibição de estatísticas principais (operadores, delegacias, SOS, taxa de resolução)
- Gráficos de SOS por dia e por mês
- Tabela de atividades recentes
- Carregamento de dados em tempo real
- Seleção de mês para gráficos mensais

**Componentes/Ícones:**
- Users, Building, AlertTriangle, CheckCircle, UserPlus (lucide-vue-next)
- SosChart, SosMonthlyChart (componentes personalizados)

### Chamados de Emergência (SOS)
**Arquivo:** `SosView.vue`

**Descrição:**
Tela de listagem e gerenciamento de chamados de emergência recebidos.

**Funcionalidades:**
- Listagem de todos os chamados SOS
- Filtros por status e busca textual
- Paginação de resultados
- Exibição de estatísticas por status
- Visualização detalhada de chamados
- Atualização em tempo real via WebSocket
- Notificações de novos chamados

**Componentes/Ícones:**
- RefreshCw, Search (lucide-vue-next)

### Detalhes do Chamado SOS
**Arquivo:** `SosDetailsView.vue`

**Descrição:**
Tela com informações detalhadas de um chamado SOS específico, incluindo mapa com localização.

**Funcionalidades:**
- Exibição detalhada de informações do solicitante
- Exibição de status e localização
- Reprodução de mídia (áudio e vídeo)
- Mapa com localização do chamado
- Rota otimizada da delegacia até o local do chamado
- Atualização de status do chamado
- Rastreamento em tempo real via WebSocket
- Cópia de coordenadas
- Abertura no Google Maps

**Componentes/Ícones:**
- ArrowLeft, MapPin, Copy, Map (lucide-vue-next)
- Leaflet (para mapas)

### Rastreamento de Apuros
**Arquivo:** `TrackingView.vue`

**Descrição:**
Tela de visualização do rastreamento de apuros em tempo real com histórico de pontos.

**Funcionalidades:**
- Mapa com histórico de pontos de rastreamento
- Lista de pontos com data/hora e coordenadas
- Informações de precisão e nível de bateria
- Atualização em tempo real via WebSocket
- Exibição de popups com informações nos marcadores do mapa

**Componentes/Ícones:**
- ArrowLeft, RefreshCw (lucide-vue-next)
- Leaflet (para mapas)

### Gerenciamento de Operadores
**Arquivo:** `UsersView.vue`

**Descrição:**
Tela para gerenciamento de operadores da delegacia.

**Funcionalidades:**
- Listagem de todos os operadores
- Filtros por status e cargo
- Busca textual
- Paginação de resultados
- Adição de novos operadores (envio de convite)
- Edição de informações de operadores
- Ativação/desativação de operadores
- Exclusão de operadores
- Modais para adicionar/editar operadores
- Confirmação de exclusão via diálogo

**Componentes/Ícones:**
- Plus, Edit, UserX, UserCheck, Search, RefreshCw, Trash2 (lucide-vue-next)
- ConfirmDialog (componente personalizado)

### Meu Perfil (Autoridade)
**Arquivo:** `AutoridadeProfileView.vue`

**Descrição:**
Tela de gerenciamento de perfil para autoridades.

**Funcionalidades:**
- Visualização/edição de informações pessoais
- Exibição de informações da delegacia (somente leitura)
- Link para página dedicada de alteração de senha
- Cancelamento de alterações
- Salvamento de alterações

**Componentes/Ícones:**
- Camera (lucide-vue-next)

### Meu Perfil (Operador)
**Arquivo:** `ProfileView.vue`

**Descrição:**
Tela de gerenciamento de perfil para operadores.

**Funcionalidades:**
- Visualização/edição de informações pessoais
- Alteração de senha
- Cancelamento de alterações
- Salvamento de alterações

**Componentes/Ícones:**
- Camera (lucide-vue-next)

### Alterar Senha
**Arquivo:** `ChangePasswordView.vue`

**Descrição:**
Tela dedicada para alteração de senha de autoridades.

**Funcionalidades:**
- Alteração de senha com validação
- Confirmação de nova senha
- Exibição/ocultação de senhas
- Validação de senha (mínimo 6 caracteres)
- Cancelamento de alterações

**Componentes/Ícones:**
- ChevronLeft, Lock, Eye, EyeOff, Loader (lucide-vue-next)

### Painel Administrativo
**Arquivo:** `ReportsView.vue`

**Descrição:**
Tela de relatórios e estatísticas detalhadas do sistema.

**Funcionalidades:**
- Visão geral do sistema (total de SOS, fechados, usuários, delegacias)
- Gráficos de status dos SOS
- Gráficos de SOS por mês
- Tabela de últimos SOS
- Tabela de delegacias com mais SOS
- Estatísticas detalhadas por status, período e usuários
- Estatísticas de mídia nos chamados
- Demografia dos usuários
- Localização dos chamados
- Mapa de calor geográfico
- Filtros por estado

**Componentes/Ícones:**
- RefreshCw, AlertTriangle, CheckCircle, Users, Building (lucide-vue-next)
- Bar, Doughnut (vue-chartjs)
- LMap, LTileLayer (@vue-leaflet/vue-leaflet)
- Leaflet e Leaflet.heat

### Visualização de Mapa
**Arquivo:** `MapView.vue`

**Descrição:**
Tela de visualização do mapa com todas as delegacias registradas.

**Funcionalidades:**
- Mapa com marcadores de todas as delegacias
- Informações das delegacias em popups
- Zoom automático para mostrar todas as delegacias
- Tratamento de erros de carregamento

**Componentes/Ícones:**
- Leaflet (para mapas)
