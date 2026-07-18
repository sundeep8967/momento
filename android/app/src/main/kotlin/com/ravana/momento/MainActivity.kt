package com.ravana.momento

import android.app.WallpaperManager
import android.graphics.BitmapFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.URL
import kotlin.concurrent.thread

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.setlog.momento/wallpaper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setWallpaper") {
                val imageUrl = call.argument<String>("url")
                if (imageUrl != null) {
                    setWallpaperFromUrl(imageUrl, result)
                } else {
                    result.error("INVALID_URL", "Image URL is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun setWallpaperFromUrl(imageUrl: String, result: MethodChannel.Result) {
        thread {
            try {
                val url = URL(imageUrl)
                val connection = url.openConnection()
                connection.doInput = true
                connection.connect()
                val inputStream = connection.inputStream
                val bitmap = BitmapFactory.decodeStream(inputStream)
                
                val wallpaperManager = WallpaperManager.getInstance(applicationContext)
                wallpaperManager.setBitmap(bitmap)
                
                runOnUiThread {
                    result.success(true)
                }
            } catch (e: Exception) {
                e.printStackTrace()
                runOnUiThread {
                    result.error("WALLPAPER_ERROR", e.localizedMessage, null)
                }
            }
        }
    }
}
