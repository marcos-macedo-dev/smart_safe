import { defineStore } from 'pinia';
import { ref } from 'vue';

export const useConfirmDialog = defineStore('confirmDialog', () => {
  const isOpen = ref(false);
  const title = ref('');
  const message = ref('');
  let resolveFn = null;

  function confirm({ titulo, mensagem }) {
    title.value = titulo;
    message.value = mensagem;
    isOpen.value = true;
    return new Promise((resolve) => {
      resolveFn = resolve;
    });
  }

  function accept() {
    isOpen.value = false;
    if (resolveFn) {
      resolveFn(true);
    }
    clear();
  }

  function cancel() {
    isOpen.value = false;
    if (resolveFn) {
      resolveFn(false);
    }
    clear();
  }

  function clear() {
    title.value = '';
    message.value = '';
    resolveFn = null;
  }

  return { isOpen, title, message, confirm, accept, cancel };
});