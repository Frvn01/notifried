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
			when (call.method) {
				"getInitialScheduleId" -> {
					val id = intent?.getStringExtra("schedule_id")
					result.success(id)
				}
				"getInitialTargetTab" -> {
					val tab = intent?.getStringExtra("target_tab")
					result.success(tab)
				}
				else -> result.notImplemented()
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
			} catch (_: Exception) {}
		}
		val targetTab = intent.getStringExtra("target_tab")
		if (targetTab != null) {
			try {
				flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
					MethodChannel(messenger, CHANNEL).invokeMethod("onNavigateTab", targetTab)
				}
			} catch (_: Exception) {}
		}
	}
}
