import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockingScreen extends StatefulWidget {
  const BlockingScreen({super.key});
  @override
  State<BlockingScreen> createState() => _BlockingScreenState();
}

class _BlockingScreenState extends State<BlockingScreen> {
  String? _blockedPackage;
  String? _childName;
  String? _blockingReason;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final pkg = prefs.getString('current_blocked_app');
    final reason = prefs.getString('blocking_reason');

    // Fetch Child Name
    String? name;
    final user = FirebaseAuth.instance.currentUser;
    final childId = prefs.getString('child_id');
    if (user != null && childId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('children')
          .doc(childId)
          .get();
      name = doc.data()?['name'];
    }

    setState(() {
      _blockedPackage = pkg;
      _childName = name;
      _blockingReason = reason;
    });
  }

  Future<void> _askPermission() async {
    if (_blockedPackage == null) return;

    final duration = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Ask for Time',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRequestOption(ctx, 15, '15 Minutes'),
            _buildRequestOption(ctx, 30, '30 Minutes'),
            _buildRequestOption(ctx, 60, '1 Hour'),
            _buildRequestOption(ctx, -1, 'Unblock for Today'),
          ],
        ),
      ),
    );

    if (duration != null && mounted) {
      // Send Request
      try {
        final prefs = await SharedPreferences.getInstance();
        final childId = prefs.getString('child_id');
        final user = FirebaseAuth.instance.currentUser;

        if (user != null && childId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('children')
              .doc(childId)
              .collection('requests')
              .add({
                'packageName': _blockedPackage,
                'appName': _blockedPackage,
                'parentId': user.uid,
                'childName': _childName ?? 'Unknown',
                'childId': childId,
                'requestedDuration': duration,
                'status': 'pending',
                'timestamp': FieldValue.serverTimestamp(),
              });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Request sent to parent! 🚀')),
            );
          }
        }
      } catch (e) {
        debugPrint("Request failed: $e");
      }
    }
  }

  Widget _buildRequestOption(BuildContext ctx, int minutes, String label) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white,
        size: 16,
      ),
      onTap: () => Navigator.pop(ctx, minutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBedtime = _blockingReason == 'bedtime';
    final isFocus = _blockingReason == 'focus';
    final isDriving = _blockingReason == 'driving';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: isBedtime
                ? [Colors.deepPurple.shade900, Colors.black]
                : isFocus
                ? [Colors.indigo.shade900, Colors.black]
                : isDriving
                ? [Colors.orange.shade900, Colors.black]
                : [Colors.red.withOpacity(0.2), Colors.black],
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                      isBedtime
                          ? Icons.bedtime_rounded
                          : isFocus
                          ? Icons.psychology
                          : isDriving
                          ? Icons.directions_car_rounded
                          : Icons.lock_outline_rounded,
                      size: 100,
                      color: isBedtime
                          ? Colors.amber
                          : isFocus
                          ? Colors.indigoAccent
                          : isDriving
                          ? Colors.orangeAccent
                          : Colors.redAccent,
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 1000.ms,
                    )
                    .shimmer(
                      color: Colors.white.withOpacity(0.5),
                      duration: 2000.ms,
                    ),
                const SizedBox(height: 32),
                Text(
                  isBedtime
                      ? 'GOOD NIGHT'
                      : isFocus
                      ? 'FOCUS MODE'
                      : isDriving
                      ? 'EYES ON ROAD'
                      : 'ACCESS DENIED',
                  style: GoogleFonts.orbitron(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isBedtime
                        ? Colors.amber
                        : isFocus
                        ? Colors.indigoAccent
                        : isDriving
                        ? Colors.orangeAccent
                        : Colors.redAccent,
                    letterSpacing: 4,
                  ),
                ).animate().fade().slideY(begin: 0.5),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    isBedtime
                        ? 'It is time to sleep. Apps are locked until morning.'
                        : isFocus
                        ? 'You are in a focus session. Keep going to earn your reward!'
                        : isDriving
                        ? 'Movement detected. Apps are locked while driving.'
                        : (_blockedPackage != null
                              ? '$_blockedPackage is locked.'
                              : 'This application is currently locked by your guardian.'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ).animate(delay: 300.ms).fade(),
                const SizedBox(height: 60),
                if (!isBedtime &&
                    !isFocus &&
                    !isDriving) // Only show 'Time's Up' for non-special blocks
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.redAccent.withOpacity(0.1),
                    ),
                    child: Text(
                      'Time\'s Up!',
                      style: GoogleFonts.robotoMono(
                        color: Colors.redAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate(delay: 600.ms).fade().scale(),

                if (isBedtime)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: Text(
                      "Sleep tight! 😴",
                      style: GoogleFonts.handlee(
                        fontSize: 28,
                        color: Colors.white70,
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                if (isFocus)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: Text(
                      "Stay strong! 💪",
                      style: GoogleFonts.handlee(
                        fontSize: 28,
                        color: Colors.white70,
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 40),
                if (!isBedtime && !isFocus && !isDriving) // Standard Block
                  ElevatedButton.icon(
                    onPressed: _askPermission,
                    icon: const Icon(Icons.volunteer_activism),
                    label: const Text('Ask for Permission'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ).animate(delay: 900.ms).fade().slideY(begin: 0.5),

                if (isDriving) // Passenger Override
                  TextButton.icon(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          // Set passenger expiry to 15 mins from now
                          await prefs.setString(
                            'passenger_mode_expiry',
                            DateTime.now()
                                .add(const Duration(minutes: 15))
                                .toIso8601String(),
                          );
                          // Force clear blocking flag locally to allow immediate exit
                          await prefs.setBool('is_blocking_active', false);
                          if (mounted) {
                            // Minimize app / Go Home
                            final intent = AndroidIntent(
                              action: 'android.intent.action.MAIN',
                              category: 'android.intent.category.HOME',
                              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
                            );
                            await intent.launch();
                          }
                        },
                        icon: const Icon(
                          Icons.person_outline,
                          color: Colors.orangeAccent,
                        ),
                        label: const Text(
                          "I'm a Passenger",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 18,
                          ),
                        ),
                      )
                      .animate(delay: 2000.ms)
                      .fadeIn(), // Delayed so driver can't easily click it
              ],
            ),
          ),
        ),
      ),
    );
  }
}
