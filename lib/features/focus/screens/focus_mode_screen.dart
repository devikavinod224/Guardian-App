import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FocusModeScreen extends StatefulWidget {
  final String childId;
  final String parentUid;

  const FocusModeScreen({
    super.key,
    required this.childId,
    required this.parentUid,
  });

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  bool _isFocusing = false;
  int _targetMinutes = 30;
  int _remainingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final endIso = prefs.getString('focus_end_time');
    if (endIso != null) {
      final endTime = DateTime.parse(endIso);
      final now = DateTime.now();
      if (endTime.isAfter(now)) {
        final diff = endTime.difference(now);
        setState(() {
          _isFocusing = true;
          _targetMinutes =
              30; // Restore default or save this too? Assuming 30 for now or calc.
          _remainingSeconds = diff.inSeconds;
        });
        _startTimer();
      } else {
        // Session over, clean up validly if not already done?
        // Actually, if app was killed, we might owe them a reward if they finished?
        // Hard to prove if they finished if app was dead. For now, assume expired = done.
        prefs.remove('focus_end_time');
      }
    }
  }

  void _startFocus() async {
    final prefs = await SharedPreferences.getInstance();
    final endTime = DateTime.now().add(Duration(minutes: _targetMinutes));

    await prefs.setString('focus_end_time', endTime.toIso8601String());
    // Service picks this up to block apps

    setState(() {
      _isFocusing = true;
      _remainingSeconds = _targetMinutes * 60;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _completeFocus();
      }
    });
  }

  Future<void> _completeFocus() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('focus_end_time');

    // Grant Reward
    final bonus = (_targetMinutes / 3)
        .round(); // Reward: 1/3 of focus time (e.g. 30 -> 10)

    // Optimistic UI
    setState(() {
      _isFocusing = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Session Complete! 🎉"),
          content: Text("You earned $bonus minutes of bonus screen time!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Awesome!"),
            ),
          ],
        ),
      );
    }

    // Sync Reward to Firestore
    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.parentUid)
          .collection('children')
          .doc(widget.childId);

      // Atomic increment
      await ref.update({'bonus_time': FieldValue.increment(bonus)});
    } catch (e) {
      debugPrint("Error granting reward: $e");
    }
  }

  void _cancelFocus() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('focus_end_time');

    setState(() {
      _isFocusing = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text(
          "Focus Mode",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.indigo,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isFocusing) ...[
              const Icon(Icons.psychology, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              Text(
                "Ready to Focus?",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Focus for 30 mins, get 10 mins bonus!",
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _startFocus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "START 30 MIN SESSION",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ] else ...[
              Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                          value: _remainingSeconds / (_targetMinutes * 60),
                          strokeWidth: 20,
                          backgroundColor: Colors.indigo.withOpacity(0.1),
                          color: Colors.indigo,
                        ),
                      ),
                      Text(
                        _formatTime(_remainingSeconds),
                        style: GoogleFonts.robotoMono(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: 2000.ms,
                    color: Colors.white.withOpacity(0.5),
                  ),
              const SizedBox(height: 40),
              const Text(
                "Stay on task! Apps are blocked.",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _cancelFocus,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Give Up (No Reward)"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
