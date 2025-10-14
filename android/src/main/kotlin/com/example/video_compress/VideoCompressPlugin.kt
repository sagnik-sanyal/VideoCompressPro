package com.example.video_compress

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.otaliastudios.transcoder.Transcoder
import com.otaliastudios.transcoder.TranscoderListener
import com.otaliastudios.transcoder.source.TrimDataSource
import com.otaliastudios.transcoder.source.UriDataSource
import com.otaliastudios.transcoder.strategy.DefaultAudioStrategy
import com.otaliastudios.transcoder.strategy.DefaultVideoStrategy
import com.otaliastudios.transcoder.strategy.RemoveTrackStrategy
import com.otaliastudios.transcoder.strategy.TrackStrategy
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import com.otaliastudios.transcoder.internal.utils.Logger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.io.File
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.Future
import androidx.core.net.toUri

/**
 * VideoCompressPlugin - Fixed for multi-isolate support
 */
class VideoCompressPlugin : MethodCallHandler, FlutterPlugin {
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private val TAG = "VideoCompressPlugin"
    private val LOG = Logger(TAG)
    private var transcodeFuture: Future<Void>? = null
    private val channelName = "video_compress"

    // Add main thread handler for cross-isolate communication
    private val mainHandler = Handler(Looper.getMainLooper())

    // Track initialization state
    private var isInitialized = false

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        // CRITICAL FIX 1: Check initialization before accessing context
        if (!isInitialized) {
            Log.w(TAG, "VideoCompress plugin not initialized")
            result.error("NOT_INITIALIZED", "Plugin not initialized. Please ensure the plugin is properly attached.", null)
            return
        }

        // CRITICAL FIX 2: Use local reference to prevent null pointer issues
        val appContext = context.applicationContext

        when (call.method) {
            "getByteThumbnail" -> {
                val path = call.argument<String>("path")
                val quality = call.argument<Int>("quality")!!
                val position = call.argument<Int>("position")!!
                ThumbnailUtility(channelName).getByteThumbnail(path!!, quality, position.toLong(), result)
            }
            "getFileThumbnail" -> {
                val path = call.argument<String>("path")
                val quality = call.argument<Int>("quality")!!
                val position = call.argument<Int>("position")!!
                ThumbnailUtility(channelName).getFileThumbnail(appContext, path!!, quality,
                    position.toLong(), result)
            }
            "getMediaInfo" -> {
                val path = call.argument<String>("path")
                result.success(Utility(channelName).getMediaInfoJson(appContext, path!!).toString())
            }
            "deleteAllCache" -> {
                result.success(Utility(channelName).deleteAllCache(appContext, result))
            }
            "setLogLevel" -> {
                val logLevel = call.argument<Int>("logLevel")!!
                Logger.setLogLevel(logLevel)
                result.success(true)
            }
            "cancelCompression" -> {
                transcodeFuture?.cancel(true)
                result.success(false)
            }
            "compressVideo" -> {
                handleCompressVideo(call, result, appContext)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    // CRITICAL FIX 3: Extract compression logic to separate method for better isolate handling
    private fun handleCompressVideo(call: MethodCall, result: MethodChannel.Result, appContext: Context) {
        try {
            val path = call.argument<String>("path")!!
            val quality = call.argument<Int>("quality")!!
            val deleteOrigin = call.argument<Boolean>("deleteOrigin")!!
            val startTime = call.argument<Int>("startTime")
            val duration = call.argument<Int>("duration")
            val includeAudio = call.argument<Boolean>("includeAudio") ?: true
            val frameRate = call.argument<Int>("frameRate") ?: 30

            val tempDir: String = appContext.getExternalFilesDir("video_compress")!!.absolutePath
            val out = SimpleDateFormat("yyyy-MM-dd hh-mm-ss", Locale.getDefault()).format(Date())
            val destPath: String = tempDir + File.separator + "VID_" + out + path.hashCode() + ".mp4"

            var videoTrackStrategy: TrackStrategy = DefaultVideoStrategy.atMost(340).build()

            when (quality) {
                0 -> {
                    videoTrackStrategy = DefaultVideoStrategy.atMost(720).build()
                }
                1 -> {
                    videoTrackStrategy = DefaultVideoStrategy.atMost(360).build()
                }
                2 -> {
                    videoTrackStrategy = DefaultVideoStrategy.atMost(640).build()
                }
                3 -> {
                    videoTrackStrategy = DefaultVideoStrategy.Builder()
                        .keyFrameInterval(3f)
                        .bitRate(1280 * 720 * 4.toLong())
                        .frameRate(frameRate)
                        .build()
                }
                4 -> {
                    videoTrackStrategy = DefaultVideoStrategy.atMost(480, 640).build()
                }
                5 -> {
                    videoTrackStrategy = DefaultVideoStrategy.atMost(540, 960).build()
                }
                6 -> {
                    videoTrackStrategy = DefaultVideoStrategy.atMost(720, 1280).build()
                }
                7 -> {
                    videoTrackStrategy = DefaultVideoStrategy.atMost(1080, 1920).build()
                }
            }

            val audioTrackStrategy: TrackStrategy = if (includeAudio) {
                val sampleRate = DefaultAudioStrategy.SAMPLE_RATE_AS_INPUT
                val channels = DefaultAudioStrategy.CHANNELS_AS_INPUT

                DefaultAudioStrategy.builder()
                    .channels(channels)
                    .sampleRate(sampleRate)
                    .build()
            } else {
                RemoveTrackStrategy()
            }

            val dataSource = if (startTime != null || duration != null) {
                val source = UriDataSource(appContext, path.toUri())
                TrimDataSource(source, (1000 * 1000 * (startTime ?: 0)).toLong(), (1000 * 1000 * (duration ?: 0)).toLong())
            } else {
                UriDataSource(appContext, path.toUri())
            }

            transcodeFuture = Transcoder.into(destPath)
                .addDataSource(dataSource)
                .setAudioTrackStrategy(audioTrackStrategy)
                .setVideoTrackStrategy(videoTrackStrategy)
                .setListener(object : TranscoderListener {
                    override fun onTranscodeProgress(progress: Double) {
                        // CRITICAL FIX 4: Use main handler to ensure thread safety
                        mainHandler.post {
                            try {
                                if (isInitialized) {
                                    methodChannel.invokeMethod("updateProgress", progress * 100.00)
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "Error sending progress update", e)
                            }
                        }
                    }

                    override fun onTranscodeCompleted(successCode: Int) {
                        mainHandler.post {
                            try {
                                if (isInitialized) {
                                    methodChannel.invokeMethod("updateProgress", 100.00)
                                }
                                val json = Utility(channelName).getMediaInfoJson(appContext, destPath)
                                json.put("isCancel", false)
                                result.success(json.toString())
                                if (deleteOrigin) {
                                    File(path).delete()
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "Error in transcode completion", e)
                                result.error("TRANSCODE_ERROR", "Transcode completed but error in callback: ${e.message}", null)
                            }
                        }
                    }

                    override fun onTranscodeCanceled() {
                        mainHandler.post {
                            result.success(null)
                        }
                    }

                    override fun onTranscodeFailed(exception: Throwable) {
                        mainHandler.post {
                            result.error("TRANSCODE_FAILED", "Transcoding failed: ${exception.message}", null)
                        }
                    }
                }).transcode()
        } catch (e: Exception) {
            Log.e(TAG, "Error starting compression", e)
            result.error("COMPRESSION_ERROR", "Failed to start compression: ${e.message}", null)
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // CRITICAL FIX 5: Initialize in onAttachedToEngine, not during method calls
        init(binding.applicationContext, binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // CRITICAL FIX 6: Proper cleanup
        isInitialized = false
        transcodeFuture?.cancel(true)
        transcodeFuture = null
        methodChannel.setMethodCallHandler(null)
    }

    private fun init(ctx: Context, messenger: BinaryMessenger) {
        // CRITICAL FIX 7: Use application context to prevent memory leaks
        context = ctx.applicationContext
        methodChannel = MethodChannel(messenger, channelName)
        methodChannel.setMethodCallHandler(this)
        isInitialized = true
        Log.d(TAG, "VideoCompress plugin initialized successfully")
    }

    companion object {
        private const val TAG = "video_compress"
    }
}