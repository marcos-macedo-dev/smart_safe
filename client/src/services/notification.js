import { useToastStore } from '@/stores/toast';

class NotificationService {
  constructor() {
    this.toast = useToastStore();
    this.recentSosNotifications = new Map();
    this.RECENT_SOS_TIMEOUT = 8000; // evita toasts duplicados em sequência
  }

  // Mostrar notificação visual
  showVisualNotification(title, message, type = 'info') {
    // Usar o toast store para mostrar notificação
    switch (type) {
      case 'success':
        this.toast.success(message);
        break;
      case 'error':
        this.toast.error(message);
        break;
      case 'warning':
        this.toast.warning(message);
        break;
      default:
        this.toast.info(message);
    }
    
    // Adicionar log no console
    console.log(`[${type.toUpperCase()}] ${title}: ${message}`);
  }

  // Notificação completa para novo SOS
  notifyNewSos(sos) {
    const sosId = sos?.id !== undefined && sos?.id !== null ? String(sos.id) : null;

    if (sosId) {
      if (this.recentSosNotifications.has(sosId)) {
        return;
      }

      const timeoutId = setTimeout(() => {
        this.recentSosNotifications.delete(sosId);
      }, this.RECENT_SOS_TIMEOUT);

      this.recentSosNotifications.set(sosId, timeoutId);
    }

    // Mostrar notificação visual
    this.showVisualNotification(
      'Novo Chamado', 
      `Chamado de emergência #${sos.id} recebido`, 
      'warning'
    );
    
    // Focar na aba se possível
    if (window.Notification && Notification.permission === 'granted') {
      new Notification('Smart Safe', {
        body: `Novo chamado de emergência #${sos.id}`,
        icon: '/favicon.ico'
      });
    }
  }

  // Notificação para SOS atualizado
  notifySosUpdate(sos) {
    this.showVisualNotification(
      'Chamado Atualizado', 
      `Chamado #${sos.id} foi atualizado`, 
      'info'
    );
  }

  // Notificação para novo ponto de rastreamento
  notifyNewTrackingPoint(trackingPoint) {
    this.showVisualNotification(
      'Nova Posição', 
      `Nova posição recebida para chamado #${trackingPoint.sos_id}`, 
      'info'
    );
  }

  // Solicitar permissão para notificações do navegador
  async requestNotificationPermission() {
    if (window.Notification && Notification.permission === 'default') {
      try {
        await Notification.requestPermission();
      } catch (error) {
        console.warn('Não foi possível solicitar permissão de notificação:', error);
      }
    }
  }
}

// Exportar uma instância singleton
export default new NotificationService();
