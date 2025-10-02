<template>
  <div class="h-full">
    <Bar :data="chartData" :options="chartOptions" ref="chartRef" />
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js'
import { Bar } from 'vue-chartjs'

// Registrar componentes do Chart.js
ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend)

// Props
const props = defineProps({
  data: {
    type: Array,
    required: true,
  },
})

// Referência para o gráfico
const chartRef = ref(null)

// Dados reativos do gráfico
const chartData = computed(() => ({
  labels: props.data.map((item) => item.data),
  datasets: [
    {
      label: 'SOS por Dia',
      backgroundColor: 'rgba(79, 70, 229, 0.1)',
      borderColor: 'rgb(79, 70, 229)',
      borderWidth: 2,
      borderRadius: 4,
      borderSkipped: false,
      data: props.data.map((item) => item.quantidade),
    },
  ],
}))

// Opções do gráfico
const chartOptions = ref({
  responsive: true,
  maintainAspectRatio: false,
  animation: {
    duration: 1000,
    easing: 'easeInOutQuart',
  },
  plugins: {
    legend: {
      display: false,
    },
    title: {
      display: false,
    },
    tooltip: {
      backgroundColor: 'rgba(0, 0, 0, 0.8)',
      titleColor: 'white',
      bodyColor: 'white',
      borderColor: 'rgb(79, 70, 229)',
      borderWidth: 1,
      callbacks: {
        label: function (context) {
          const value = context.parsed.y
          return `${value} ${value === 1 ? 'SOS' : 'SOSs'}`
        },
      },
    },
  },
  scales: {
    x: {
      grid: {
        display: false,
      },
      ticks: {
        color: 'rgb(107, 114, 128)',
        font: {
          size: 12,
        },
      },
    },
    y: {
      beginAtZero: true,
      grid: {
        color: 'rgba(0, 0, 0, 0.05)',
        drawBorder: false,
      },
      ticks: {
        precision: 0,
        color: 'rgb(107, 114, 128)',
        font: {
          size: 12,
        },
      },
    },
  },
  interaction: {
    intersect: false,
    mode: 'index',
  },
})
</script>
