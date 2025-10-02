<template>
  <div class="h-full">
    <Doughnut :data="chartData" :options="chartOptions" ref="chartRef" />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { Chart as ChartJS, ArcElement, Tooltip, Legend } from 'chart.js'
import { Doughnut } from 'vue-chartjs'

// Registrar componentes do Chart.js
ChartJS.register(ArcElement, Tooltip, Legend)

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
  labels: props.data.map((item) => item.status),
  datasets: [
    {
      data: props.data.map((item) => item.quantidade),
      backgroundColor: props.data.map((item) => item.cor),
      borderColor: props.data.map((item) => item.cor),
      borderWidth: 2,
      hoverOffset: 4,
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
      position: 'bottom',
      labels: {
        usePointStyle: true,
        pointStyle: 'circle',
        font: {
          size: 12,
        },
        color: 'rgb(107, 114, 128)',
      },
    },
    tooltip: {
      backgroundColor: 'rgba(0, 0, 0, 0.8)',
      titleColor: 'white',
      bodyColor: 'white',
      borderColor: 'rgb(79, 70, 229)',
      borderWidth: 1,
      callbacks: {
        label: function (context) {
          const value = context.parsed
          const total = context.dataset.data.reduce((a, b) => a + b, 0)
          const percentage = total > 0 ? ((value / total) * 100).toFixed(1) : 0
          return `${value} SOS (${percentage}%)`
        },
      },
    },
  },
  cutout: '60%',
  interaction: {
    intersect: false,
  },
})
</script>
