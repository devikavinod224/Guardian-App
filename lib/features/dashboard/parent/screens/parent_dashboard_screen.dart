import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../features/pairing/screens/pairing_code_screen.dart';
import '../../../../features/auth/services/auth_service.dart';
import '../../../../features/settings/screens/settings_screen.dart';
import '../../../../features/pairing/services/pairing_service.dart';
import 'child_detail_screen.dart';
import '../../../auth/screens/role_selection_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Access Requests',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collectionGroup('requests')
                      .where(
                        'parentId',
                        isEqualTo: context.read<AuthService>().currentUser?.uid,
                      )
                      .where('status', isEqualTo: 'pending')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint("Request Query Error: ${snapshot.error}");
                      return const Center(
                        child: Text('Requires Firestore Index (Check Logic)'),
                      );
                    }
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    final reqs = snapshot.data!.docs;
                    if (reqs.isEmpty)
                      return const Center(child: Text('No pending requests.'));

                    return ListView.builder(
                      itemCount: reqs.length,
                      itemBuilder: (context, index) {
                        final req = reqs[index];
                        final data = req.data() as Map<String, dynamic>;
                        final childName = data['childName'] ?? 'Child';
                        final appName = data['appName'] ?? 'App';
                        final duration = data['requestedDuration'] as int? ?? 0;
                        final durationText = duration == -1
                            ? "Unblock for Today"
                            : "$duration mins";

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.lock_clock,
                              color: Colors.red,
                            ),
                          ),
                          title: Text('$childName wants access to $appName'),
                          subtitle: Text('Requested: $durationText'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  req.reference.update({'status': 'rejected'});
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                                onPressed: () => _approveRequest(context, req),
                              ),
                            ],
                          ),
                        ).animate().fade().slideX();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _listenForSOS();
  }

  // Listener for SOS Alerts
  void _listenForSOS() {
    // We need to wait for user to be logged in, but initState runs before build.
    // However, we can use a post-frame or check auth later.
    // Ideally, we should start this only after we have a valid user.
    // Since ParentDashboardScreen is built only after login, we can assume context.read<AuthService>() works?
    // No, context.read might not be ready in initState for inherited widgets sometimes, but generally ok if parent exists.
    // Safer: Use addPostFrameCallback.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthService>().currentUser;
      if (user != null) {
        FirebaseFirestore.instance
            .collectionGroup('alerts')
            .where('parentId', isEqualTo: user.uid)
            .where('type', isEqualTo: 'SOS')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots()
            .listen((snapshot) {
              if (snapshot.docs.isNotEmpty) {
                final doc = snapshot.docs.first;
                final data = doc.data();
                final timestamp = data['timestamp'] as Timestamp?;

                if (timestamp != null) {
                  final time = timestamp.toDate();
                  final diff = DateTime.now().difference(time);
                  // Only show if alert is recent (< 5 mins) to avoid spamming old alerts
                  if (diff.inMinutes < 5) {
                    // Check if we already showed this one? (Mechanism needed or just show dialog)
                    // If we use a dialog, we need to be careful not to stack them.
                    // Ideally check if dialog is open. For now, simple approach:
                    _showSOSDialog(context, data);
                  }
                }
              }
            });
      }
    });
  }

  void _showSOSDialog(BuildContext context, Map<String, dynamic> data) {
    // Only show if mounted
    if (!mounted) return;

    // Check if dialog is effectively needed (simple debounce could go here)

    showDialog(
      context: context,
      barrierDismissible: false, // Critical!
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.red, width: 3),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 40,
            ),
            const SizedBox(width: 12),
            const Text(
              "SOS ALERT",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['message'] ?? 'Emergency reported!',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (data['location'] != null)
              const Text(
                "Location attached.",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 8),
            const Text(
              "High priority notification received.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ACKNOWLEDGE"),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(
    BuildContext context,
    DocumentSnapshot reqDoc,
  ) async {
    final data = reqDoc.data() as Map<String, dynamic>;
    final childId = data['childId'];
    final pkg = data['packageName'];
    final duration = data['requestedDuration'] as int? ?? 0;
    final userUid = context.read<AuthService>().currentUser?.uid;

    if (userUid == null || childId == null || pkg == null) return;

    final childRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userUid)
        .collection('children')
        .doc(childId);

    // 1. Update Request
    await reqDoc.reference.update({'status': 'approved'});

    // 2. Grant Access
    if (duration == -1) {
      // Unblock for today (remove limit and block)
      await childRef.update({
        'blocked_apps': FieldValue.arrayRemove([pkg]),
        'app_limits.$pkg': FieldValue.delete(),
      });
    } else {
      // Add time to current usage
      final childDoc = await childRef.get();
      final childData = childDoc.data() as Map<String, dynamic>?;
      int currentUsageMins = 0;

      if (childData != null && childData['app_usage'] != null) {
        final usageMap = childData['app_usage'] as Map<String, dynamic>;
        final usageMillis = usageMap[pkg] as int? ?? 0;
        currentUsageMins = (usageMillis / 1000 / 60).ceil();
      }

      // If they are already blocked, they likely used X mins.
      // We want to give them X + requested mins.
      // If they haven't used it (just blocked explicitly), currentUsage is low, so limit = duration.
      // This covers both cases.
      final newLimit = currentUsageMins + duration;

      await childRef.update({
        'blocked_apps': FieldValue.arrayRemove([pkg]),
        'app_limits.$pkg': newLimit,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Granted $duration mins (Total limit: $newLimit mins)',
            ),
          ),
        );
      }
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Parent'),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup('requests')
                .where(
                  'parentId',
                  isEqualTo: context.read<AuthService>().currentUser?.uid,
                )
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return IconButton(
                onPressed: () => _showRequestsSheet(context),
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PairingCodeScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (mounted) {
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
      body: StreamBuilder<QuerySnapshot>(
        stream: context.read<AuthService>().currentUser != null
            ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(context.read<AuthService>().currentUser!.uid)
                  .collection('children')
                  .snapshots()
            : const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.devices_other_rounded,
                        size: 64,
                        color: Colors.indigo.shade300,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Devices Linked',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Link a child device to start monitoring activity and location.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final children = snapshot.data!.docs;
          // Sort for Leaderboard (descending screen time)
          final leaderboardData = List<QueryDocumentSnapshot>.from(children);
          leaderboardData.sort((a, b) {
            final aTime =
                (a.data() as Map<String, dynamic>)['total_screen_time'] ?? 0;
            final bTime =
                (b.data() as Map<String, dynamic>)['total_screen_time'] ?? 0;
            return bTime.compareTo(aTime);
          });

          return Column(
            children: [
              if (leaderboardData.isNotEmpty &&
                  (leaderboardData.first.data() as Map)['total_screen_time'] !=
                      null &&
                  ((leaderboardData.first.data() as Map)['total_screen_time']
                          as int) >
                      0)
                _buildLeaderboard(context, leaderboardData.first)
                    .animate()
                    .fade(duration: 600.ms)
                    .slideY(begin: -0.2, end: 0, curve: Curves.easeOutBack),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final doc = children[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown Child';
                    final isSafe = data['is_safe'] as bool? ?? true;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChildDetailScreen(
                              childId: doc.id,
                              childName: name,
                              parentUid: context
                                  .read<AuthService>()
                                  .currentUser!
                                  .uid,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isSafe
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isSafe
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSafe
                                        ? Colors.blue.withValues(alpha: 0.2)
                                        : Colors.red.withValues(alpha: 0.2),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: isSafe
                                      ? Colors.blue.shade50
                                      : Colors.red.shade50,
                                  child: Icon(
                                    isSafe
                                        ? Icons.rocket_launch_rounded
                                        : Icons.warning_rounded,
                                    color: isSafe
                                        ? Colors.blueAccent
                                        : Colors.redAccent,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (!isSafe) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              "ALERT",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _buildStatusIndicator(
                                          data['last_active'],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatTimestamp(data['last_active']),
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!isSafe)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          "Location: Out of Safe Zone",
                                          style: GoogleFonts.poppins(
                                            color: Colors.red.shade700,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate(delay: (100 * index).ms).fade().slideX(),
                    );
                  },
                ),
              ),
            ],
          );
        },
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
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo,
            child: const Icon(Icons.settings),
          ),
          const SizedBox(height: 20),
          FloatingActionButton.extended(
            heroTag: 'add_device',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PairingCodeScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Device'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(BuildContext context, DocumentSnapshot topChildDoc) {
    final data = topChildDoc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unknown';
    final totalMillis = data['total_screen_time'] as int? ?? 0;

    // Convert millis to hours/mins
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                    Icons.privacy_tip_rounded,
                    color: Colors.white,
                    size: 28,
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: 2000.ms,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
              const SizedBox(width: 12),
              Text(
                'Highest Activity',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  radius: 28,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${hours}h ${mins}m',
                        style: GoogleFonts.robotoMono(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ' today',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(dynamic timestamp) {
    bool isOnline = false;
    if (timestamp is Timestamp) {
      final now = DateTime.now();
      final date = timestamp.toDate();
      final diff = now.difference(date);
      if (diff.inMinutes < 5) isOnline = true;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? Colors.green : Colors.grey,
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Never';
    if (timestamp is Timestamp) {
      final now = DateTime.now();
      final date = timestamp.toDate();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }
    return 'Unknown';
  }
}
