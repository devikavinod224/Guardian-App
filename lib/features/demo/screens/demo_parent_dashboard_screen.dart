import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../data/demo_data.dart';
import 'demo_child_detail_screen.dart';
import 'demo_settings_screen.dart';

class DemoParentDashboardScreen extends StatefulWidget {
  const DemoParentDashboardScreen({super.key});

  @override
  State<DemoParentDashboardScreen> createState() =>
      _DemoParentDashboardScreenState();
}

class _DemoParentDashboardScreenState extends State<DemoParentDashboardScreen> {
  // Local state for demo interactions
  final List<Map<String, dynamic>> _children = DemoData.children;
  List<Map<String, dynamic>> _requests = DemoData.requests;

  @override
  Widget build(BuildContext context) {
    // Sort for Leaderboard
    final leaderboardData = List<Map<String, dynamic>>.from(_children);
    leaderboardData.sort((a, b) {
      final aTime = a['total_screen_time'] as int;
      final bTime = b['total_screen_time'] as int;
      return bTime.compareTo(aTime);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Dashboard (DEMO)'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_active),
                onPressed: () => _showRequestsSheet(context),
              ),
              if (_requests.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child:
                      Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_requests.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.2, 1.2),
                          ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.pop(context),
            tooltip: "Exit Demo",
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Leaderboard
              if (leaderboardData.isNotEmpty)
                _buildLeaderboard(context, leaderboardData.first)
                    .animate()
                    .fade(duration: 600.ms)
                    .slideY(begin: -0.2, end: 0, curve: Curves.easeOutBack),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _children.length,
                  itemBuilder: (context, index) {
                    final data = _children[index];
                    final name = data['name'];
                    final isSafe = data['is_safe'] as bool;
                    final isSos = data['is_sos'] as bool? ?? false;
                    final isFocus = data['is_focus'] as bool? ?? false;

                    return Card(
                      elevation: isSos ? 12 : 8,
                      shadowColor: isSos
                          ? Colors.red
                          : isSafe
                          ? Colors.blueAccent.withValues(alpha: 0.3)
                          : Colors.redAccent.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSos
                              ? Colors.red
                              : isSafe
                              ? Colors.blueAccent.withValues(alpha: 0.1)
                              : Colors.redAccent,
                          width: isSos ? 3 : (isSafe ? 1 : 2),
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: isSos
                              ? Colors.red.withValues(alpha: 0.2)
                              : isSafe
                              ? Colors.blueAccent.withValues(alpha: 0.1)
                              : Colors.redAccent.withValues(alpha: 0.1),
                          child:
                              Icon(
                                    isSos
                                        ? Icons.sos
                                        : isSafe
                                        ? Icons.rocket_launch_rounded
                                        : Icons.warning_rounded,
                                    color: isSos
                                        ? Colors.red
                                        : isSafe
                                        ? Colors.blueAccent
                                        : Colors.redAccent,
                                    size: isSos ? 32 : 24,
                                  )
                                  .animate(
                                    onPlay: (c) =>
                                        isSos ? c.repeat(reverse: true) : null,
                                  )
                                  .scale(end: const Offset(1.2, 1.2)),
                        ),
                        title: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isSos
                                ? Colors.red
                                : (isSafe ? null : Colors.red),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildStatusIndicator(data['last_active']),
                                const SizedBox(width: 8),
                                Text(
                                  'Last active: ${_formatTimestamp(data['last_active'])}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            if (isSos)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "SOS TRIGGERED! 🚨",
                                  style: GoogleFonts.poppins(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ).animate(onPlay: (c) => c.repeat()).fade(),

                            if (!isSafe && !isSos)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_off,
                                      size: 12,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "OUT OF SAFE ZONE",
                                      style: GoogleFonts.poppins(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (isFocus && !isSos)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.psychology,
                                      size: 14,
                                      color: Colors.indigo,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Focus Mode Active 🎯",
                                      style: GoogleFonts.poppins(
                                        color: Colors.indigo,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.blueAccent,
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DemoChildDetailScreen(childData: data),
                            ),
                          );
                          setState(() {
                            _requests = DemoData.requests;
                          });
                        },
                      ),
                    ).animate(delay: (100 * index).ms).fade().slideX();
                  },
                ),
              ),
            ],
          ),

          // Floating Debug Menu for Presentation Control
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'demo_debug',
              backgroundColor: Colors.grey[800],
              child: const Icon(Icons.build, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Presentation Controls",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.sos, color: Colors.red),
                          title: const Text("Trigger SOS (Sarah)"),
                          onTap: () {
                            setState(() {
                              // Toggle SOS for Sarah (Index 1)
                              var sarah = _children.firstWhere(
                                (c) => c['name'] == 'Sarah',
                              );
                              sarah['is_sos'] = !(sarah['is_sos'] ?? false);
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.blue,
                          ),
                          title: const Text("Simulate Add Device"),
                          onTap: () {
                            Navigator.pop(ctx);
                            _simulateAddDevice();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DemoSettingsScreen()),
              );
            },
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo,
            child: const Icon(Icons.settings),
          ),
          const SizedBox(height: 20),
          FloatingActionButton.extended(
            heroTag: 'add_device',
            onPressed: _simulateAddDevice,
            icon: const Icon(Icons.add),
            label: const Text("Add Device"),
          ),
        ],
      ),
    );
  }

  void _simulateAddDevice() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text("Scanning QR Code...", style: GoogleFonts.poppins()),
            ],
          ),
        ),
      ),
    );

    // Simulate network delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo: Device "Tablet" added successfully! 🎉'),
          ),
        );
        setState(() {
          _children.add({
            'id': 'child_new',
            'name': 'Tablet',
            'total_screen_time': 0,
            'is_safe': true,
            'last_active': Timestamp.now(),
            'location': {
              'lat': 40.7128,
              'lng': -74.0060,
              'timestamp': Timestamp.now(),
            },
            'app_usage': <String, dynamic>{}, // Fix Type
            'bonus_time': 0,
            'bedtime': {'enabled': false, 'start': '21:00', 'end': '07:00'},
            'blocked_apps': [],
          });
        });
      }
    });
  }

  void _showRequestsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Access Requests (DEMO)',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_requests.isEmpty)
                const Center(child: Text('No pending requests.'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Icon(Icons.lock_clock, color: Colors.white),
                      ),
                      title: Text('${req['childName']} wants access'),
                      subtitle: Text(
                        'App: ${req['appName']} for ${req['requestedDuration']} mins',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () {
                              setState(() {
                                _requests.removeAt(index);
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Demo: Request Approved! ✅'),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _requests.removeAt(index);
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Demo: Request Rejected ❌'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboard(BuildContext context, Map<String, dynamic> data) {
    final name = data['name'];
    final totalMillis = data['total_screen_time'] as int;
    final duration = Duration(milliseconds: totalMillis);
    final hours = duration.inHours;
    final mins = duration.inMinutes.remainder(60);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6A1B9A), // Deep Purple
            const Color(0xFF8E24AA), // Purple
            Colors.deepOrange.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A1B9A).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white24,
              child: Icon(Icons.emoji_events, size: 36, color: Colors.amber),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Activity Leader",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$hours hr $mins min",
                  style: GoogleFonts.robotoMono(
                    color: Colors.amberAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(Timestamp lastActive) {
    final now = DateTime.now();
    final activeTime = lastActive.toDate();
    final diff = now.difference(activeTime);
    final isOnline = diff.inMinutes < 5;

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? Colors.green : Colors.grey,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(date);
  }
}
