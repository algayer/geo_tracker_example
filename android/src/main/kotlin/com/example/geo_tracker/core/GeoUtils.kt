package com.example.geo_tracker.core

import kotlin.math.*

/**
 * Utilitários geográficos.
 *
 * - [haversineMeters]: distância em metros entre dois pares lat/lon (WGS84) usando Haversine.
 * - [etaSeconds]: tempo estimado (s) dado distância (m) e velocidade (m/s).
 */
object GeoUtils {

    /** Raio médio da Terra em metros (aprox.). */
    private const val EARTH_RADIUS_METERS = 6_371_000.0

    /**
     * Distância em metros entre dois pontos geográficos.
     *
     * @param lat1 Latitude do ponto 1 (graus decimais)
     * @param lon1 Longitude do ponto 1 (graus decimais)
     * @param lat2 Latitude do ponto 2 (graus decimais)
     * @param lon2 Longitude do ponto 2 (graus decimais)
     * @return Distância Haversine em metros.
     */
    fun haversineMeters(
        lat1: Double,
        lon1: Double,
        lat2: Double,
        lon2: Double
    ): Double {
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)

        val a = sin(dLat / 2).pow(2) +
                cos(Math.toRadians(lat1)) *
                cos(Math.toRadians(lat2)) *
                sin(dLon / 2).pow(2)

        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return EARTH_RADIUS_METERS * c
    }

    /**
     * Tempo estimado em segundos.
     *
     * @param distanceMeters Distância em metros.
     * @param speedMps Velocidade em m/s.
     * @return ETA em segundos; retorna NaN se velocidade <= 0 ou distância inválida.
     */
    fun etaSeconds(distanceMeters: Double, speedMps: Double): Double {
        if (speedMps <= 0.0 || distanceMeters.isNaN() || distanceMeters < 0.0) return Double.NaN
        return distanceMeters / speedMps
    }
}
