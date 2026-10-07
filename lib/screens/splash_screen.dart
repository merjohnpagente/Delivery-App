import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import 'auth/login_screen.dart';

/// Clean onboarding splash with staggered entrance animations:
/// hero image scales in, "Dodo food" slides up, "By Merjdev"
/// fades in, then the CTA button appears.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _imageScale;
  late final Animation<double> _imageFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _authorFade;
  late final Animation<Offset> _authorSlide;
  late final Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _imageFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _imageScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _titleSlide =
        Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
            .animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.65, curve: Curves.easeIn),
    );
    _authorSlide =
        Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero)
            .animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _authorFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
    );
    _buttonFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

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
                      FadeTransition(
                        opacity: _imageFade,
                        child: ScaleTransition(
                          scale: _imageScale,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(
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
                              borderRadius:
                                  BorderRadius.circular(
                                      AppRadius.xxl),
                              child: Image.asset(
                                'assets/images/cover-image.png',
                                height: heroH,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Container(
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
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: Text(
                            'Dodo food',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SlideTransition(
                        position: _authorSlide,
                        child: FadeTransition(
                          opacity: _authorFade,
                          child: Text(
                            'By Merjdev',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FadeTransition(
                        opacity: _authorFade,
                        child: Text(
                          'Delicious food delivered\nright to your doorstep',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      FadeTransition(
                        opacity: _buttonFade,
                        child: ElevatedButton(
                          onPressed: _goLogin,
                          child: const Text('Get Started'),
                        ),
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
