
import axios from 'axios'
import { useLoadingStore } from '@/stores/loading'
import { useToastStore } from '@/stores/toast'
import { useUserStore } from '@/stores/user'
import router from '@/router'

// ============================================================================
// CONSTANTS
// ============================================================================
const TOKEN_KEY = 'authToken'

// ============================================================================
// AUTH UTILITIES
// ============================================================================
export function saveAuthData(token, user) {
  localStorage.setItem(TOKEN_KEY, token)
  const userStore = useUserStore()
  userStore.setUser(user)
}

export function getAuthToken() {
  return localStorage.getItem(TOKEN_KEY)
}

export function removeAuthData() {
  localStorage.removeItem(TOKEN_KEY)
  const userStore = useUserStore()
  userStore.clearUser()
}

export function isAuthenticated() {
  return !!getAuthToken()
}

// ============================================================================
// HTTP CLIENT CONFIGURATION
// ============================================================================
const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:3002/api',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000,
})

// ============================================================================
// HTTP INTERCEPTORS
// ============================================================================
http.interceptors.request.use(
  (config) => {
    const token = getAuthToken()
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    const loading = useLoadingStore()
    loading.start('api')
    return config
  },
  (error) => {
    const loading = useLoadingStore()
    loading.stop('api')
    return Promise.reject(error)
  },
)

function handleLogout() {
  removeAuthData()
  router.push('/login')
}

http.interceptors.response.use(
  (response) => {
    const loading = useLoadingStore()
    loading.stop('api')
    return response
  },
  (error) => {
    const loading = useLoadingStore()
    const toast = useToastStore()
    loading.stop('api')

    const message =
      error.response?.data?.message ||
      error.response?.data?.error ||
      'Erro de conexão com o servidor'

    // Check if this is a login attempt with invalid credentials
    const isLoginAttempt = error.config?.url?.includes('/auth/login')
    const isUnauthorized = error.response?.status === 401

    if (isUnauthorized && !isLoginAttempt) {
      // Session expired - not related to login
      toast.error('Sessão expirada. Faça login novamente.')
      handleLogout()
    } else {
      // Show specific error message or generic one
      toast.error(message)
    }

    return Promise.reject(message)
  },
)

// ============================================================================
// AUTHENTICATION SERVICES
// ============================================================================
export const login = async (payload) => {
  const response = await http.post('/auth/login', payload)
  if (response.data.accessToken) {
    saveAuthData(response.data.accessToken, response.data.user)
  }
  return response
}

export const logout = async () => {
  try {
    await http.post('/auth/logout')
  } finally {
    removeAuthData()
  }
}

export const changePassword = (currentPassword, newPassword) =>
  http.post('/auth/change-password', {
    currentPassword,
    newPassword
  })

// ============================================================================
// PASSWORD RESET SERVICES
// ============================================================================
// User password reset
export const requestPasswordResetUser = (email) => 
  http.post('/auth/request-password-reset/user', { email })

export const resetPasswordWithOtp = (email, otp, newPassword) =>
  http.post('/auth/reset-password/otp', {
    email,
    otp,
    newPassword
  })

// Authority password reset
export const requestPasswordResetAuthority = (email) => 
  http.post('/auth/request-password-reset/authority', { email })

export const resetPasswordWithToken = (token, newPassword) =>
  http.post(`/auth/reset-password/authority/${token}`, {
    newPassword
  })

// ============================================================================
// USER SERVICES
// ============================================================================
export const createUser = (payload) => http.post('/users', payload)
export const listUsers = () => http.get('/users')
export const getUserById = (id) => http.get(`/users/${id}`)
export const getLoggedInUser = () => http.get('/users/me')
export const updateUser = (id, payload) => http.put(`/users/${id}`, payload)
export const deleteUser = (id) => http.delete(`/users/${id}`)

// ============================================================================
// SOS SERVICES
// ============================================================================
export const createSos = (payload) => http.post('/sos', payload)
export const listSos = (params) => http.get('/sos', { params })
export const getSosById = (id) => http.get(`/sos/${id}`)
export const updateSos = (id, payload) => http.put(`/sos/${id}`, payload)
export const deleteSos = (id) => http.delete(`/sos/${id}`)

// ============================================================================
// DELEGACIA SERVICES
// ============================================================================
export const listDelegacias = (params = {}) => http.get('/delegacias', { params })
export const findNearbyDelegacias = (params) => 
  http.get('/delegacias/proximas', { params })
export const createDelegacia = (payload) => http.post('/delegacias', payload)
export const updateDelegacia = (id, payload) => http.put(`/delegacias/${id}`, payload)
export const deleteDelegacia = (id) => http.delete(`/delegacias/${id}`)

// ============================================================================
// DELEGACIA REGISTRATION SERVICES
// ============================================================================
export const getPendingDelegaciaRegistration = (token) => 
  http.get('/delegacias-register/pending', { params: { token } })
export const registerDelegacia = (payload) => http.post('/delegacias-register/register', payload)
export const approveDelegaciaRegistration = (payload) => http.post('/delegacias-register/approve', payload)
export const rejectDelegaciaRegistration = (payload) => http.post('/delegacias-register/reject', payload)


// ============================================================================
// DELEGACIA USER SERVICES
// ============================================================================
export const listDelegaciaUsers = () => http.get('/delegacia-users')
export const getDelegaciaUserById = (id) => http.get(`/delegacia-users/${id}`)
export const updateDelegaciaUser = (id, payload) => http.put(`/delegacia-users/${id}`, payload)
export const deactivateDelegaciaUser = (id) => http.patch(`/delegacia-users/${id}/deactivate`)
export const reactivateDelegaciaUser = (id) => http.patch(`/delegacia-users/${id}/reactivate`)

// ============================================================================
// DELEGACIA STATISTICS SERVICES
// ============================================================================
export const getDelegaciaStats = (params = {}) => http.get('/delegacia-stats/stats', { params })
export const getDelegaciaSosByHour = (params = {}) => http.get('/delegacia-stats/sos-by-hour', { params })
export const getDelegaciaSosByDayOfWeek = (params = {}) => http.get('/delegacia-stats/sos-by-day-of-week', { params })
export const getDelegaciaUserDemographics = (params = {}) => http.get('/delegacia-stats/user-demographics', { params })
export const getDelegaciaLocationStats = (params = {}) => http.get('/delegacia-stats/location-stats', { params })

// ============================================================================
// AUTHORITY SERVICES
// ============================================================================
export const createAutoridade = (payload) => http.post('/autoridades', payload)
export const listAutoridades = () => http.get('/autoridades')
export const getAutoridadeById = (id) => http.get(`/autoridades/${id}`)
export const updateAutoridade = (id, payload) => http.put(`/autoridades/${id}`, payload)
export const deleteAutoridade = (id) => http.delete(`/autoridades/${id}`)
export const getLoggedInAutoridade = () => http.get('/autoridades/me')
export const updateLoggedInAutoridade = (payload) => http.put('/autoridades/me', payload)

// ============================================================================
// MEDIA SERVICES
// ============================================================================
export const createMedia = (payload) => http.post('/media', payload)
export const listMedia = (params) => http.get('/media', { params })
export const getMediaById = (id) => http.get(`/media/${id}`)
export const updateMedia = (id, payload) => http.put(`/media/${id}`, payload)
export const deleteMedia = (id) => http.delete(`/media/${id}`)

// ============================================================================
// CONTACT SERVICES
// ============================================================================
export const createContact = (payload) => http.post('/contacts', payload)
export const listContacts = () => http.get('/contacts')
export const getContactById = (id) => http.get(`/contacts/${id}`)
export const updateContact = (id, payload) => http.put(`/contacts/${id}`, payload)
export const deleteContact = (id) => http.delete(`/contacts/${id}`)

// ============================================================================
// TRACKING SERVICES
// ============================================================================
export const getTrackingBySosId = (sosId) => http.get(`/rastreamento-apuros/${sosId}`)
export const createTrackingPoint = (payload) => http.post('/rastreamento-apuros', payload)

// ============================================================================
// INVITE SERVICES
// ============================================================================
export const verifyInviteToken = (token) => http.get(`/invites/verify/${token}`)
export const acceptInvite = (data) => http.post('/invites/accept', data)
export const sendInvite = (data) => http.post('/invites/send', data)

// ============================================================================
// EMAIL SERVICES
// ============================================================================
export const sendGenericTemplateEmail = (payload) => http.post('/email/send-generic-template', payload)
export const sendPasswordResetEmail = (payload) => http.post('/email/send-password-reset', payload)
export const sendInviteEmail = (payload) => http.post('/email/send-invite', payload)
export const sendNotificationEmail = (payload) => http.post('/email/send-notification', payload)
export const sendCustomTemplateEmail = (payload) => http.post('/email/send-custom-template', payload)
export const sendCustomEmail = (payload) => http.post('/email/send-custom', payload)

// ============================================================================
// UPLOAD SERVICES
// ============================================================================
export const uploadFile = (formData) => http.post('/upload', formData, {
  headers: {
    'Content-Type': 'multipart/form-data'
  }
})

// ============================================================================
// REPORT SERVICES
// ============================================================================
export const getSystemOverview = () => http.get('/reports/overview')
export const getSosStats = (params = {}) => http.get('/reports/sos-stats', { params })
export const getUserStats = (params = {}) => http.get('/reports/user-stats', { params })
export const getTopDelegacias = (params = {}) => http.get('/reports/top-delegacias', { params })
export const getMonthlyStats = (params = {}) => http.get('/reports/monthly-stats', { params })
export const getMediaStats = (params = {}) => http.get('/reports/media-stats', { params })
export const getUserDemographics = (params = {}) => http.get('/reports/user-demographics', { params })
export const getSosLocationStats = (params = {}) => http.get('/reports/sos-location-stats', { params })
export const getSosGeographicDistribution = (params = {}) => http.get('/reports/sos-geographic-distribution', { params })
export const getSosResponseStats = (params = {}) => http.get('/reports/sos-response-stats', { params })
export const getMediaStatsByType = (params = {}) => http.get('/reports/media-stats-by-type', { params })
export const getSosByHour = (params = {}) => http.get('/reports/sos-by-hour', { params })

// ============================================================================
// EXPORT
// ============================================================================
export default http
