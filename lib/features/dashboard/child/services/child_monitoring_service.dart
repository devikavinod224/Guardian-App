import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:intl/intl.dart';

// Entry point for the background service
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Initialize Firebase inside background isolate
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init failed in bg: $e");
  }

  // Periodic task
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Guardian Active",
          content: "Monitoring device usage...",
        );
      }
    }

    try {
      await _performMonitoring(service);
    } catch (e) {
      debugPrint("Monitoring error: $e");
    }

    // Send data update to UI if needed
    service.invoke('update');
  });

  // Output "Child Service Started" for debugging
  debugPrint("Child Monitoring Service Started");

  // Speed Detection Stream (Driving Safety)
  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  ).listen((position) async {
    final speedKmh = position.speed * 3.6; // Convert m/s to km/h
    final prefs = await SharedPreferences.getInstance();

    // Threshold: 20 km/h
    if (speedKmh > 20) {
      await prefs.setBool('is_moving_fast', true);
      debugPrint(
        "Guardian: Speed detected: ${speedKmh.toStringAsFixed(1)} km/h",
      );
    } else if (speedKmh < 5) {
      // Only clear if significantly slow to avoid jitter at lights
      await prefs.setBool('is_moving_fast', false);
    }
  });

  // Real-time listener for specific rule updates (Blocking/Limits)
  // This ensures parents' changes apply instantly
  StreamSubscription? rulesSubscription;

  Timer.periodic(const Duration(seconds: 2), (timer) async {
    // ... Fast Loop (Existing Code) ...
    // We need to keep the fast loop running.

    // Initialize listener once if not active
    if (rulesSubscription == null && service is AndroidServiceInstance) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final childId = prefs.getString('child_id');
        if (childId != null) {
          final deviceRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('children')
              .doc(childId);

          rulesSubscription = deviceRef.snapshots().listen((snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data();
              final blockedApps = List<String>.from(
                data?['blocked_apps'] ?? [],
              );
              final appLimits = Map<String, dynamic>.from(
                data?['app_limits'] ?? {},
              );
              final bedtime = Map<String, dynamic>.from(data?['bedtime'] ?? {});

              prefs.setStringList('blocked_apps_cache', blockedApps);
              prefs.setString('app_limits_cache', jsonEncode(appLimits));
              prefs.setString('bedtime_cache', jsonEncode(bedtime));
              debugPrint("Guardian: Rules updated via Stream (incl. Bedtime)!");
            }
          });
        }
      }
    }

    if (service is AndroidServiceInstance) {
      if (!(await service.isForegroundService())) return;
    }
    // ... rest of fast loop ...

    try {
      // 1. Get Top App
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(
        const Duration(minutes: 1),
      ); // Short window
      List<UsageInfo> usage = await UsageStats.queryUsageStats(
        startDate,
        endDate,
      );

      // Sort by last time used
      usage.sort(
        (a, b) => (b.lastTimeUsed ?? '0').compareTo(a.lastTimeUsed ?? '0'),
      );

      if (usage.isNotEmpty) {
        final currentApp = usage.first.packageName;
        if (currentApp == null) return;

        // 2. Check against Local Cache
        final prefs = await SharedPreferences.getInstance();
        final blockedApps = prefs.getStringList('blocked_apps_cache') ?? [];
        final appLimitsJson = prefs.getString('app_limits_cache');
        final bedtimeJson = prefs.getString('bedtime_cache');

        Map<String, int> appLimits = {};
        if (appLimitsJson != null) {
          final decoded = jsonDecode(appLimitsJson) as Map<String, dynamic>;
          appLimits = decoded.map((key, value) => MapEntry(key, value as int));
        }

        bool shouldBlock = false;
        String blockReason =
            "access"; // 'access' | 'time_limit' | 'bedtime' | 'focus'

        // Constraint 0: Driving Safety (Critical)
        final isMovingFast = prefs.getBool('is_moving_fast') ?? false;
        if (isMovingFast) {
          final passengerExpiryIso = prefs.getString('passenger_mode_expiry');
          bool isPassenger = false;
          if (passengerExpiryIso != null) {
            final expiry = DateTime.parse(passengerExpiryIso);
            if (expiry.isAfter(DateTime.now())) {
              isPassenger = true;
            }
          }

          if (!isPassenger) {
            shouldBlock = true;
            blockReason = "driving";
            debugPrint("BLOCKING: Driving detected!");
          }
        }

        // Constraint 0: Focus Mode (Highest Priority - Voluntary)
        final focusEndIso = prefs.getString('focus_end_time');
        if (!shouldBlock && focusEndIso != null) {
          final focusEnd = DateTime.parse(focusEndIso);
          if (focusEnd.isAfter(DateTime.now())) {
            shouldBlock = true;
            blockReason = "focus";
            debugPrint("BLOCKING: Focus Mode Active!");
          } else {
            // Cleanup expired focus
            prefs.remove('focus_end_time');
          }
        }

        // Constraint 1: Bedtime (High Priority)
        if (!shouldBlock && bedtimeJson != null) {
          final bedtime = jsonDecode(bedtimeJson) as Map<String, dynamic>;
          if (bedtime['enabled'] == true) {
            final now = TimeOfDay.now();
            final startStr = bedtime['start'] as String? ?? "21:00";
            final endStr = bedtime['end'] as String? ?? "07:00";

            final startHour = int.parse(startStr.split(":")[0]);
            final startMin = int.parse(startStr.split(":")[1]);
            final endHour = int.parse(endStr.split(":")[0]);
            final endMin = int.parse(endStr.split(":")[1]);

            final nowMinutes = now.hour * 60 + now.minute;
            final startMinutes = startHour * 60 + startMin;
            final endMinutes = endHour * 60 + endMin;

            bool isBedtimeNow = false;
            if (startMinutes > endMinutes) {
              // Crosses midnight (e.g. 21:00 to 07:00)
              isBedtimeNow =
                  nowMinutes >= startMinutes || nowMinutes < endMinutes;
            } else {
              // Same day (e.g. 01:00 to 05:00)
              isBedtimeNow =
                  nowMinutes >= startMinutes && nowMinutes < endMinutes;
            }

            if (isBedtimeNow) {
              shouldBlock = true;
              blockReason = "bedtime";
              debugPrint("BLOCKING: Bedtime is active!");
            }
          }
        }

        // Constraint 1: Explicit Block
        if (!shouldBlock && blockedApps.contains(currentApp)) {
          shouldBlock = true;
          debugPrint("BLOCKING: $currentApp is explicitly blocked!");
        }

        // Constraint 2: Time Limit
        if (!shouldBlock && appLimits.containsKey(currentApp)) {
          final limitMins = appLimits[currentApp]!;
          // Check usage for TODAY
          DateTime now = DateTime.now();
          DateTime startOfDay = DateTime(now.year, now.month, now.day);
          List<UsageInfo> todayUsage = await UsageStats.queryUsageStats(
            startOfDay,
            now,
          );
          final appUsage = todayUsage.firstWhere(
            (u) => u.packageName == currentApp,
            orElse: () =>
                UsageInfo(packageName: currentApp, totalTimeInForeground: "0"),
          );

          final usedMillis =
              int.tryParse(appUsage.totalTimeInForeground ?? '0') ?? 0;
          final usedMins = (usedMillis / 1000 / 60).round();

          if (usedMins >= limitMins) {
            shouldBlock = true;
            blockReason = "time_limit";
            debugPrint(
              "BLOCKING: $currentApp reached limit ($usedMins / $limitMins mins)!",
            );
          }
        }

        if (shouldBlock) {
          // SKIP locking if WE are the top app
          if (currentApp == 'com.devika.guardian') return;

          // Set Flag
          await prefs.setBool('is_blocking_active', true);
          await prefs.setString('current_blocked_app', currentApp);
          await prefs.setString('blocking_reason', blockReason); // Pass reason

          // 3. Launch Blocking Screen
          final intent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: 'com.devika.guardian',
            componentName: 'com.devika.guardian.MainActivity',
            flags: [
              Flag.FLAG_ACTIVITY_NEW_TASK,
              Flag.FLAG_ACTIVITY_REORDER_TO_FRONT,
            ],
            // We can pass data to open specific route
            arguments: {'route': '/blocking'},
          );
          await intent.launch();
        } else {
          // If we are in a safe app (and it's not us), clear the flag
          if (currentApp != 'com.devika.guardian') {
            await prefs.setBool('is_blocking_active', false);
            await prefs.remove('current_blocked_app');
            await prefs.remove('blocking_reason');
          }
        }
      }
    } catch (e) {
      // debugPrint("Enforcement error: $e"); // Noisy
    }
  });
}

Future<void> _performMonitoring(ServiceInstance service) async {
  final prefs = await SharedPreferences.getInstance();
  final parentUid = prefs.getString('parent_uid'); // Saved during login
  final deviceId = prefs.getString('device_id');

  if (parentUid == null || deviceId == null) return;

  // 1. Get Location
  Position? position;
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        position = await Geolocator.getCurrentPosition();
      }
    }
  } catch (e) {
    debugPrint("Location error: $e");
  }

  // 2. Get Usage Stats (Last 24 hours)
  List<UsageInfo> usage = [];
  try {
    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(const Duration(days: 1));
    usage = await UsageStats.queryUsageStats(startDate, endDate);
  } catch (e) {
    debugPrint("Usage stats error: $e");
  }

  // 3. Sync to Firestore
  try {
    final deviceRef = FirebaseFirestore.instance
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(deviceId);

    Map<String, dynamic> updateData = {
      'last_active': FieldValue.serverTimestamp(),
    };

    if (position != null) {
      updateData['location'] = {
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      };
    }

    // Process usage stats (basic summary)
    Map<String, int> appUsageMap = {};
    int totalScreenTime = 0;
    for (var u in usage) {
      if (u.packageName != null) {
        final time = (int.tryParse(u.totalTimeInForeground ?? '0') ?? 0);
        appUsageMap[u.packageName!] = (appUsageMap[u.packageName!] ?? 0) + time;
        totalScreenTime += time;
      }
    }
    appUsageMap.removeWhere((key, value) => value == 0);
    updateData['app_usage'] = appUsageMap;
    updateData['total_screen_time'] = totalScreenTime;

    // 4. Sync Installed Apps (Smart Sync)
    try {
      // Check for changes (optimization)
      List<AppInfo> apps = await InstalledApps.getInstalledApps(false, true);
      apps.sort((a, b) => a.packageName.compareTo(b.packageName));
      final currentFingerprint = apps.map((e) => e.packageName).join(',');
      final savedFingerprint = prefs.getString('apps_fingerprint');

      if (savedFingerprint != currentFingerprint) {
        debugPrint("Guardian: App list changed, syncing...");

        // Fetch full details with icons
        final appsWithIcons = await InstalledApps.getInstalledApps(true, true);
        final batch = FirebaseFirestore.instance.batch();
        final appsCollection = deviceRef.collection('apps');

        // 1. Sync current apps
        for (var app in appsWithIcons) {
          final docRef = appsCollection.doc(app.packageName);
          final data = {
            'name': app.name,
            'packageName': app.packageName,
            'version': app.versionName,
            'last_synced': FieldValue.serverTimestamp(),
          };

          // Only update icon if it's new (to save bandwidth, though local check is basic)
          // Actually, always sending icon is safer for now to ensure it exists.
          if (app.icon != null) {
            data['icon'] = base64Encode(app.icon!);
          }

          // Use merge: true to avoid overwriting existing rules (blocked status, etc.)
          batch.set(docRef, data, SetOptions(merge: true));
        }

        // 2. Remove uninstalled apps from Firestore
        final existingDocs = await appsCollection.get();
        for (var doc in existingDocs.docs) {
          if (!appsWithIcons.any((a) => a.packageName == doc.id)) {
            batch.delete(doc.reference);
          }
        }

        await batch.commit();
        await prefs.setString('apps_fingerprint', currentFingerprint);
        debugPrint("Guardian: App sync complete.");
      }
    } catch (e) {
      debugPrint("App sync error: $e");
    }

    // updateData['installed_apps'] = ... (Legacy field removed)
    await deviceRef.update(updateData);

    // 4b. Sync Daily Stats (New for Phase 6)
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final statsRef = deviceRef.collection('stats').doc(dateStr);

      await statsRef.set({
        'total_minutes': (totalScreenTime / 1000 / 60).round(),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Stats sync error: $e");
    }

    // 5. Check for blocks and Limits
    final docSnapshot = await deviceRef.get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      final blockedApps = List<String>.from(data?['blocked_apps'] ?? []);
      final appLimits = Map<String, dynamic>.from(data?['app_limits'] ?? {});

      // Update Local Cache for Fast Loop
      await prefs.setStringList('blocked_apps_cache', blockedApps);
      await prefs.setString('app_limits_cache', jsonEncode(appLimits));

      // 6. Geofencing Check
      if (position != null && data != null && data['safe_zone'] != null) {
        try {
          final safeZone = data['safe_zone'];
          final double safeLat = safeZone['lat'];
          final double safeLng = safeZone['lng'];
          final double radius = (safeZone['radius'] as num).toDouble();

          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            safeLat,
            safeLng,
          );

          // Update Safe Status
          // If distance > radius => Unsafe (false).
          // We explicitly update this field.
          final bool isSafe = distance <= radius;

          // Only update if changed to avoid write spam?
          // For now, simple update is fine as we are already writing updateData.
          // However, updateData was already committed above. We should add this to updateData BEFORE commit.

          // RETROACTIVE FIX: Since we already called deviceRef.update(updateData) above at Step 4,
          // we need to do another update here or move this logic up.
          // To be cleaner, I'll do a separate update for safety status if it changed or just update it now.

          await deviceRef.update({'is_safe': isSafe});
        } catch (e) {
          debugPrint("Geofencing error: $e");
        }
      }

      for (var u in usage) {
        if (u.packageName == null) continue;

        // Check if Blocked
        if (blockedApps.contains(u.packageName)) {
          debugPrint("BLOCKING: ${u.packageName} is blocked!");
          // Logic to minimize/kill sends a notification for now
        }

        // Check Limits
        if (appLimits.containsKey(u.packageName)) {
          final limitMinutes = appLimits[u.packageName] as int;
          final currentMinutes =
              (int.parse(u.totalTimeInForeground!) / 1000 / 60).round();

          if (currentMinutes >= limitMinutes) {
            debugPrint("LIMIT REACHED: ${u.packageName}");
          }
        }
      }
    }
  } catch (e) {
    debugPrint("Firestore sync error: $e");
  }
}

class ChildMonitoringService {
  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'guardian_channel',
      'Guardian Service',
      description: 'Used for monitoring child activity',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'guardian_channel',
        initialNotificationTitle: 'Guardian Active',
        initialNotificationContent: 'Initializing monitoring...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: (service) {
          onStart(service);
          return true;
        },
      ),
    );

    service.startService();
  }
}
