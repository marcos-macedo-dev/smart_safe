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
})

// Referência para o gráfico
const chartRef = ref(null)

// Dados reativos do gráfico
const chartData = computed(() => ({
  labels: props.data.map((item) => item.mes),
  datasets: [
    {
      label: 'SOS por Semana',
      borderColor: 'rgb(79, 70, 229)',
      backgroundColor: 'rgba(79, 70, 229, 0.1)',
      data: props.data.map((item) => item.quantidade),
      tension: 0.4,
      fill: true,
      pointBackgroundColor: 'rgb(79, 70, 229)',
      pointBorderColor: 'white',
      pointBorderWidth: 2,
      pointRadius: 6,
      pointHoverRadius: 8,
    },
  ],
}))

// Opções do gráfico
const chartOptions = ref({
  responsive: true,
  maintainAspectRatio: false,
  animation: {
    duration: 1200,
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
