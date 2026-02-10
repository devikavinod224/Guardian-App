import 'package:cloud_firestore/cloud_firestore.dart';

class DemoData {
  static final List<Map<String, dynamic>> children = [
    {
      'id': 'child_1',
      'name': 'Alex',
      'total_screen_time': 14500000, // ~4 hours
      'is_safe': true,
      'last_active': Timestamp.now(),
      'location': {
        'lat': 40.7128,
        'lng': -74.0060,
        'timestamp': Timestamp.now(),
      }, // New York
      'app_usage': {
        'com.instagram.android': 5400000,
        'com.whatsapp': 3600000,
        'com.twitter.android': 2400000,
      },
      'bonus_time': 15,
      'bedtime': {'enabled': true, 'start': '21:00', 'end': '07:00'},
      'blocked_apps': [],
    },
    {
      'id': 'child_2',
      'name': 'Sarah',
      'total_screen_time': 7200000, // ~2 hours
      'is_safe': false, // Unsafe!
      'last_active': Timestamp.now(), // Online
      'location': {
        'lat': 40.7580,
        'lng': -73.9855,
        'timestamp': Timestamp.now(),
      }, // Times Square
      'app_usage': {
        'com.facebook.katana': 3600000,
        'com.linkedin.android': 1800000,
      },
      'bonus_time': 0,
      'bedtime': {'enabled': false, 'start': '22:00', 'end': '06:00'},
      'blocked_apps': [],
    },
    {
      'id': 'child_3',
      'name': 'Mike',
      'total_screen_time': 3600000, // ~1 hour
      'is_safe': true,
      'last_active': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 20)),
      ), // Offline
      'location': {
        'lat': 40.7829,
        'lng': -73.9654,
        'timestamp': Timestamp.now(),
      }, // Central Park
      'app_usage': {'com.whatsapp': 1200000, 'com.instagram.android': 2400000},
      'bonus_time': 30,
      'bedtime': {'enabled': true, 'start': '20:30', 'end': '06:30'},
      'blocked_apps': ['com.instagram.android'],
    },
    {
      'id': 'child_4',
      'name': 'Emma',
      'total_screen_time': 18000000, // ~5 hours (High Usage!)
      'is_safe': true,
      'last_active': Timestamp.now(),
      'location': {
        'lat': 34.0522,
        'lng': -118.2437,
        'timestamp': Timestamp.now(),
      }, // LA
      'app_usage': {
        'com.twitter.android': 14400000,
        'com.facebook.katana': 3600000,
      },
      'bonus_time': 0,
      'bedtime': {'enabled': true, 'start': '21:00', 'end': '07:00'},
      'blocked_apps': [],
    },
    {
      'id': 'child_5',
      'name': 'Lucas',
      'total_screen_time': 900000, // ~15 mins
      'is_safe': true,
      'last_active': Timestamp.now(),
      'location': {
        'lat': 51.5074,
        'lng': -0.1278,
        'timestamp': Timestamp.now(),
      }, // London
      'app_usage': {'com.linkedin.android': 900000}, // Productive!
      'bonus_time': 45,
      'bedtime': {'enabled': true, 'start': '21:00', 'end': '07:00'},
      'blocked_apps': [],
      'is_sos': false,
      'is_focus': false,
    },
    {
      'id': 'child_5',
      'name': 'Lucas',
      'total_screen_time': 900000, // ~15 mins
      'is_safe': true,
      'last_active': Timestamp.now(),
      'location': {
        'lat': 51.5074,
        'lng': -0.1278,
        'timestamp': Timestamp.now(),
      }, // London
      'app_usage': {'com.duolingo': 900000}, // Productive!
      'bonus_time': 45,
      'bedtime': {'enabled': true, 'start': '21:30', 'end': '07:30'},
      'blocked_apps': [],
      'is_sos': false,
      'is_focus': true, // Lucas is focusing!
    },
  ];

  static Map<String, dynamic>? currentSosChild; // To simulate active SOS

  static final List<Map<String, dynamic>> requests = [
    {
      'childName': 'Sarah',
      'appName': 'Snapchat',
      'requestedDuration': 30,
      'timestamp': Timestamp.now(),
      'status': 'pending',
    },
    {
      'childName': 'Emma',
      'appName': 'Roblox',
      'requestedDuration': 60,
      'timestamp': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      'status': 'pending',
    },
  ];
}
