package com.example.geo_tracker.core

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

/**
 * Helper de permissões de localização (FINE/COARSE).
 *
 * Observação: este helper apenas dispara o request e chama o callback.
 * O app deve chamar [checkFineCoarse] depois do diálogo do sistema para confirmar o estado final.
 */
class PermissionsHelper {

    data class Status(
        val fineGranted: Boolean,
        val coarseGranted: Boolean,
        val shouldShowRationale: Boolean
    )

    /** Verdadeiro se FINE ou COARSE estiverem concedidas. */
    fun hasFineOrCoarse(ctx: Context): Boolean {
        val fine = isGranted(ctx, Manifest.permission.ACCESS_FINE_LOCATION)
        val coarse = isGranted(ctx, Manifest.permission.ACCESS_COARSE_LOCATION)
        return fine || coarse
    }

    /** Retorna o status atual das permissões e se devemos mostrar rationale. */
    fun checkFineCoarse(ctx: Context): Status {
        val fine = isGranted(ctx, Manifest.permission.ACCESS_FINE_LOCATION)
        val coarse = isGranted(ctx, Manifest.permission.ACCESS_COARSE_LOCATION)
        val act = ctx as? Activity
        val rationale = act?.let {
            ActivityCompat.shouldShowRequestPermissionRationale(it, Manifest.permission.ACCESS_FINE_LOCATION) ||
            ActivityCompat.shouldShowRequestPermissionRationale(it, Manifest.permission.ACCESS_COARSE_LOCATION)
        } ?: false
        return Status(fineGranted = fine, coarseGranted = coarse, shouldShowRationale = rationale)
    }

    /**
     * Abre o diálogo do sistema para FINE/COARSE.
     * O callback é chamado imediatamente como `true` (request enviado).
     * Revalide depois com [checkFineCoarse].
     */
    fun requestFineCoarse(activity: Activity, onRequestSent: (Boolean) -> Unit) {
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ),
            REQ_CODE_LOCATION
        )
        onRequestSent(true)
    }

    private fun isGranted(ctx: Context, permission: String): Boolean =
        ContextCompat.checkSelfPermission(ctx, permission) == PackageManager.PERMISSION_GRANTED

    companion object {
        private const val REQ_CODE_LOCATION = 1001
    }
}
