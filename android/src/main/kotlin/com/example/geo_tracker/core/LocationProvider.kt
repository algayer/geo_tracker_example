package com.example.geo_tracker.core

import com.example.geo_tracker.model.LocationSample

/**
 * Fonte de localização do dispositivo.
 *
 * Implementações devem:
 * - Tentar **cache** (última localização conhecida) rapidamente;
 * - Se não houver cache válido, tentar **leitura atual** com timeout;
 * - Lançar exceções claras em caso de permissão ausente, provider indisponível ou timeout.
 */
interface LocationProvider {

    /**
     * Retorna a última localização conhecida ou bloqueia até obter uma leitura atual
     * (best-effort), respeitando o [timeoutMs].
     *
     * @param timeoutMs Tempo máximo (ms) para tentar uma leitura atual quando não houver cache.
     * @return [LocationSample] com lat/lng/accuracy/ts e, se houver, speed/bearing.
     *
     * @throws SecurityException se as permissões de localização não estiverem concedidas.
     * @throws IllegalStateException se o provider estiver indisponível, as configurações
     *         de localização estiverem desativadas/insuficientes ou houver estouro de timeout.
     */
    fun getLastKnownOrCurrent(timeoutMs: Long = 1500L): LocationSample
}
