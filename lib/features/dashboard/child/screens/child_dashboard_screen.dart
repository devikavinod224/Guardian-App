import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../../auth/screens/role_selection_screen.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../features/focus/screens/focus_mode_screen.dart';
import '../services/child_monitoring_service.dart';

class ChildDashboardScreen extends StatefulWidget {
  const ChildDashboardScreen({super.key});

  @override
  State<ChildDashboardScreen> createState() => _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends State<ChildDashboardScreen> {
  @override
  void initState() {
    super.initState();
    ChildMonitoringService().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Protection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Clear prefs manually as we didn't inject AuthService fully, or use Provider if available
              // Since AuthService is at root, we can use it.
              await context.read<AuthService>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.red.shade50],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'This device is protected',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Parent monitoring is active.'),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  // Get IDs
                  final prefs = await SharedPreferences.getInstance();
                  final childId = prefs.getString('child_id');
                  final parentUid = prefs.getString('parent_uid');

                  if (childId != null && parentUid != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FocusModeScreen(
                          childId: childId,
                          parentUid: parentUid,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.psychology),
                label: const Text('Start Focus Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    const platform = MethodChannel(
                      'com.anand.guardian/settings',
                    );
                    await platform.invokeMethod('requestDeviceAdmin');
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                icon: const Icon(Icons.security),
                label: const Text('Enable Uninstall Protection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: GestureDetector(
          onLongPress: () => _sendSOS(context),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.sos, color: Colors.white, size: 36),
          ),
        ),
      ),
      bottomNavigationBar: const BottomAppBar(
        height: 60,
        color: Colors.white,
        child: Center(
          child: Text(
            "Long Press Red Button for SOS",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Future<void> _sendSOS(BuildContext context) async {
    HapticFeedback.heavyImpact(); // Vibrate

    // Get IDs
    final prefs = await SharedPreferences.getInstance();
    final parentUid = prefs.getString('parent_uid');
    final childId = prefs.getString('child_id');

    if (parentUid != null && childId != null) {
      // Get Location (Best Effort)
      GeoPoint? location;
      try {
        final pos = await Geolocator.getCurrentPosition();
        location = GeoPoint(pos.latitude, pos.longitude);
      } catch (e) {
        debugPrint("SOS Location Error: $e");
      }

      // Upload Alert
      await FirebaseFirestore.instance
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(childId)
          .collection('alerts')
          .add({
            'type': 'SOS',
            'timestamp': FieldValue.serverTimestamp(),
            'parentId': parentUid, // For CollectionGroup query
            'message': 'Emergency SOS triggered by child!',
            if (location != null) 'location': location,
          });

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("SOS Sent!"),
            content: const Text(
              "Parents have been notified with your location.",
            ),
            backgroundColor: Colors.red.shade50,
            icon: const Icon(Icons.notifications_active, color: Colors.red),
          ),
        );
      }
    }
  }
}
