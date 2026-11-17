package com.example.app

import android.content.ContentValues
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    private val galleryChannel = "com.example.app/gallery"
    private val splashChannel = "com.example.app/splash"
    private val windowFocusChannel = "com.example.app/window_focus"

    @Volatile
    private var keepSplashOnScreen = true
    private val mainHandler = Handler(Looper.getMainLooper())
    private val fallbackReleaseSplash = Runnable { releaseSplash() }
    private val pendingFocusWaiters = mutableListOf<Pair<MethodChannel.Result, Runnable>>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, windowFocusChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "waitForFocus") {
                    if (hasWindowFocus()) {
                        result.success(true)
                        return@setMethodCallHandler
                    }
                    lateinit var entry: Pair<MethodChannel.Result, Runnable>
                    val timeout = Runnable {
                        if (pendingFocusWaiters.remove(entry)) {
                            try {
                                result.success(false)
                            } catch (_: IllegalStateException) {}
                        }
                    }
                    entry = Pair(result, timeout)
                    pendingFocusWaiters.add(entry)
                    mainHandler.postDelayed(timeout, 500L)
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, splashChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "hide") {
                    releaseSplash()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, galleryChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveImage") {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName")
                        ?: "mio_qr_${System.currentTimeMillis()}.png"
                    if (bytes == null || bytes.isEmpty()) {
                        result.error("INVALID_ARGS", "Empty image bytes", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val savedPath = savePngToGallery(bytes, fileName)
                        result.success(savedPath)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun savePngToGallery(bytes: ByteArray, fileName: String): String {
        val resolver = applicationContext.contentResolver
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                put(
                    MediaStore.Images.Media.RELATIVE_PATH,
                    "${Environment.DIRECTORY_PICTURES}/Mio"
                )
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Cannot create MediaStore entry")
            resolver.openOutputStream(uri)?.use { out ->
                out.write(bytes)
                out.flush()
            } ?: throw IllegalStateException("Cannot open output stream")
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri.toString()
        } else {
            @Suppress("DEPRECATION")
            val dir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
                "Mio"
            )
            if (!dir.exists()) dir.mkdirs()
            val file = File(dir, fileName)
            FileOutputStream(file).use { out ->
                out.write(bytes)
                out.flush()
            }
            @Suppress("DEPRECATION")
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DATA, file.absolutePath)
                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            }
            resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            return file.absolutePath
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        splashScreen.setKeepOnScreenCondition { keepSplashOnScreen }
        super.onCreate(savedInstanceState)

        // Trên Android < 12, Flutter switch sang NormalTheme trong super.onCreate;
        // giữ launch_background làm nền cho tới khi Dart báo hide() để tránh chớp trắng.
        if (keepSplashOnScreen && Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            window.setBackgroundDrawableResource(R.drawable.launch_background)
        }

        mainHandler.postDelayed(fallbackReleaseSplash, 12000L)
        setHighRefreshRate()
    }

    private fun releaseSplash() {
        mainHandler.removeCallbacks(fallbackReleaseSplash)
        if (!keepSplashOnScreen) return
        keepSplashOnScreen = false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            window.setBackgroundDrawableResource(android.R.color.white)
        }
        window?.decorView?.postInvalidate()
    }

    override fun onDestroy() {
        mainHandler.removeCallbacks(fallbackReleaseSplash)
        flushFocusWaiters(false)
        super.onDestroy()
    }

    override fun onResume() {
        super.onResume()
        setHighRefreshRate()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            setHighRefreshRate()
            flushFocusWaiters(true)
        }
    }

    private fun flushFocusWaiters(focused: Boolean) {
        if (pendingFocusWaiters.isEmpty()) return
        val copy = pendingFocusWaiters.toList()
        pendingFocusWaiters.clear()
        for ((res, timeout) in copy) {
            mainHandler.removeCallbacks(timeout)
            try {
                res.success(focused)
            } catch (_: IllegalStateException) {}
        }
    }

    private fun setHighRefreshRate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val currentDisplay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                display
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay
            }
            val modes = currentDisplay?.supportedModes ?: return
            val currentMode = currentDisplay.mode
            val highestMode = modes
                .filter {
                    it.physicalWidth == currentMode.physicalWidth &&
                        it.physicalHeight == currentMode.physicalHeight
                }
                .maxByOrNull { it.refreshRate }
                ?: modes.maxByOrNull { it.refreshRate }

            highestMode?.let {
                val layoutParams = window.attributes
                if (layoutParams.preferredDisplayModeId != it.modeId ||
                    layoutParams.preferredRefreshRate != it.refreshRate
                ) {
                    layoutParams.preferredDisplayModeId = it.modeId
                    layoutParams.preferredRefreshRate = it.refreshRate
                    window.attributes = layoutParams
                }
            }
        }
    }
}
