<template>
  <div class="h-full">
    <Line :data="chartData" :options="chartOptions" ref="chartRef" />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js'
import { Line } from 'vue-chartjs'

// Registrar componentes do Chart.js
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler,
)

// Props
const props = defineProps({
  data: {
    type: Array,
    required: true,
  },
  title: {
    type: String,
    default: 'Tendência',
  },
})

// Referência para o gráfico
const chartRef = ref(null)

// Dados reativos do gráfico
const chartData = computed(() => ({
  labels: props.data.map((item) => item.label),
  datasets: [
    {
      label: props.title,
      data: props.data.map((item) => item.value),
      borderColor: 'rgb(16, 185, 129)',
      backgroundColor: 'rgba(16, 185, 129, 0.1)',
      tension: 0.4,
      fill: true,
      pointBackgroundColor: 'rgb(16, 185, 129)',
      pointBorderColor: 'white',
      pointBorderWidth: 2,
      pointRadius: 4,
      pointHoverRadius: 6,
    },
  ],
}))

// Opções do gráfico
const chartOptions = ref({
  responsive: true,
  maintainAspectRatio: false,
  animation: {
    duration: 1500,
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
      borderColor: 'rgb(16, 185, 129)',
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
