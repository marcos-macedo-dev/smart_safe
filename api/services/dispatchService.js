const { Sos, Autoridade } = require('../models');
const { Op } = require('sequelize');

/**
 * Serviço responsável pela lógica de atribuição e despacho de ocorrências.
 */
class DispatchService {

  /**
   * Encontra o agente ativo com menor carga de trabalho em uma delegacia.
   * Critérios:
   * 1. Pertence à delegacia.
   * 2. Cargo 'Agente'.
   * 3. Status 'ativo'.
   * 4. Menor número de SOS 'ativos' ou 'aguardando'.
   * 
   * @param {number} delegaciaId 
   * @param {number} sosLatitude (Reservado para uso futuro: proximidade)
   * @param {number} sosLongitude (Reservado para uso futuro: proximidade)
   * @returns {Promise<Autoridade|null>} O agente selecionado ou null
   */
  static async findBestAgentForSos(delegaciaId, sosLatitude, sosLongitude) {
    // 1. Busca todos agentes candidatos na delegacia
    const agentes = await Autoridade.findAll({
      where: {
        delegacia_id: delegaciaId,
        cargo: 'Agente',
        ativo: true
      }
    });

    if (agentes.length === 0) return null;

    // 2. Calcula carga de trabalho para cada um
    // Otimização futura: Fazer isso com um COUNT/GROUP BY direto no banco seria mais performático
    // para delegacias com MUITOS agentes. Para escala atual, loop é aceitável.
    let agenteComMenorCarga = agentes[0];
    let menorCarga = Infinity;

    for (const agente of agentes) {
      const cargaAtual = await Sos.count({
        where: {
          autoridade_id: agente.id,
          status: { [Op.in]: ['ativo', 'aguardando_autoridade'] }
        }
      });

      if (cargaAtual < menorCarga) {
        menorCarga = cargaAtual;
        agenteComMenorCarga = agente;
      }
    }

    return agenteComMenorCarga;
  }
}

module.exports = DispatchService;
