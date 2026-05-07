package com.fragsaddicts.caisse

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var pendingImportResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILE_IMPORT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickJsonBackup" -> openJsonBackupPicker(result)
                    "saveJsonBackup" -> saveJsonBackup(
                        call.argument("name"),
                        call.argument("content"),
                        result
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun saveJsonBackup(name: String?, content: String?, result: MethodChannel.Result) {
        val json = content
        if (json.isNullOrBlank()) {
            result.error("empty_export", "Le contenu de l'export est vide.", null)
            return
        }

        val fileName = safeJsonFileName(name)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                    put(MediaStore.MediaColumns.MIME_TYPE, "application/json")
                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }
                val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                if (uri == null) {
                    result.error("export_failed", "Impossible de créer le fichier dans Downloads.", null)
                    return
                }

                try {
                    contentResolver.openOutputStream(uri)?.use { output ->
                        output.write(json.toByteArray(Charsets.UTF_8))
                    } ?: throw IllegalStateException("Flux d'écriture indisponible")

                    values.clear()
                    values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                    contentResolver.update(uri, values, null, null)
                    result.success(mapOf("name" to fileName, "uri" to uri.toString()))
                } catch (error: Exception) {
                    contentResolver.delete(uri, null, null)
                    result.error("export_failed", "Impossible d'écrire le fichier dans Downloads.", error.message)
                }
            } else {
                val downloads = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                if (!downloads.exists()) downloads.mkdirs()
                val file = File(downloads, fileName)
                file.writeText(json, Charsets.UTF_8)
                result.success(mapOf("name" to fileName, "path" to file.absolutePath))
            }
        } catch (error: Exception) {
            result.error("export_failed", "Impossible d'enregistrer l'export dans Downloads.", error.message)
        }
    }

    private fun safeJsonFileName(name: String?): String {
        val baseName = name
            ?.trim()
            ?.replace(Regex("[^A-Za-z0-9._-]+"), "-")
            ?.trim('-', '.', '_')
            ?.takeIf { it.isNotEmpty() }
            ?: "frags-addicts-export.json"
        return if (baseName.endsWith(".json", ignoreCase = true)) baseName else "$baseName.json"
    }

    private fun openJsonBackupPicker(result: MethodChannel.Result) {
        if (pendingImportResult != null) {
            result.error("picker_already_open", "Un sélecteur de fichier est déjà ouvert.", null)
            return
        }
        pendingImportResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/json"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("application/json", "text/json", "text/plain", "application/octet-stream")
            )
        }

        try {
            startActivityForResult(intent, PICK_JSON_BACKUP_REQUEST)
        } catch (error: Exception) {
            pendingImportResult = null
            result.error("picker_unavailable", "Impossible d'ouvrir le sélecteur de fichier.", error.message)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_JSON_BACKUP_REQUEST) return

        val result = pendingImportResult ?: return
        pendingImportResult = null

        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        val uri = data?.data
        if (uri == null) {
            result.error("file_missing", "Aucun fichier sélectionné.", null)
            return
        }

        try {
            val content = contentResolver.openInputStream(uri)
                ?.bufferedReader(Charsets.UTF_8)
                ?.use { it.readText() }
            if (content == null) {
                result.error("file_unreadable", "Impossible de lire le fichier sélectionné.", null)
                return
            }
            result.success(
                mapOf(
                    "name" to (displayName(uri) ?: "sauvegarde.json"),
                    "content" to content
                )
            )
        } catch (error: Exception) {
            result.error("file_unreadable", "Impossible de lire le fichier sélectionné.", error.message)
        }
    }

    private fun displayName(uri: Uri): String? {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) return cursor.getString(index)
        }
        return uri.lastPathSegment
    }

    companion object {
        private const val FILE_IMPORT_CHANNEL = "frags_addicts/file_import"
        private const val PICK_JSON_BACKUP_REQUEST = 7301
    }
}
