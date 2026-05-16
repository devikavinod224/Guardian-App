import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../data/demo_data.dart';

class DemoChildDetailScreen extends StatefulWidget {
  final Map<String, dynamic> childData;

  const DemoChildDetailScreen({super.key, required this.childData});

  @override
  State<DemoChildDetailScreen> createState() => _DemoChildDetailScreenState();
}

class _DemoChildDetailScreenState extends State<DemoChildDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _data = widget.childData;
  }

  Widget _getAppIcon(String pkg) {
    if (pkg.contains('instagram')) {
      return const FaIcon(
        FontAwesomeIcons.instagram,
        color: Colors.purple,
        size: 32,
      );
    } else if (pkg.contains('whatsapp')) {
      return const FaIcon(
        FontAwesomeIcons.whatsapp,
        color: Colors.green,
        size: 32,
      );
    } else if (pkg.contains('facebook')) {
      return const FaIcon(
        FontAwesomeIcons.facebook,
        color: Colors.blue,
        size: 32,
      );
    } else if (pkg.contains('twitter') || pkg.contains('x')) {
      return const FaIcon(
        FontAwesomeIcons.xTwitter,
        color: Colors.black,
        size: 32,
      );
    } else if (pkg.contains('linkedin')) {
      return const FaIcon(
        FontAwesomeIcons.linkedin,
        color: Colors.blueAccent,
        size: 32,
      );
    } else if (pkg.contains('snapchat')) {
      return const FaIcon(
        FontAwesomeIcons.snapchat,
        color: Colors.yellow,
        size: 32,
      );
    } else if (pkg.contains('youtube')) {
      return const FaIcon(
        FontAwesomeIcons.youtube,
        color: Colors.red,
        size: 32,
      );
    } else if (pkg.contains('tiktok')) {
      return const FaIcon(
        FontAwesomeIcons.tiktok,
        color: Colors.black,
        size: 32,
      );
    } else if (pkg.contains('discord')) {
      return const FaIcon(
        FontAwesomeIcons.discord,
        color: Colors.indigo,
        size: 32,
      );
    } else if (pkg.contains('spotify')) {
      return const FaIcon(
        FontAwesomeIcons.spotify,
        color: Colors.green,
        size: 32,
      );
    } else if (pkg.contains('roblox')) {
      return const Icon(Icons.games_rounded, color: Colors.redAccent, size: 32);
    } else if (pkg.contains('duolingo')) {
      return const Icon(Icons.translate, color: Colors.greenAccent, size: 32);
    }
    return const Icon(Icons.android, color: Colors.green, size: 32);
  }

  String _getAppName(String pkg) {
    if (pkg.contains('instagram')) return "Instagram";
    if (pkg.contains('whatsapp')) return "WhatsApp";
    if (pkg.contains('facebook')) return "Facebook";
    if (pkg.contains('twitter') || pkg.contains('x')) return "Twitter X";
    if (pkg.contains('linkedin')) return "LinkedIn";
    if (pkg.contains('snapchat')) return "Snapchat";
    if (pkg.contains('youtube')) return "YouTube";
    if (pkg.contains('tiktok')) return "TikTok";
    if (pkg.contains('discord')) return "Discord";
    if (pkg.contains('spotify')) return "Spotify";
    if (pkg.contains('roblox')) return "Roblox";
    if (pkg.contains('duolingo')) return "Duolingo";

    // Fallback: Try to get the meaningful part
    final parts = pkg.split('.');
    if (parts.length > 1) {
      return parts[1][0].toUpperCase() + parts[1].substring(1);
    }
    return pkg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_data['name']}\'s Device (DEMO)'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Activity'),
            Tab(icon: Icon(Icons.map), text: 'Location'),
            Tab(icon: Icon(Icons.shield), text: 'Controls'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivityTab(),
          _buildLocationTab(),
          _buildControlsTab(),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    final appUsage = _data['app_usage'] as Map<String, dynamic>;
    final bonusTime = _data['bonus_time'] as int;
    final isFocus = _data['is_focus'] as bool? ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isFocus)
          Card(
            color: Colors.indigo.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.psychology,
                color: Colors.indigo,
                size: 32,
              ),
              title: Text(
                "Focus Mode Active 🎯",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              subtitle: Text(
                "${_data['name']} is currently in a focus session.",
                style: GoogleFonts.poppins(color: Colors.indigo.shade700),
              ),
            ),
          ).animate().scale().fade(),

        if (bonusTime > 0)
          Card(
            color: Colors.amber.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.stars, color: Colors.orange, size: 32),
              title: Text(
                "Bonus Time Earned!",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              subtitle: Text(
                "${_data['name']} earned $bonusTime mins from Focus Sessions.",
                style: GoogleFonts.poppins(color: Colors.brown),
              ),
            ),
          ).animate().scale().fade(),

        const SizedBox(height: 16),
        _buildDemoChart(),
        const SizedBox(height: 16),

        Text(
          "App Usage (Today)",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...appUsage.entries.map((e) {
          final pkg = e.key;
          final millis = e.value as int;
          final mins = (millis / 1000 / 60).round();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
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
                child: _getAppIcon(pkg),
              ),
              title: Text(
                _getAppName(pkg),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
                  "$mins min",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDemoChart() {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: [
            makeGroup(0, 50),
            makeGroup(1, 120),
            makeGroup(2, 30),
            makeGroup(3, 80),
            makeGroup(4, 20),
            makeGroup(5, 75),
            makeGroup(6, 140, isToday: true),
          ],
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return Text(days[val.toInt() % 7]);
                },
              ),
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  BarChartGroupData makeGroup(int x, double y, {bool isToday = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isToday ? Colors.amber : Colors.blueAccent,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildLocationTab() {
    final loc = _data['location'] as Map<String, dynamic>;
    final lat = loc['lat'] as double;
    final lng = loc['lng'] as double;
    final point = LatLng(lat, lng);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(initialCenter: point, initialZoom: 14),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.anand.guardian',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: point,
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderStrokeWidth: 2,
                  borderColor: Colors.blue,
                  radius: 500,
                  useRadiusInMeter: true,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Last Known Location",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  Text("Lat: $lat, Lng: $lng"),
                  Row(
                    children: [
                      const Icon(Icons.shield, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        "Safe Zone: Active (500m)",
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                  Text(
                    "Updated: Just now",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsTab() {
    final apps = (_data['app_usage'] as Map<String, dynamic>).keys.toList();
    final blocked = List<String>.from(_data['blocked_apps'] ?? []);
    final bedtime = _data['bedtime'] as Map<String, dynamic>;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Bedtime Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.indigo.shade900, Colors.deepPurple],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.nights_stay, color: Colors.amber),
                    const SizedBox(width: 12),
                    Text(
                      "Bedtime Mode",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: bedtime['enabled'],
                      activeColor: Colors.amber,
                      onChanged: (val) {
                        setState(() {
                          bedtime['enabled'] = val;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Demo: Bedtime ${val ? 'Enabled' : 'Disabled'}",
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ],
                ),
                if (bedtime['enabled'])
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _demoTimePicker("Starts", bedtime['start']),
                        const Icon(Icons.arrow_forward, color: Colors.white54),
                        _demoTimePicker("Ends", bedtime['end']),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "App Controls (DEMO)",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: apps.length,
          itemBuilder: (ctx, index) {
            final pkg = apps[index];
            final isBlocked = blocked.contains(pkg);

            return GestureDetector(
              onTap: () {
                if (isBlocked) {
                  setState(() {
                    blocked.remove(pkg);
                    _data['blocked_apps'] = blocked;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Demo: Unblocked ${_getAppName(pkg)}"),
                    ),
                  );
                } else {
                  _showDemoLimitDialog(pkg, blocked);
                }
              },
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isBlocked ? Colors.white : Colors.grey.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: isBlocked
                          ? ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Colors.grey,
                                BlendMode.saturation,
                              ),
                              child: _getAppIcon(pkg),
                            )
                          : _getAppIcon(pkg),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        _getAppName(pkg),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isBlocked ? Colors.red : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isBlocked) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 12, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            "Blocked",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _demoTimePicker(String label, String time) {
    return GestureDetector(
      onTap: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (t != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Demo: Time Updated!")));
        }
      },
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white70)),
          Text(
            time,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDemoLimitDialog(String pkg, List<String> blocked) {
    int selectedHours = 1;
    int selectedMinutes = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Manage ${_getAppName(pkg)}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text("Block App Needed"),
                  onTap: () {
                    setState(() {
                      blocked.add(pkg);
                      _data['blocked_apps'] = blocked;
                    });
                    Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Demo: Blocked ${_getAppName(pkg)}"),
                        ),
                      );
                      _simulateRequest(pkg, _data['name']);
                    }
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
                    // Save mock limit
                    setState(() {
                      if (_data['app_limits'] == null) {
                        _data['app_limits'] = <String, dynamic>{};
                      }
                      final totalMins = (selectedHours * 60) + selectedMinutes;
                      if (totalMins > 0) {
                        _data['app_limits'][pkg] = totalMins;
                      } else {
                        _data['app_limits'].remove(pkg);
                      }
                    });
                    Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Demo: Limit set to ${selectedHours}h ${selectedMinutes}m",
                          ),
                        ),
                      );
                      if ((selectedHours * 60 + selectedMinutes) > 0) {
                        _simulateRequest(pkg, _data['name'], type: 'time');
                      }
                    }
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

  void _simulateRequest(
    String pkg,
    String childName, {
    String type = 'unblock',
  }) {
    final appName = pkg.split('.').last;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          type == 'unblock'
              ? "Simulating: $childName is reacting to block..."
              : "Simulating: $childName requesting more time...",
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      final newRequest = {
        'childName': childName,
        'appName': appName,
        'requestedDuration': type == 'unblock'
            ? -1
            : 30, // -1 for Unblock, 30 for time
        'timestamp': Timestamp.now(),
        'status': 'pending',
      };

      DemoData.requests.insert(0, newRequest); // Add to top

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.indigo,
          content: Row(
            children: [
              const Icon(Icons.mail, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "📩 New Request from $childName: ${type == 'unblock' ? 'Unblock' : 'More time for'} $appName",
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "VIEW",
            textColor: Colors.amber,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    });
  }
}
