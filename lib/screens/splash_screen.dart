import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import 'auth/login_screen.dart';

/// Splash: animated rider icon (entrance + gentle float loop),
/// "Dodo food" brand, "By MerjDev", GitHub dev link + BSCS credit.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _float;
  late final Animation<double> _iconFade;
  late final Animation<double> _iconScale;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _authorFade;
  late final Animation<Offset> _authorSlide;
  late final Animation<double> _buttonFade;
  late final Animation<double> _floatDy;

  static const _githubUrl = 'https://github.com/merjohnpagente';

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    // Gentle endless float for the rider icon.
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _floatDy = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _float, curve: Curves.easeInOut),
    );

    _iconFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _iconScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _titleSlide =
        Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
            .animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.3, 0.65, curve: Curves.easeIn),
    );
    _authorSlide =
        Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero)
            .animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _authorFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
    );
    _buttonFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
    );

    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _float.dispose();
    super.dispose();
  }

  void _goLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _openGithub() async {
    final uri = Uri.parse(_githubUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open GitHub link.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconSize =
        Responsive.heroHeight(context, fraction: 0.26, min: 140, max: 220);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
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
                      const SizedBox(height: AppSpacing.md),
                      // Animated rider icon with endless float.
                      FadeTransition(
                        opacity: _iconFade,
                        child: ScaleTransition(
                          scale: _iconScale,
                          child: AnimatedBuilder(
                            animation: _floatDy,
                            builder: (context, child) {
                              return Transform.translate(
                                offset:
                                    Offset(0, _floatDy.value),
                                child: child,
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(36),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withOpacity(0.25),
                                    blurRadius: 30,
                                    offset:
                                        const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(36),
                                child: Image.asset(
                                  'assets/icon/app_icon.png',
                                  height: iconSize,
                                  width: iconSize,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) =>
                                          Container(
                                    height: iconSize,
                                    width: iconSize,
                                    color: AppColors.primary
                                        .withOpacity(0.08),
                                    child: const Icon(
                                      Icons.delivery_dining,
                                      size: 90,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: Text(
                            'Dodo food',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SlideTransition(
                        position: _authorSlide,
                        child: FadeTransition(
                          opacity: _authorFade,
                          child: Text(
                            'By MerjDev',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3,
                              color: AppColors.textDark,
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
                      const SizedBox(height: AppSpacing.xxl),
                      FadeTransition(
                        opacity: _buttonFade,
                        child: ElevatedButton(
                          onPressed: _goLogin,
                          child: const Text('Get Started'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Dev credit: GitHub link + BSCS students.
                      FadeTransition(
                        opacity: _buttonFade,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _openGithub,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.code,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'github.com/merjohnpagente',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                      decoration:
                                          TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Created by MerjDev • BSCS Students',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textGrey,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      ),
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
