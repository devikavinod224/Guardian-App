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

            return TabBarView(
              children: [
                // Tab 1: Activity
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHistoryChart(context), // New Chart
                    const SizedBox(height: 16),
                    _buildUsageCard(context, data['app_usage']),
                  ],
                ),
                // Tab 2: Location (Map)
                childPos == null
                    ? const Center(child: Text('Location not valid.'))
                    : Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: childPos,
                              initialZoom: 15.0,
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
                                      color: Colors.blue.withOpacity(0.1),
                                      borderColor: Colors.blue,
                                      borderStrokeWidth: 2,
                                      useRadiusInMeter: true,
                                      radius: safeZoneRadius,
                                    ),
                                  ],
                                ),
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
                          Positioned(
                            bottom: 20,
                            left: 20,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
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
                                    'Last Updated: ${data['location']?['timestamp'] != null ? DateFormat('h:mm a').format((data['location']['timestamp'] as Timestamp).toDate()) : 'Unknown'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            right: 20,
                            child: FloatingActionButton.extended(
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(parentUid)
                                    .collection('children')
                                    .doc(childId)
                                    .update({
                                      'safe_zone': {
                                        'lat': childPos!.latitude,
                                        'lng': childPos.longitude,
                                        'radius': 500, // 500 meters
                                        'timestamp':
                                            FieldValue.serverTimestamp(),
                                      },
                                    });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Safe Zone set to current location (500m) 🛡️',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.security),
                              label: const Text('Set Home Zone'),
                              backgroundColor: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                // Tab 3: Controls
                _buildControlsTab(context, data),
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

            // APP LIST
            if (apps.isEmpty)
              const Expanded(child: Center(child: Text('No apps synced yet.')))
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
                      onTap: () =>
                          _showLimitPickerDialog(context, pkg, name, limitMins),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isBlocked
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isBlocked
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isBlocked
                                                      ? Colors.red.withOpacity(
                                                          0.2,
                                                        )
                                                      : Colors.blue.withOpacity(
                                                          0.2,
                                                        ),
                                                  blurRadius: 12,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: iconBase64 != null
                                                ? ClipOval(
                                                    child: Image.memory(
                                                      base64Decode(iconBase64),
                                                      width: 48,
                                                      height: 48,
                                                      fit: BoxFit.cover,
                                                      gaplessPlayback: true,
                                                    ),
                                                  )
                                                : CircleAvatar(
                                                    radius: 24,
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                    child: Icon(
                                                      Icons.android,
                                                      color: Colors.grey[400],
                                                      size: 28,
                                                    ),
                                                  ),
                                          )
                                          .animate(target: isBlocked ? 1 : 0)
                                          .scale(end: const Offset(0.9, 0.9))
                                          .desaturate(end: 1),
                                      const SizedBox(height: 8),
                                      Text(
                                        name,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (limitMins != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.orange.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            '${limitMins}m Limit',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.deepOrange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Transform.scale(
                                    scale: 0.6,
                                    child: Switch(
                                      value: !isBlocked, // ON = Allowed
                                      activeColor: Colors.greenAccent,
                                      activeTrackColor: Colors.green
                                          .withOpacity(0.3),
                                      inactiveThumbColor: Colors.redAccent,
                                      inactiveTrackColor: Colors.red
                                          .withOpacity(0.3),
                                      onChanged: (allowed) {
                                        final ref = FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(parentUid)
                                            .collection('children')
                                            .doc(childId);

                                        if (allowed) {
                                          ref.update({
                                            'blocked_apps':
                                                FieldValue.arrayRemove([pkg]),
                                          });
                                        } else {
                                          ref.update({
                                            'blocked_apps':
                                                FieldValue.arrayUnion([pkg]),
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate(delay: (30 * index).ms).scale().fade(),
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
              color: Colors.white.withOpacity(0.1),
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
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const SizedBox.shrink();

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
                      : Colors.blueAccent.withOpacity(0.7),
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

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: iconBase64 != null
                              ? Image.memory(
                                  base64Decode(iconBase64),
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.android,
                                    color: Colors.blueAccent,
                                    size: 20,
                                  ),
                                )
                              : const Icon(
                                  Icons.android,
                                  color: Colors.blueAccent,
                                  size: 20,
                                ),
                        ),
                        title: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          pkg,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: Text(
                          '$minutes min',
                          style: GoogleFonts.robotoMono(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      );
                    },
                  );
                },
              )
            else
              const Text('No usage data yet.'),
          ],
        ),
      ),
    );
  }
}
