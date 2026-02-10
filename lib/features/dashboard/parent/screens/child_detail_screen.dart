import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChildDetailScreen extends StatelessWidget {
  final String childId;
  final String childName;
  final String parentUid;

  const ChildDetailScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.parentUid,
  });

  Widget _getAppIcon(String pkg, String? iconBase64) {
    if (iconBase64 != null && iconBase64.isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          base64Decode(iconBase64),
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (c, e, s) => _getFallbackIcon(pkg),
        ),
      );
    }
    return _getFallbackIcon(pkg);
  }

  Widget _getFallbackIcon(String pkg) {
    if (pkg.contains('instagram'))
      return const FaIcon(
        FontAwesomeIcons.instagram,
        color: Colors.purple,
        size: 32,
      );
    if (pkg.contains('whatsapp'))
      return const FaIcon(
        FontAwesomeIcons.whatsapp,
        color: Colors.green,
        size: 32,
      );
    if (pkg.contains('facebook'))
      return const FaIcon(
        FontAwesomeIcons.facebook,
        color: Colors.blue,
        size: 32,
      );
    if (pkg.contains('twitter') || pkg.contains('x'))
      return const FaIcon(
        FontAwesomeIcons.xTwitter,
        color: Colors.black,
        size: 32,
      );
    if (pkg.contains('linkedin'))
      return const FaIcon(
        FontAwesomeIcons.linkedin,
        color: Colors.blueAccent,
        size: 32,
      );
    if (pkg.contains('snapchat'))
      return const FaIcon(
        FontAwesomeIcons.snapchat,
        color: Colors.yellow,
        size: 32,
      );
    if (pkg.contains('youtube'))
      return const FaIcon(
        FontAwesomeIcons.youtube,
        color: Colors.red,
        size: 32,
      );
    if (pkg.contains('tiktok'))
      return const FaIcon(
        FontAwesomeIcons.tiktok,
        color: Colors.black,
        size: 32,
      );
    if (pkg.contains('discord'))
      return const FaIcon(
        FontAwesomeIcons.discord,
        color: Colors.indigo,
        size: 32,
      );
    if (pkg.contains('spotify'))
      return const FaIcon(
        FontAwesomeIcons.spotify,
        color: Colors.green,
        size: 32,
      );
    return const Icon(Icons.android, color: Colors.green, size: 32);
  }

  String _getAppName(String pkg, String originalName) {
    if (pkg.contains('instagram')) return "Instagram";
    if (pkg.contains('whatsapp')) return "WhatsApp";
    if (pkg.contains('facebook')) return "Facebook";
    if (pkg.contains('twitter') || pkg.contains('x')) return "Twitter X";
    if (pkg.contains('linkedin')) return "LinkedIn";
    if (pkg.contains('snapchat')) return "Snapchat";
    if (pkg.contains('youtube')) return "YouTube";
    if (pkg.contains('tiktok')) return "TikTok";

    if (originalName.isNotEmpty && originalName != 'Unknown')
      return originalName;

    // Fallback
    final parts = pkg.split('.');
    if (parts.length > 1) {
      return parts[1][0].toUpperCase() + parts[1].substring(1);
    }
    return pkg;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(childName),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activity'),
              Tab(text: 'Location'),
              Tab(text: 'Controls'),
            ],
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(parentUid)
              .collection('children')
              .doc(childId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Center(child: Text('Error: ${snapshot.error}'));
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data?.data() as Map<String, dynamic>?;
            if (data == null)
              return const Center(child: Text('No data available'));

            // Extract Location
            LatLng? childPos;
            if (data['location'] != null) {
              final lat = data['location']['lat'];
              final lng = data['location']['lng'];
              if (lat != null && lng != null) {
                childPos = LatLng(lat, lng);
              }
            }

            // Extract Safe Zone
            LatLng? safeZoneCenter;
            double safeZoneRadius = 500; // default
            if (data['safe_zone'] != null) {
              final lat = data['safe_zone']['lat'];
              final lng = data['safe_zone']['lng'];
              final rad = data['safe_zone']['radius'];
              if (lat != null && lng != null) {
                safeZoneCenter = LatLng(lat, lng);
                if (rad != null) safeZoneRadius = (rad as num).toDouble();
              }
            }

            return Column(
              children: [
                if (data['is_safe'] == false)
                  Container(
                        width: double.infinity,
                        color: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "OUT OF SAFE ZONE",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(duration: 800.ms),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Activity
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildHistoryChart(context), // New Chart
                          const SizedBox(height: 16),
                          if (data['bonus_time'] != null &&
                              (data['bonus_time'] as int) > 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.indigo, Colors.blueAccent],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.stars_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Bonus Time Earned!",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "${data['bonus_time']} mins available",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().shimmer(duration: 2000.ms),
                          _buildUsageCard(context, data['app_usage']),
                        ],
                      ),
                      // Tab 2: Location (Map)
                      Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter:
                                  childPos ??
                                  safeZoneCenter ??
                                  const LatLng(20.5937, 78.9629), // Default
                              initialZoom: childPos != null ? 15.0 : 4.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.devika.guardian',
                              ),
                              if (safeZoneCenter != null)
                                CircleLayer(
                                  circles: [
                                    CircleMarker(
                                      point: safeZoneCenter,
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderColor: Colors.blue,
                                      borderStrokeWidth: 2,
                                      useRadiusInMeter: true,
                                      radius: safeZoneRadius,
                                    ),
                                  ],
                                ),
                              if (childPos != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: childPos,
                                      width: 80,
                                      height: 80,
                                      child: const Icon(
                                        Icons.location_on,
                                        size: 50,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (childPos == null)
                            Center(
                              child: Container(
                                margin: const EdgeInsets.all(32),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Waiting for location...",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Ensure child's device covers internet & GPS.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20, // Full width bottom bar
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (childPos != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          data['location']?['timestamp'] != null
                                              ? DateFormat('h:mm a').format(
                                                  (data['location']['timestamp']
                                                          as Timestamp)
                                                      .toDate(),
                                                )
                                              : 'Just now',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                FloatingActionButton.extended(
                                  heroTag: 'set_home',
                                  onPressed: childPos == null
                                      ? null
                                      : () {
                                          FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(parentUid)
                                              .collection('children')
                                              .doc(childId)
                                              .update({
                                                'safe_zone': {
                                                  'lat': childPos!.latitude,
                                                  'lng': childPos!.longitude,
                                                  'radius': 500, // 500 meters
                                                  'timestamp':
                                                      FieldValue.serverTimestamp(),
                                                },
                                              });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Safe Zone set to current location (500m) 🛡️',
                                              ),
                                            ),
                                          );
                                        },
                                  icon: const Icon(Icons.security),
                                  label: const Text('Set Home Zone'),
                                  backgroundColor: childPos == null
                                      ? Colors.grey
                                      : Colors.blueAccent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Tab 3: Controls
                      _buildControlsTab(context, data),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildControlsTab(
    BuildContext context,
    Map<String, dynamic> childData,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(childId)
          .collection('apps')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final apps = snapshot.data?.docs ?? [];

        return Column(
          children: [
            // BEDTIME CONTROLS
            _buildBedtimeCard(context, childData),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "App Limits & Blocking",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // APP LIST
            if (apps.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Syncing apps from child device...',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This may take 1-2 minutes.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final doc = apps[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final pkg = data['packageName'] ?? '';
                    final iconBase64 = data['icon'] as String?;

                    final blockedApps = List<String>.from(
                      childData['blocked_apps'] ?? [],
                    );
                    final appLimits = Map<String, dynamic>.from(
                      childData['app_limits'] ?? {},
                    );

                    final isBlocked = blockedApps.contains(pkg);
                    final limitMins = appLimits[pkg] as int?;

                    return GestureDetector(
                      onTap: () => _showLimitDialog(
                        context,
                        pkg,
                        _getAppName(pkg, name),
                      ),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        decoration: BoxDecoration(
                          color: isBlocked ? Colors.red.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isBlocked
                                ? Colors.red.shade200
                                : Colors.grey.shade200,
                            width: isBlocked ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (isBlocked) {
                                  // Unblock
                                  final ref = FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(parentUid)
                                      .collection('children')
                                      .doc(childId);

                                  ref.update({
                                    'blocked_apps': FieldValue.arrayRemove([
                                      pkg,
                                    ]),
                                  });
                                } else {
                                  _showLimitDialog(context, pkg, name);
                                }
                              },
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isBlocked
                                          ? Colors.white
                                          : Colors.grey.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: isBlocked
                                        ? ColorFiltered(
                                            colorFilter: const ColorFilter.mode(
                                              Colors.grey,
                                              BlendMode.saturation,
                                            ),
                                            child: _getAppIcon(pkg, iconBase64),
                                          )
                                        : _getAppIcon(pkg, iconBase64),
                                  ),
                                  if (limitMins != null)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.timer,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                _getAppName(pkg, name),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isBlocked
                                      ? Colors.red
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: !isBlocked,
                                activeColor: Colors.green,
                                inactiveTrackColor: Colors.red.shade100,
                                inactiveThumbColor: Colors.red,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (allowed) {
                                  final ref = FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(parentUid)
                                      .collection('children')
                                      .doc(childId);

                                  if (allowed) {
                                    ref.update({
                                      'blocked_apps': FieldValue.arrayRemove([
                                        pkg,
                                      ]),
                                    });
                                  } else {
                                    ref.update({
                                      'blocked_apps': FieldValue.arrayUnion([
                                        pkg,
                                      ]),
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBedtimeCard(BuildContext context, Map<String, dynamic> data) {
    final bedtime = data['bedtime'] as Map<String, dynamic>? ?? {};
    final isEnabled = bedtime['enabled'] as bool? ?? false;
    final start = bedtime['start'] ?? '21:00';
    final end = bedtime['end'] ?? '07:00';

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.indigo.shade900, Colors.deepPurple.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.nights_stay,
                      color: Colors.amber,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Bedtime Mode",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isEnabled,
                  activeColor: Colors.amber,
                  onChanged: (val) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(parentUid)
                        .collection('children')
                        .doc(childId)
                        .update({
                          'bedtime.enabled': val,
                          // ensure defaults exist if first time
                          if (!bedtime.containsKey('start'))
                            'bedtime.start': start,
                          if (!bedtime.containsKey('end')) 'bedtime.end': end,
                        });
                  },
                ),
              ],
            ),
            if (isEnabled) ...[
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTimePicker(context, "Starts", start, (newTime) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(parentUid)
                        .collection('children')
                        .doc(childId)
                        .update({'bedtime.start': newTime});
                  }),
                  const Icon(Icons.arrow_forward, color: Colors.white54),
                  _buildTimePicker(context, "Ends", end, (newTime) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(parentUid)
                        .collection('children')
                        .doc(childId)
                        .update({'bedtime.end': newTime});
                  }),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    BuildContext context,
    String label,
    String timeStr,
    Function(String) onPicked,
  ) {
    return GestureDetector(
      onTap: () async {
        final parts = timeStr.split(':');
        final initial = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );
        if (picked != null) {
          final formatted =
              '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
          onPicked(formatted);
        }
      },
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30),
            ),
            child: Text(
              timeStr, // Simplified formatting, ideally use DateFormat
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLimitPickerDialog(
    BuildContext context,
    String pkg,
    String appName,
    int? currentLimit,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Set Limit: $appName',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set a daily time limit for this app.'),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildLimitChip(ctx, pkg, 15, currentLimit),
                _buildLimitChip(ctx, pkg, 30, currentLimit),
                _buildLimitChip(ctx, pkg, 60, currentLimit),
                _buildLimitChip(ctx, pkg, 120, currentLimit),
                _buildLimitChip(
                  ctx,
                  pkg,
                  null,
                  currentLimit,
                  label: 'No Limit',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitChip(
    BuildContext context,
    String pkg,
    int? minutes,
    int? current, {
    String? label,
  }) {
    final isSelected = minutes == current;
    return ChoiceChip(
      label: Text(label ?? '$minutes mins'),
      selected: isSelected,
      onSelected: (_) {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(parentUid)
            .collection('children')
            .doc(childId);

        if (minutes == null) {
          // Remove limit
          // Firestore doesn't support deleting a map key via update easily without dot notation syntax
          // but we can rewrite the map or use FieldValue.delete() if key is known path.
          // For map fields: "app_limits.pkg": FieldValue.delete()
          ref.update({'app_limits.$pkg': FieldValue.delete()});
        } else {
          ref.update({'app_limits.$pkg': minutes});
        }
        Navigator.pop(context);
      },
    );
  }

  Widget _buildHistoryChart(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(childId)
          .collection('stats')
          .orderBy('timestamp', descending: true)
          .limit(7)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs;
        // if (docs.isEmpty) return const SizedBox.shrink(); // Disabled to show empty chart

        // Prepare data: Map<DateStr, Mins>
        final Map<String, int> dailyMins = {};
        for (var doc in docs) {
          dailyMins[doc.id] =
              (doc.data() as Map<String, dynamic>)['total_minutes'] ?? 0;
        }

        // Fill last 7 days (including today)
        final List<BarChartGroupData> barGroups = [];
        final now = DateTime.now();
        double maxMins = 0;

        // X=0 is 6 days ago, X=6 is Today
        for (int i = 0; i < 7; i++) {
          // i=0 -> subtract 6 days
          // i=6 -> subtract 0 days
          final date = now.subtract(Duration(days: 6 - i));
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          final mins = dailyMins[dateStr]?.toDouble() ?? 0.0;
          if (mins > maxMins) maxMins = mins;

          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: mins,
                  color: i == 6
                      ? Colors
                            .amber // Today
                      : Colors.blueAccent.withValues(alpha: 0.7),
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: (maxMins < 60) ? 60 : maxMins * 1.2,
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          );
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Weekly Activity",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                AspectRatio(
                  aspectRatio: 1.5,
                  child: BarChart(
                    BarChartData(
                      maxY: (maxMins < 60) ? 60 : maxMins * 1.2,
                      barGroups: barGroups,
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final index = val.toInt();
                              if (index < 0 || index >= 7)
                                return const SizedBox.shrink();

                              final date = now.subtract(
                                Duration(days: 6 - index),
                              );
                              final dayName = DateFormat(
                                'E',
                              ).format(date)[0]; // M, T, W...

                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  dayName,
                                  style: GoogleFonts.poppins(
                                    fontWeight: index == 6
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: index == 6
                                        ? Colors.amber
                                        : Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    Map<String, dynamic>? location,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Last Known Location',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (location != null) ...[
              Text('Latitude: ${location['lat']}'),
              Text('Longitude: ${location['lng']}'),
              Text(
                'Updated: ${location['timestamp'] != null ? DateFormat('h:mm a').format((location['timestamp'] as Timestamp).toDate()) : 'Unknown'}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ] else
              const Text('Location not yet available.'),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageCard(BuildContext context, Map<String, dynamic>? usage) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.apps, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'App Usage (Today)',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (usage != null && usage.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: usage.length,
                itemBuilder: (ctx, index) {
                  final pkg = usage.keys.elementAt(index);
                  final milliseconds = usage[pkg] as int;
                  final minutes = (milliseconds / 1000 / 60).round();

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(parentUid)
                        .collection('children')
                        .doc(childId)
                        .collection('apps')
                        .doc(pkg)
                        .get(),
                    builder: (context, snapshot) {
                      final appData =
                          snapshot.data?.data() as Map<String, dynamic>?;
                      final name = appData?['name'] ?? pkg.split('.').last;
                      final iconBase64 = appData?['icon'] as String?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _getAppIcon(pkg, iconBase64),
                          ),
                          title: Text(
                            _getAppName(pkg, name),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$minutes min',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade700,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.smartphone_rounded,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No activity recorded yet today",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Usage stats will appear here shortly.",
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLimitDialog(BuildContext context, String pkg, String appName) {
    int selectedHours = 1;
    int selectedMinutes = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Manage $appName"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text("Block App"),
                  onTap: () {
                    Navigator.pop(ctx);
                    final ref = FirebaseFirestore.instance
                        .collection('users')
                        .doc(parentUid)
                        .collection('children')
                        .doc(childId);

                    ref.update({
                      'blocked_apps': FieldValue.arrayUnion([pkg]),
                      'app_limits.$pkg': FieldValue.delete(),
                    });

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Blocked $appName")));
                  },
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  "Set Daily Limit",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hours Picker
                    Column(
                      children: [
                        Text("Hours", style: GoogleFonts.poppins(fontSize: 12)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<int>(
                            value: selectedHours,
                            underline: const SizedBox(),
                            items: List.generate(12, (index) => index).map((h) {
                              return DropdownMenuItem(
                                value: h,
                                child: Text("$h"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() => selectedHours = val!);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Minutes Picker
                    Column(
                      children: [
                        Text(
                          "Minutes",
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<int>(
                            value: selectedMinutes,
                            underline: const SizedBox(),
                            items: [0, 15, 30, 45].map((m) {
                              return DropdownMenuItem(
                                value: m,
                                child: Text("$m".padLeft(2, '0')),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() => selectedMinutes = val!);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final totalMins = (selectedHours * 60) + selectedMinutes;
                    final ref = FirebaseFirestore.instance
                        .collection('users')
                        .doc(parentUid)
                        .collection('children')
                        .doc(childId);

                    if (totalMins > 0) {
                      ref.update({
                        'app_limits.$pkg': totalMins,
                        'blocked_apps': FieldValue.arrayRemove([pkg]),
                      });
                    } else {
                      ref.update({'app_limits.$pkg': FieldValue.delete()});
                    }

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Limit set to ${selectedHours}h ${selectedMinutes}m for $appName",
                        ),
                      ),
                    );
                  },
                  child: const Text("Save Limit"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
