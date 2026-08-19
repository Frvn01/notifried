package com.example.nowtifried

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
	private val CHANNEL = "nowtifried/widget"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			if (call.method == "getInitialScheduleId") {
				val id = intent?.getStringExtra("schedule_id")
				result.success(id)
			} else {
				result.notImplemented()
			}
		}
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		setIntent(intent)
		val id = intent.getStringExtra("schedule_id")
		if (id != null) {
			try {
				flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
					MethodChannel(messenger, CHANNEL).invokeMethod("onWidgetTap", id)
				}
			} catch (e: Exception) {
				// ignore
			}
		}
	}
}
