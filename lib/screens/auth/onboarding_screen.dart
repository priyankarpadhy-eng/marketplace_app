import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market_app/screens/auth/login_screen.dart';
import 'package:market_app/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback markOnboardingSeen;
  const OnboardingScreen({
    super.key,
    required this.markOnboardingSeen,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Rides",
      description: "Book your ride effortlessly and reach your destination safely.",
      imagePath: "assets/images/onboarding/onboarding_rides.png",
      points: [
        "Share ride",
        "Cost effective",
        "Easy to use",
      ],
    ),
    OnboardingData(
      title: "Food Delivery",
      description: "Cravings? Get your favorite meals delivered hot and fast.",
      imagePath: "assets/images/onboarding/onboarding_food.png",
      points: [
        "Local campus eateries",
        "Zero hidden delivery fees",
        "Fast updates",
      ],
    ),
    OnboardingData(
      title: "Refurbished",
      description: "Shop premium refurbished products at unbeatable prices.",
      imagePath: "assets/images/onboarding/onboarding_refurbished.png",
      points: [
        "Same product low price",
        "Campus students",
        "Self bargain",
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    widget.markOnboardingSeen();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [

            // Carousel Card
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Container (Only borders the image with 4px padding inside)
                      Expanded(
                        flex: 5,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(4, 4, 4, 0), // Outer padding from screen
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                            ],
                            border: isDark ? Border.all(color: Colors.white10) : Border.all(color: Colors.black12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(23), // Matches container border minus 1px
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
                              child: Transform.scale(
                                scale: 1.05, // Slight zoom
                                child: Image.asset(
                                  page.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Icon(Icons.image_outlined, size: 48, color: AppTheme.textSecondary(isDark)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                        // Content directly on page
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  page.title,
                                  style: GoogleFonts.syne(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.02,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  page.description,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    height: 1.6,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ...page.points.map((point) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 4, right: 12),
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, size: 12, color: AppTheme.primary),
                                      ),
                                      Expanded(
                                        child: Text(
                                          point,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                                const Spacer(),
                                // Button
                                GestureDetector(
                                  onTap: () {
                                    if (_currentIndex == _pages.length - 1) {
                                      _finishOnboarding();
                                    } else {
                                      _pageController.nextPage(
                                        duration: const Duration(milliseconds: 350),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF312E81), // Dark indigo like reference
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _currentIndex == _pages.length - 1 ? "Let's Go!" : "Next",
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String imagePath;
  final List<String> points;

  OnboardingData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.points,
  });
}
