package com.example.geo_tracker.model

/**
 * Amostra de localização (espelha campos básicos de [android.location.Location]).
 *
 * @param lat Latitude (graus decimais).
 * @param lng Longitude (graus decimais).
 * @param accuracy Precisão (m).
 * @param timestampMillis Epoch em milissegundos do instante do fix.
 * @param speedMps Velocidade (m/s), se disponível.
 * @param bearing Rumo (0–360°, 0 = Norte), se disponível.
 */
data class LocationSample(
    val lat: Double,
    val lng: Double,
    val accuracy: Float,
    val timestampMillis: Long,
    val speedMps: Float? = null,
    val bearing: Float? = null
)
