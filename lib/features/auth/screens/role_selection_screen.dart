import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'parent_login_screen.dart';
import 'child_login_screen.dart';
import '../../demo/screens/demo_parent_dashboard_screen.dart';
import '../../shared/widgets/animated_background.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: const Color(0xFF2D3142),
                    ),
                    children: [
                      const TextSpan(text: 'Welcome to\n'),
                      TextSpan(
                        text: 'Guardian',
                        style: TextStyle(color: const Color(0xFF2575FC)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
                const SizedBox(height: 16),
                Text(
                      'Choose your role to get started',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600], // Grey text
                        fontSize: 18,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                const Spacer(),
                _RoleCard(
                      title: 'Parent',
                      description: 'Monitor and manage child activity',
                      icon: Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      textColor: const Color(0xFF6A11CB),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ParentLoginScreen(),
                          ),
                        );
                      },
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideX(begin: -0.2, end: 0),
                const SizedBox(height: 24),
                _RoleCard(
                      title: 'Child',
                      description: 'Join family and share stats',
                      icon: Icons.child_care_rounded,
                      color: Colors.white,
                      textColor: const Color(0xFF2575FC),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChildLoginScreen(),
                          ),
                        );
                      },
                    )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms)
                    .slideX(begin: 0.2, end: 0),
                const Spacer(),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DemoParentDashboardScreen(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.slideshow_rounded,
                      color: Colors.grey[600],
                    ),
                    label: Text(
                      "Try Demo Simulation",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: textColor, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[300],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
