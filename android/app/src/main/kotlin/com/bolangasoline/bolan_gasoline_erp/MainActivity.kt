package com.bolangasoline.bolan_gasoline_erp

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentAdapter
import android.print.PrintDocumentInfo
import android.print.PrintManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "bolan_gasoline_erp/native_actions"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sharePdf" -> {
                        val filename = call.argument<String>("filename") ?: "report.pdf"
                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes == null) {
                            result.error("NO_BYTES", "PDF bytes missing", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val outFile = File(cacheDir, filename)
                            FileOutputStream(outFile).use { it.write(bytes) }
                            val uri = FileProvider.getUriForFile(
                                this,
                                "$packageName.fileprovider",
                                outFile
                            )
                            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                                type = "application/pdf"
                                putExtra(Intent.EXTRA_STREAM, uri)
                                putExtra(Intent.EXTRA_SUBJECT, filename)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(Intent.createChooser(shareIntent, "Share PDF Report"))
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SHARE_ERR", e.message, null)
                        }
                    }

                    "printPdf" -> {
                        val filename = call.argument<String>("filename") ?: "report.pdf"
                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes == null) {
                            result.error("NO_BYTES", "PDF bytes missing", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val outFile = File(cacheDir, filename)
                            FileOutputStream(outFile).use { it.write(bytes) }
                            val printManager =
                                getSystemService(Context.PRINT_SERVICE) as PrintManager
                            printManager.print(
                                filename,
                                PdfFilePrintAdapter(outFile, filename),
                                null
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("PRINT_ERR", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}

private class PdfFilePrintAdapter(
    private val file: File,
    private val jobName: String
) : PrintDocumentAdapter() {
    override fun onLayout(
        oldAttributes: PrintAttributes?,
        newAttributes: PrintAttributes?,
        cancellationSignal: CancellationSignal?,
        callback: LayoutResultCallback,
        extras: Bundle?
    ) {
        if (cancellationSignal?.isCanceled == true) {
            callback.onLayoutCancelled()
            return
        }
        val info = PrintDocumentInfo.Builder(jobName)
            .setContentType(PrintDocumentInfo.CONTENT_TYPE_DOCUMENT)
            .setPageCount(PrintDocumentInfo.PAGE_COUNT_UNKNOWN)
            .build()
        callback.onLayoutFinished(info, true)
    }

    override fun onWrite(
        pages: Array<out PageRange>?,
        destination: ParcelFileDescriptor?,
        cancellationSignal: CancellationSignal?,
        callback: WriteResultCallback
    ) {
        if (cancellationSignal?.isCanceled == true || destination == null) {
            callback.onWriteCancelled()
            return
        }
        try {
            FileInputStream(file).use { input ->
                FileOutputStream(destination.fileDescriptor).use { output ->
                    input.copyTo(output)
                }
            }
            callback.onWriteFinished(arrayOf(PageRange.ALL_PAGES))
        } catch (e: Exception) {
            callback.onWriteFailed(e.message)
        }
    }
}
