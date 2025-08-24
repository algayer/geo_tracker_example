package com.example.geo_tracker

import android.app.Activity
import android.content.Context
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.example.geo_tracker.core.GeoUtils
import com.example.geo_tracker.core.LocationProvider
import com.example.geo_tracker.core.PermissionsHelper
import com.example.geo_tracker.model.LocationSample
import com.example.geo_tracker.providers.FusedLocationProvider
import kotlinx.coroutines.*

/**
 * Plugin Android do GeoTracker.
 *
 * Métodos expostos via MethodChannel "geo_tracker":
 * - getPlatformVersion
 * - checkPermissions / requestPermissions
 * - getLastKnownOrCurrent
 * - computeDistanceMeters
 * - computeDistanceEta
 * - computeDistancesEta
 */
class GeoTrackerPlugin :
  FlutterPlugin,
  MethodCallHandler,
  ActivityAware {

  private var appContext: Context? = null
  private var activity: Activity? = null
  private var channel: MethodChannel? = null

  private lateinit var permissionsHelper: PermissionsHelper
  private var locationProvider: LocationProvider? = null

  private val pluginJob = SupervisorJob()
  private val pluginScope = CoroutineScope(Dispatchers.Default + pluginJob)

  // FlutterPlugin
  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    appContext = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, CHANNEL_METHOD).also { it.setMethodCallHandler(this) }
    permissionsHelper = PermissionsHelper()
    locationProvider = FusedLocationProvider(binding.applicationContext)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel?.setMethodCallHandler(null)
    channel = null
    locationProvider = null
    appContext = null
    pluginScope.cancel()
  }

  // ActivityAware
  override fun onAttachedToActivity(binding: ActivityPluginBinding) { activity = binding.activity }
  override fun onDetachedFromActivityForConfigChanges() { activity = null }
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { activity = binding.activity }
  override fun onDetachedFromActivity() { activity = null }

  // Channel handler
  override fun onMethodCall(call: MethodCall, result: Result) {
    try {
      when (call.method) {
        "getPlatformVersion" -> {
          result.success("Android ${Build.VERSION.RELEASE}")
        }

        "checkPermissions" -> {
          val ctx = activity ?: appContext ?: return result.err("NO_CONTEXT", "Contexto indisponível.")
          val status = permissionsHelper.checkFineCoarse(ctx)
          result.success(mapOf("fine" to status.fineGranted, "coarse" to status.coarseGranted, "rationale" to status.shouldShowRationale))
        }

        "requestPermissions" -> {
          val act = activity ?: return result.err("NO_ACTIVITY", "Activity ausente para requisitar permissões.")
          permissionsHelper.requestFineCoarse(act) { requested -> result.success(mapOf("requested" to requested)) }
        }

        "getLastKnownOrCurrent" -> {
          val ctx = appContext ?: return result.err("NO_CONTEXT", "Contexto indisponível.")
          if (!permissionsHelper.hasFineOrCoarse(activity ?: ctx)) {
            return result.error("NO_PERMISSION", "Permissões de localização não concedidas.", mapOf("required" to listOf("ACCESS_FINE_LOCATION", "ACCESS_COARSE_LOCATION")))
          }
          val timeoutMs = (call.argument<Number>("timeoutMs") ?: DEFAULT_TIMEOUT_MS).toLong()
          val provider = locationProvider ?: return result.err("NO_PROVIDER", "LocationProvider indisponível.")

          pluginScope.launch {
            try {
              val sample = provider.getLastKnownOrCurrent(timeoutMs)
              withContext(Dispatchers.Main) { result.success(sample.toMap()) }
            } catch (se: SecurityException) {
              withContext(Dispatchers.Main) { result.error("NO_PERMISSION", se.message ?: "Sem permissão de localização.", null) }
            } catch (ise: IllegalStateException) {
              val msg = ise.message.orEmpty()
              withContext(Dispatchers.Main) {
                when {
                  msg == "LOCATION_SETTINGS_DISABLED" -> result.error("LOCATION_SETTINGS_DISABLED", "A localização do dispositivo está desativada ou insuficiente.", null)
                  msg.startsWith("TIMEOUT_")         -> result.error("TIMEOUT", "Tempo excedido ao tentar obter a localização.", null)
                  else                                -> result.error("INTERNAL_ERROR", msg.ifBlank { "Erro interno." }, ise.stackTraceToString())
                }
              }
            } catch (t: Throwable) {
              withContext(Dispatchers.Main) { result.error("INTERNAL_ERROR", t.message ?: "Erro interno.", t.stackTraceToString()) }
            }
          }
        }

        "computeDistanceMeters" -> {
          val from = call.argument<Map<String, Any?>>("from") ?: return result.badArgs("Parâmetro 'from' é obrigatório.")
          val to   = call.argument<Map<String, Any?>>("to")   ?: return result.badArgs("Parâmetro 'to' é obrigatório.")

          val fromLat = (from["lat"] as? Number)?.toDouble() ?: return result.badArgs("'from.lat' inválido.")
          val fromLng = (from["lng"] as? Number)?.toDouble() ?: return result.badArgs("'from.lng' inválido.")
          val toLat   = (to["lat"]   as? Number)?.toDouble() ?: return result.badArgs("'to.lat' inválido.")
          val toLng   = (to["lng"]   as? Number)?.toDouble() ?: return result.badArgs("'to.lng' inválido.")

          val meters = GeoUtils.haversineMeters(fromLat, fromLng, toLat, toLng)
          result.success(mapOf("meters" to meters))
        }

        // distância + ETA com perfil de velocidade (ou velocidade do device)
        "computeDistanceEta" -> {
          pluginScope.launch {
            try {
              val from = call.argument<Map<String, Any?>>("from") ?: return@launch withMain { result.badArgs("Parâmetro 'from' é obrigatório.") }
              val to   = call.argument<Map<String, Any?>>("to")   ?: return@launch withMain { result.badArgs("Parâmetro 'to' é obrigatório.") }

              val profile     = call.argument<String>("profile") ?: "drive_city"
              val customSpeed = call.argument<Number>("customSpeedMps")?.toDouble()
              val timeoutMs   = (call.argument<Number>("timeoutMs") ?: DEFAULT_TIMEOUT_MS).toLong()

              val fromLat = (from["lat"] as? Number)?.toDouble() ?: return@launch withMain { result.badArgs("'from.lat' inválido.") }
              val fromLng = (from["lng"] as? Number)?.toDouble() ?: return@launch withMain { result.badArgs("'from.lng' inválido.") }
              val toLat   = (to["lat"]   as? Number)?.toDouble() ?: return@launch withMain { result.badArgs("'to.lat' inválido.") }
              val toLng   = (to["lng"]   as? Number)?.toDouble() ?: return@launch withMain { result.badArgs("'to.lng' inválido.") }

              val (speedMps, source) = resolveSpeedMps(profile, customSpeed, timeoutMs)
              val meters  = GeoUtils.haversineMeters(fromLat, fromLng, toLat, toLng)
              val etaSec  = GeoUtils.etaSeconds(meters, speedMps)

              withMain { result.success(mapOf("meters" to meters, "etaSeconds" to etaSec, "speedMps" to speedMps, "speedSource" to source)) }
            } catch (t: Throwable) {
              withMain { result.error("INTERNAL_ERROR", t.message ?: "Erro interno.", t.stackTraceToString()) }
            }
          }
        }

        // lote de destinos: usa mesma velocidade para todos
        "computeDistancesEta" -> {
          pluginScope.launch {
            try {
              val from = call.argument<Map<String, Any?>>("from") ?: return@launch withMain { result.badArgs("Parâmetro 'from' é obrigatório.") }
              @Suppress("UNCHECKED_CAST")
              val toAny = call.argument<List<Any?>>("to") ?: return@launch withMain { result.badArgs("Parâmetro 'to' (lista) é obrigatório.") }

              val profile     = call.argument<String>("profile") ?: "drive_city"
              val customSpeed = call.argument<Number>("customSpeedMps")?.toDouble()
              val timeoutMs   = (call.argument<Number>("timeoutMs") ?: DEFAULT_TIMEOUT_MS).toLong()

              val fromLat = (from["lat"] as? Number)?.toDouble() ?: return@launch withMain { result.badArgs("'from.lat' inválido.") }
              val fromLng = (from["lng"] as? Number)?.toDouble() ?: return@launch withMain { result.badArgs("'from.lng' inválido.") }

              val (speedMps, source) = resolveSpeedMps(profile, customSpeed, timeoutMs)

              val rows = ArrayList<Map<String, Any?>>(toAny.size)
              for ((idx, item) in toAny.withIndex()) {
                val mp  = item as? Map<*, *> ?: return@launch withMain { result.badArgs("'to[$idx]' inválido.") }
                val lat = (mp["lat"] as? Number)?.toDouble() ?: return@launch withMain { result.badArgs("'to[$idx].lat' inválido.") }
                val lng = (mp["lng"] as? Number)?.toDouble() ?: return@launch withMain { result.badArgs("'to[$idx].lng' inválido.") }
                val id  = mp["id"]?.toString()

                val m  = GeoUtils.haversineMeters(fromLat, fromLng, lat, lng)
                val et = GeoUtils.etaSeconds(m, speedMps)

                rows.add(mapOf("index" to idx, "id" to id, "lat" to lat, "lng" to lng, "meters" to m, "etaSeconds" to et))
              }

              val payload: Map<String, Any?> = mapOf(
                "from"        to mapOf("lat" to fromLat, "lng" to fromLng),
                "profile"     to profile,
                "speedMps"    to speedMps,
                "speedSource" to source,
                "rows"        to rows,
              )
              withMain { result.success(payload) }
            } catch (t: Throwable) {
              withMain { result.error("INTERNAL_ERROR", t.message ?: "Erro interno.", t.stackTraceToString()) }
            }
          }
        }

        else -> result.notImplemented()
      }
    } catch (t: Throwable) {
      result.error("INTERNAL_ERROR", t.message ?: "Erro interno.", t.stackTraceToString())
    }
  }

  // Helpers

  private suspend fun withMain(block: () -> Unit) = withContext(Dispatchers.Main) { block() }

  private fun LocationSample.toMap(): Map<String, Any?> = mapOf(
    "lat" to lat, "lng" to lng, "accuracy" to accuracy, "ts" to timestampMillis, "speed" to speedMps, "bearing" to bearing
  )

  private fun Result.badArgs(message: String) { error("BAD_ARGS", message, null) }
  private fun Result.err(code: String, message: String) { error(code, message, null) }

  /** Seleciona velocidade (m/s) conforme perfil; pode ler velocidade do device. */
  private fun resolveSpeedMps(profile: String, customSpeed: Double?, timeoutMs: Long): Pair<Double, String> =
    when (profile.lowercase()) {
      "walk", "walking", "pedestrian" -> WALK_MPS to "profile:walk"
      "bike", "bicycle", "cycling"    -> BIKE_MPS to "profile:bike"
      "drive_city", "car_city", "urban" -> DRIVE_CITY_MPS to "profile:drive_city"
      "drive_fast", "highway"         -> DRIVE_FAST_MPS to "profile:drive_fast"
      "custom" -> {
        val v = customSpeed ?: 0.0
        val s = if (v > 0.0) v else DRIVE_CITY_MPS
        s to if (v > 0.0) "custom" else "fallback:drive_city"
      }
      "current", "device" -> {
        val s = try { locationProvider?.getLastKnownOrCurrent(timeoutMs)?.speedMps?.toDouble() ?: 0.0 } catch (_: Throwable) { 0.0 }
        val use = if (s > 0.5) s else DRIVE_CITY_MPS
        use to if (use == DRIVE_CITY_MPS) "fallback:drive_city" else "location:speed"
      }
      else -> DRIVE_CITY_MPS to "fallback:drive_city"
    }

  companion object {
    private const val CHANNEL_METHOD = "geo_tracker"
    private const val DEFAULT_TIMEOUT_MS = 3000L
    private const val WALK_MPS: Double = 1.39       // ~5 km/h
    private const val BIKE_MPS: Double = 4.17       // ~15 km/h
    private const val DRIVE_CITY_MPS: Double = 11.11 // ~40 km/h
    private const val DRIVE_FAST_MPS: Double = 22.22 // ~80 km/h
  }
}
