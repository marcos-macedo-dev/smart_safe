# Como usar as stores de Toast e Loading

## Toast Store

A toast store fornece métodos simples para mostrar diferentes tipos de notificações:

```javascript
import { useToastStore } from '@/stores/toast'
const toast = useToastStore()

// Mostrar toasts de diferentes tipos
toast.success('Operação realizada com sucesso!')
toast.error('Ocorreu um erro na operação')
toast.warning('Esta é uma mensagem de aviso')
toast.info('Informação importante')

// Método genérico
toast.addToast('Mensagem personalizada', 'tipo')
```

## Loading Store

A loading store permite controlar estados de carregamento de forma simples:

```javascript
import { useLoadingStore } from '@/stores/loading'
const loading = useLoadingStore()

// Iniciar um estado de loading
loading.start('identificador')

// Parar um estado de loading
loading.stop('identificador')

// Verificar se um identificador específico está carregando
if (loading.isLoading('identificador')) {
  // Fazer algo
}

// Verificar se qualquer coisa está carregando
if (loading.isLoadingAny()) {
  // Fazer algo
}
```

## Exemplo de uso em um componente

```javascript
import { useToastStore } from '@/stores/toast'
import { useLoadingStore } from '@/stores/loading'

export default {
  setup() {
    const toast = useToastStore()
    const loading = useLoadingStore()
    
    const fetchData = async () => {
      loading.start('fetchData')
      
      try {
        await api.getData()
        toast.success('Dados carregados com sucesso!')
      } catch (error) {
        toast.error('Falha ao carregar dados')
      } finally {
        loading.stop('fetchData')
      }
    }
    
    return { fetchData, loading }
  }
}
```