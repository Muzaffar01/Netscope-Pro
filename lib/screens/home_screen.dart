import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:netscope/providers/theme_provider.dart';
import 'package:netscope/providers/search_provider.dart';
import 'package:netscope/providers/history_provider.dart';
import 'package:netscope/screens/result_screen.dart';
import 'package:netscope/screens/history_screen.dart';
import 'package:netscope/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _pulseController;
  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    _bgAnimController.dispose();
    super.dispose();
  }

  void _performSearch([int initialTabIndex = 0]) async {
    final domain = _urlController.text.trim();
    if (domain.isEmpty) {
      _focusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a domain or URL first'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate domain format
    final domainRegex = RegExp(
      r'^(https?://)?([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}(/.*)?$',
    );
    if (!domainRegex.hasMatch(domain)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid domain (e.g., google.com)'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    _focusNode.unfocus();

    final searchProvider = context.read<SearchProvider>();
    await searchProvider.searchWebsite(domain);

    if (!mounted) return;

    if (searchProvider.state == SearchState.loaded) {
      final historyProvider = context.read<HistoryProvider>();
      historyProvider.addToHistory(
        searchProvider.currentDomain,
        title: searchProvider.websiteInfo?.domainInfo?.title,
      );

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ResultScreen(initialTabIndex: initialTabIndex),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else if (searchProvider.state == SearchState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(searchProvider.errorMessage),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final searchProvider = context.watch<SearchProvider>();
    final isDark = themeProvider.isDark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background gradient orbs
          _buildAnimatedBackground(isDark, size),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.radar, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'NetScope Pro',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.history_rounded),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const HistoryScreen()),
                              );
                            },
                            tooltip: 'Search History',
                          ),
                          IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                key: ValueKey(isDark),
                              ),
                            ),
                            onPressed: () => themeProvider.toggleTheme(),
                            tooltip: 'Toggle Theme',
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: size.height * 0.08),

                        // Hero icon with animation
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.15 + _pulseController.value * 0.1),
                                    AppColors.accent.withValues(alpha: 0.1 + _pulseController.value * 0.08),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.2 + _pulseController.value * 0.15),
                                    blurRadius: 30 + _pulseController.value * 20,
                                    spreadRadius: _pulseController.value * 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.travel_explore_rounded,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            );
                          },
                        ).animate().fadeIn(duration: 600.ms).scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1, 1),
                              curve: Curves.elasticOut,
                              duration: 800.ms,
                            ),

                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Explore Any Website',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.3),

                        const SizedBox(height: 12),

                        Text(
                          'Get server info, DNS records, WHOIS data,\nand visualize network routes in real-time',
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white54 : Colors.black45,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 350.ms, duration: 500.ms),

                        const SizedBox(height: 48),

                        // Search input
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _urlController,
                            focusNode: _focusNode,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter domain (e.g., google.com)',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black26,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 16, right: 8),
                                child: Icon(
                                  Icons.language_rounded,
                                  color: AppColors.primary.withValues(alpha: 0.7),
                                ),
                              ),
                              suffixIcon: _urlController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 20),
                                      onPressed: () {
                                        _urlController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkCard.withValues(alpha: 0.8)
                                  : Colors.white.withValues(alpha: 0.9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder.withValues(alpha: 0.5)
                                      : AppColors.lightBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _performSearch(),
                            textInputAction: TextInputAction.search,
                          ),
                        ).animate().fadeIn(delay: 500.ms, duration: 500.ms).slideY(begin: 0.2),

                        const SizedBox(height: 20),

                        // Analyze button
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: searchProvider.state == SearchState.loading
                              ? _buildLoadingButton(isDark)
                              : ElevatedButton(
                                  onPressed: () => _performSearch(0),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.search_rounded, size: 22),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Analyze Website',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ).animate().fadeIn(delay: 650.ms, duration: 500.ms).slideY(begin: 0.2),

                        const SizedBox(height: 48),

                        // Feature cards
                        _buildFeatureCards(isDark),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Analyzing...',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark, Size size) {
    return AnimatedBuilder(
      animation: _bgAnimController,
      builder: (context, _) {
        return CustomPaint(
          size: size,
          painter: _BackgroundPainter(
            isDark: isDark,
            animationValue: _bgAnimController.value,
          ),
        );
      },
    );
  }

  Widget _buildFeatureCards(bool isDark) {
    final features = [
      {
        'icon': Icons.dns_rounded,
        'label': 'DNS Records',
        'desc': 'A, AAAA, MX, TXT',
        'color': AppColors.accent,
        'tabIndex': 3,
      },
      {
        'icon': Icons.route_rounded,
        'label': 'Traceroute',
        'desc': 'Visual network path',
        'color': AppColors.primary,
        'tabIndex': 2,
      },
      {
        'icon': Icons.security_rounded,
        'label': 'WHOIS Info',
        'desc': 'Registration details',
        'color': AppColors.accentSecondary,
        'tabIndex': 3,
      },
      {
        'icon': Icons.speed_rounded,
        'label': 'Ping Test',
        'desc': 'Response latency',
        'color': AppColors.success,
        'tabIndex': 0,
      },
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(features.length, (index) {
        final f = features[index];
        final tabIndex = f['tabIndex'] as int;

        return GestureDetector(
          onTap: () {
            if (_urlController.text.trim().isNotEmpty) {
              _performSearch(tabIndex);
            } else {
              _focusNode.requestFocus();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Enter a domain to use the ${f['label']} tool'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.primary,
                ),
              );
            }
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - 60) / 2,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCard.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (f['color'] as Color).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (f['color'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  f['icon'] as IconData,
                  color: f['color'] as Color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                f['label'] as String,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                f['desc'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        )).animate().fadeIn(
              delay: Duration(milliseconds: 800 + index * 100),
              duration: 400.ms,
            ).slideY(begin: 0.2).scale(begin: const Offset(0.95, 0.95));
      }),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final bool isDark;
  final double animationValue;

  _BackgroundPainter({required this.isDark, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // First orb
    final orb1Center = Offset(
      size.width * (0.2 + 0.1 * _sin(animationValue)),
      size.height * (0.15 + 0.05 * _cos(animationValue * 1.3)),
    );
    paint.shader = RadialGradient(
      colors: [
        AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
        AppColors.primary.withValues(alpha: 0),
      ],
    ).createShader(Rect.fromCircle(center: orb1Center, radius: 200));
    canvas.drawCircle(orb1Center, 200, paint);

    // Second orb
    final orb2Center = Offset(
      size.width * (0.8 + 0.08 * _cos(animationValue * 0.7)),
      size.height * (0.6 + 0.06 * _sin(animationValue * 1.1)),
    );
    paint.shader = RadialGradient(
      colors: [
        AppColors.accent.withValues(alpha: isDark ? 0.06 : 0.04),
        AppColors.accent.withValues(alpha: 0),
      ],
    ).createShader(Rect.fromCircle(center: orb2Center, radius: 250));
    canvas.drawCircle(orb2Center, 250, paint);

    // Third orb
    final orb3Center = Offset(
      size.width * (0.5 + 0.12 * _sin(animationValue * 0.5)),
      size.height * (0.85 + 0.04 * _cos(animationValue * 0.9)),
    );
    paint.shader = RadialGradient(
      colors: [
        AppColors.accentSecondary.withValues(alpha: isDark ? 0.05 : 0.03),
        AppColors.accentSecondary.withValues(alpha: 0),
      ],
    ).createShader(Rect.fromCircle(center: orb3Center, radius: 180));
    canvas.drawCircle(orb3Center, 180, paint);
  }

  double _sin(double t) => 
    (t * 3.14159 * 2).abs() < 1e-10 ? 0 : 
    _sinApprox(t * 3.14159 * 2);
    
  double _cos(double t) => _sin(t + 0.25);
  
  double _sinApprox(double x) {
    // Normalize to [-pi, pi]
    while (x > 3.14159) { x -= 6.28318; }
    while (x < -3.14159) { x += 6.28318; }
    // Taylor approximation
    double x3 = x * x * x;
    double x5 = x3 * x * x;
    return x - x3 / 6.0 + x5 / 120.0;
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => true;
}
