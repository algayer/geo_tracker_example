package com.example.geo_tracker.providers

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.util.Log
import com.example.geo_tracker.core.LocationProvider
import com.example.geo_tracker.model.LocationSample
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.LocationSettingsRequest
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

private const val TAG = "FusedLocationProvider"
private const val ERR_LOCATION_SETTINGS_DISABLED = "LOCATION_SETTINGS_DISABLED"

// Cache: aguarda o Task.lastLocation e aceita fix até esta “idade”.
private const val LAST_LOCATION_WAIT_MS = 500L // 0.5s
private const val LAST_LOCATION_MAX_AGE_MS = 5_000L // 5s

/**
 * [LocationProvider] baseado em FusedLocationProviderClient.
 *
 * Estratégia:
 * 1) Tenta `lastLocation` recente (≤ [LAST_LOCATION_MAX_AGE_MS]) aguardando até [LAST_LOCATION_WAIT_MS].
 * 2) Se não houver cache válido, tenta `getCurrentLocation` com alta precisão e [timeoutMs].
 *
 * Se as configurações de localização estiverem desativadas e não houver cache, lança
 * `IllegalStateException(ERR_LOCATION_SETTINGS_DISABLED)`.
 */
class FusedLocationProvider(private val context: Context) : LocationProvider {

    private val fused: FusedLocationProviderClient by lazy {
        LocationServices.getFusedLocationProviderClient(context)
    }
    private val settingsClient by lazy {
        LocationServices.getSettingsClient(context)
    }

    // Executor para callbacks do Play Services (evita main thread).
    private val bg: ExecutorService = Executors.newSingleThreadExecutor()

    @SuppressLint("MissingPermission")
    override fun getLastKnownOrCurrent(timeoutMs: Long): LocationSample {
        val settingsError = checkLocationSettingsOrNull()

        getLastLocationQuick(LAST_LOCATION_WAIT_MS, LAST_LOCATION_MAX_AGE_MS)
            ?.let { return it.toSample() }

        if (settingsError != null) {
            throw IllegalStateException(ERR_LOCATION_SETTINGS_DISABLED, settingsError)
        }

        getCurrentLocationHighAccuracy(timeoutMs)?.let { return it.toSample() }

        throw IllegalStateException("Não foi possível obter localização em ${timeoutMs}ms.")
    }

    /** Retorna `null` se as configurações estiverem OK; caso contrário, a exceção do SettingsClient. */
    private fun checkLocationSettingsOrNull(): Exception? {
        val req = LocationSettingsRequest.Builder()
            .addLocationRequest(
                LocationRequest.Builder(1000L)
                    .setPriority(Priority.PRIORITY_HIGH_ACCURACY)
                    .build()
            ).build()

        var error: Exception? = null
        val latch = CountDownLatch(1)

        settingsClient.checkLocationSettings(req)
            .addOnSuccessListener(bg) { latch.countDown() }
            .addOnFailureListener(bg) { ex ->
                error = ex as? Exception ?: Exception(ex.message)
                latch.countDown()
            }

        latch.await(500, TimeUnit.MILLISECONDS)
        return error
    }

    /** Tenta `lastLocation` e valida a “idade” do fix. */
    @SuppressLint("MissingPermission")
    private fun getLastLocationQuick(waitMs: Long, maxAgeMs: Long): Location? {
        val task = runCatching { fused.lastLocation }.getOrNull() ?: return null
        val latch = CountDownLatch(1)
        val ref = AtomicReference<Location?>()

        task.addOnSuccessListener(bg) { loc ->
            if (loc != null) {
                val ageMs = System.currentTimeMillis() - loc.time
                ref.set(if (ageMs <= maxAgeMs) loc else null)
            } else {
                ref.set(null)
            }
            latch.countDown()
        }.addOnFailureListener(bg) {
            ref.set(null)
            latch.countDown()
        }

        latch.await(waitMs, TimeUnit.MILLISECONDS)
        return ref.get()
    }

    /** Tenta uma leitura atual com alta precisão e cancela no timeout. */
    @SuppressLint("MissingPermission")
    private fun getCurrentLocationHighAccuracy(timeoutMs: Long): Location? {
        val cts = CancellationTokenSource()
        val task = fused.getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY, cts.token)

        val latch = CountDownLatch(1)
        val ref = AtomicReference<Location?>()

        task.addOnSuccessListener(bg) { loc ->
            ref.set(loc); latch.countDown()
        }.addOnFailureListener(bg) { e ->
            Log.w(TAG, "getCurrentLocation failure: ${e.message}")
            latch.countDown()
        }

        val ok = latch.await(timeoutMs, TimeUnit.MILLISECONDS)
        if (!ok) {
            Log.w(TAG, "getCurrentLocation timeout (${timeoutMs}ms). Cancelando token…")
            cts.cancel()
        }
        return ref.get()
    }

    private fun Location.toSample() = LocationSample(
        lat = latitude,
        lng = longitude,
        accuracy = accuracy,
        timestampMillis = time,
        speedMps = if (hasSpeed()) speed else null,
        bearing = if (hasBearing()) bearing else null
    )
}
