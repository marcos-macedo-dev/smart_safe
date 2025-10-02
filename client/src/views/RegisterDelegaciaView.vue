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
            Nome do Administrador <span class="text-red-500">*</span>
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
            Email do Administrador <span class="text-red-500">*</span>
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

      <div class="mt-5 text-center text-gray-400 text-xs">
        <p>
          Após o envio, a solicitação será revisada pela equipe.<br />
          Se aprovada, um convite será enviado ao administrador.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive } from 'vue'
import { useRouter } from 'vue-router'
import { Send } from 'lucide-vue-next'
import { registerDelegacia } from '@/services/http'
import { vMaska } from 'maska/vue'
import { useToastStore } from '@/stores/toast'

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
