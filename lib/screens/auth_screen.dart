import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService().signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.sandBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo & Branding
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppTheme.goldAccent,
                  size: 48,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),

              const Text(
                'ThreadLenz',
                style: TextStyle(
                  fontSize: 36,
                  fontFamily: 'Playfair Display',
                  fontWeight: FontWeight.bold,
                  color: AppTheme.emeraldPrimary,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),

              Text(
                'AI-Powered Product Photography',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.emeraldPrimary.withValues(alpha: 0.7),
                ),
              ).animate().fadeIn(delay: 400.ms),

              const Spacer(flex: 2),

              // Features list
              _buildFeatureItem(
                icon: Icons.camera_alt_outlined,
                text: 'Upload product photos from any angle',
                delay: 500,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.auto_fix_high,
                text: 'AI generates stunning e-commerce shots',
                delay: 600,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.cloud_outlined,
                text: 'Projects synced across all devices',
                delay: 700,
              ),

              const Spacer(flex: 2),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.textDark,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.emeraldPrimary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                              height: 24,
                              width: 24,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.g_mobiledata,
                                size: 28,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),

              const SizedBox(height: 16),

              Text(
                'By continuing, you agree to our Terms of Service',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
    required int delay,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.emeraldPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.emeraldPrimary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: delay.ms).slideX(begin: -0.1);
  }
}
