
const { Delegacia, DelegaciaCobertura } = require('../models');
const { Op } = require('sequelize');

/**
 * Calcula a distância em km entre duas coordenadas usando a fórmula de Haversine.
 * @param {number} lat1 Latitude do ponto 1.
 * @param {number} lon1 Longitude do ponto 1.
 * @param {number} lat2 Latitude do ponto 2.
 * @param {number} lon2 Longitude do ponto 2.
 * @returns {number} Distância em quilômetros.
 */
function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // Raio da Terra em km
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const d = R * c; // Distância em km
  return d;
}

function deg2rad(deg) {
  return deg * (Math.PI / 180);
}

/**
 * Encontra a delegacia responsável por uma dada localização.
 * @param {number} latitude Latitude do incidente.
 * @param {number} longitude Longitude do incidente.
 * @returns {Promise<number|null>} ID da delegacia responsável ou null se nenhuma for encontrada.
 */
async function findDelegaciaForLocation(latitude, longitude) {
  if (!latitude || !longitude) {
    return null;
  }

  const delegacias = await Delegacia.findAll({
    include: [{
      model: DelegaciaCobertura,
      as: 'coberturas' // 'as' deve corresponder ao definido na associação
    }]
  });

  let delegaciaMaisProxima = null;
  let menorDistancia = Infinity;

  for (const delegacia of delegacias) {
    // Se a delegacia não tem coberturas definidas, calcular distância direta
    if (!delegacia.coberturas || delegacia.coberturas.length === 0) {
      const distancia = getDistanceFromLatLonInKm(
        latitude,
        longitude,
        delegacia.latitude,
        delegacia.longitude
      );
      
      // Se esta delegacia está mais próxima que a anterior, atualizar
      if (distancia < menorDistancia) {
        menorDistancia = distancia;
        delegaciaMaisProxima = delegacia.id;
      }
      continue;
    }

    // Verificar coberturas definidas
    for (const cobertura of delegacia.coberturas) {
      if (cobertura.tipo === 'raio') {
        const distancia = getDistanceFromLatLonInKm(
          latitude,
          longitude,
          delegacia.latitude,
          delegacia.longitude
        );
        // O valor da cobertura de raio está em km
        if (distancia <= parseFloat(cobertura.valor)) {
          // Se esta delegacia está mais próxima que a anterior, atualizar
          if (distancia < menorDistancia) {
            menorDistancia = distancia;
            delegaciaMaisProxima = delegacia.id;
          }
        }
      }
      // TODO: Implementar lógica para cobertura por 'municipio' e 'estado'
      // Isso pode exigir um serviço de geocodificação reversa (lat/lon -> cidade/estado)
    }
  }

  return delegaciaMaisProxima; // Retorna a delegacia mais próxima ou null se nenhuma for encontrada
}

module.exports = { findDelegaciaForLocation };
