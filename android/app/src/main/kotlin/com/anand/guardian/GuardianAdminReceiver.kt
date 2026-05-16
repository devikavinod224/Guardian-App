package com.anand.guardian // Note: Package might need adjustment based on MainActivity, checking file list next.
// Wait, listing showed 'com/anand/guardian'. Let me check MainActivity first to be sure of package name.
// I will pause writing this file until I read MainActivity.kt
import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast

class GuardianAdminReceiver : DeviceAdminReceiver() {
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Toast.makeText(context, "Guardian Protection Enabled", Toast.LENGTH_SHORT).show()
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Toast.makeText(context, "Guardian Protection Disabled", Toast.LENGTH_SHORT).show()
    }
}
