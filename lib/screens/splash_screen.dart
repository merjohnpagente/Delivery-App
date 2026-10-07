import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import 'auth/login_screen.dart';

/// Clean onboarding splash: hero image, brand, tagline, single CTA.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heroH = Responsive.heroHeight(context);
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              AppRadius.xxl),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withOpacity(0.18),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              AppRadius.xxl),
                          child: Image.asset(
                            'assets/images/cover-image.png',
                            height: heroH,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(
                              height: heroH,
                              color: AppColors.primary
                                  .withOpacity(0.08),
                              child: const Icon(
                                Icons.delivery_dining,
                                size: 120,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      Text(
                        'BINGS',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Delicious food delivered\nright to your doorstep',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          height: 1.6,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text('Get Started'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
