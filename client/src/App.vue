<script setup>
import { onMounted, onBeforeUnmount } from 'vue';
import ToastNotification from '@/components/ToastNotification.vue'
import LoadingOverlay from '@/components/LoadingOverlay.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import socket from '@/services/socket';

// Conectar ao WebSocket quando a aplicação iniciar
onMounted(() => {
  console.log('Iniciando conexão WebSocket...');
  socket.connect();
});

// Desconectar do WebSocket quando a aplicação for desmontada
onBeforeUnmount(() => {
  console.log('Desconectando WebSocket...');
  socket.disconnect();
});
</script>

<template>
  <ToastNotification />
  <LoadingOverlay />
  <ConfirmDialog />
  <router-view />
</template>

<style scoped></style>
