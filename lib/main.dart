import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/pairing/services/pairing_service.dart';
import 'features/dashboard/parent/screens/parent_dashboard_screen.dart';
import 'features/dashboard/child/screens/child_dashboard_screen.dart';
import 'features/blocking/screens/blocking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // This will fail if google-services.json is missing
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    // We continue so the UI can still be seen/tested to some extent
  }

  runApp(const GuardianApp());
}

class GuardianApp extends StatefulWidget {
  const GuardianApp({super.key});

  @override
  State<GuardianApp> createState() => _GuardianAppState();
}

class _GuardianAppState extends State<GuardianApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBlockingStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBlockingStatus();
    }
  }

  Future<void> _checkBlockingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isBlocking = prefs.getBool('is_blocking_active') ?? false;

    // If blocking is active AND we are not already on the blocking screen (simple check)
    // A more robust check would use a global navigator key or route observer.
    // For now, if active, we push.
    if (isBlocking && mounted) {
      // We use a slight delay to ensure context is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const BlockingScreen()),
            (route) => false, // Clear stack so they can't go back
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<PairingService>(create: (_) => PairingService()),
      ],
      child: MaterialApp(
        title: 'Guardian',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: FutureBuilder<String?>(
          future: AuthService().autoLogin(),
          builder: (context, snapshot) {
            // If blocking is active, we might want to override home, but _checkBlockingStatus handles it.
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData) {
              if (snapshot.data == 'parent') {
                return const ParentDashboardScreen();
              } else if (snapshot.data == 'child') {
                return const ChildDashboardScreen();
              }
            }
            return const RoleSelectionScreen();
          },
        ),
      ),
    );
  }
}
