import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final StorageService _storage = StorageService();
  int _currentPage = 0;
  Timer? _autoNavTimer;

  late AnimationController _ambientController;
  late Animation<double> _ambientAnimation;

  final List<Map<String, dynamic>> _slides = [
    {
      'badge': 'NEW GENERATION',
      'title': 'Welcome to\nNowtifried',
      'subtitle':
          'Your personal student command center. Designed with frosted translucent surfaces and crafted for effortless academic excellence.',
      'icon': CupertinoIcons.sparkles,
      'accent': const Color(0xFF6C5CE7),
      'features': [
        'Curated for Modern Students',
        'Intuitive Academic Organization',
        'Clean, Focused Workflow',
      ],
    },
    {
      'badge': 'TIMETABLE & CLASS ALERTS',
      'title': 'Class Schedules\n& Timetable',
      'subtitle':
          'Track your full subject timetable with real-time countdowns, recurring days of the week, and instant classroom directions.',
      'icon': CupertinoIcons.book_fill,
      'accent': const Color(0xFF5960A0),
      'features': [
        'Live Class Countdowns',
        'Recurring Lecture Days',
        'Room & Instructor Info',
      ],
    },
    {
      'badge': 'UNIFIED TIMELINE',
      'title': 'Interactive\nStudent Calendar',
      'subtitle':
          'Visualize every school day at a glance. Seamlessly connect upcoming lectures, exam dates, and deliverables in a clean calendar grid.',
      'icon': CupertinoIcons.calendar_today,
      'accent': const Color(0xFF0984E3),
      'features': [
        'Monthly & Daily Views',
        'Color-Coded Event Dots',
        'Direct Agenda Inspection',
      ],
    },
    {
      'badge': 'DEADLINE MANAGER',
      'title': 'Quizzes, Exams\n& Activities',
      'subtitle':
          'Never miss a crucial deadline. Categorize quizzes, major exams, group projects, and homework with priority badges and subtask checklists.',
      'icon': CupertinoIcons.checkmark_shield_fill,
      'accent': const Color(0xFFFF9500),
      'features': [
        'Quizzes, Exams & Homework',
        'High/Medium/Low Priority',
        'Interactive Checklist Steps',
      ],
    },
    {
      'badge': 'STUDY REVIEWERS',
      'title': 'Quick Notes\n& Reviewers',
      'subtitle':
          'Jot down study summaries, formula cheat-sheets, and quiz notes right when inspiration strikes. Pin crucial reviewers to the top.',
      'icon': CupertinoIcons.doc_text_fill,
      'accent': const Color(0xFF00B894),
      'features': [
        'Quiz & Exam Tags',
        'Pin Important Reviewers',
        'Distraction-free Writing',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _ambientAnimation = CurvedAnimation(
      parent: _ambientController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _autoNavTimer?.cancel();
    _pageController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _finishOnboarding() async {
    _autoNavTimer?.cancel();
    await _storage.markOnboardingSeen();
    widget.onCompleted();
  }

  void _onNextTap() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    if (index == _slides.length - 1) {
      // Auto-advance to dashboard after 2.5 seconds if user pauses on the last page
      _autoNavTimer?.cancel();
      _autoNavTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) {
          _finishOnboarding();
        }
      });
    } else {
      _autoNavTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSlide = _slides[_currentPage];
    final Color currentAccent = currentSlide['accent'] as Color;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF10121D) : const Color(0xFFCCD2F8),
      body: Stack(
        children: [
          // ── Ambient Animated Glow Orbs in Background ──
          AnimatedBuilder(
            animation: _ambientAnimation,
            builder: (context, child) {
              final val = _ambientAnimation.value;
              return Stack(
                children: [
                  Positioned(
                    top: -60 + (val * 30),
                    left: -40 + (val * 20),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentAccent.withOpacity(0.35),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80 + (val * 40),
                    right: -50 - (val * 20),
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6C5CE7).withOpacity(0.28),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.4,
                    right: -70 + (val * 25),
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00B894).withOpacity(0.2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Blur backdrop filter layer for smooth ambient depth ──
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(color: Colors.transparent),
            ),
          ),

          // ── Main Page Content ──
          SafeArea(
            child: Column(
              children: [
                // Top Bar with Skip
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: currentAccent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: currentAccent.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'N',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Nowtifried',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _finishOnboarding,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // PageView with Features
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final item = _slides[index];
                      final IconData icon = item['icon'] as IconData;
                      final Color accent = item['accent'] as Color;
                      final List<String> features =
                          (item['features'] as List).cast<String>();

                      return Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Hero Frosted Icon Plaque
                              GlassContainer(
                                width: 100,
                                height: 100,
                                borderRadius: BorderRadius.circular(32),
                                blur: 24,
                                opacity: isDark ? 0.25 : 0.65,
                                child: Center(
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 32,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),

                              // Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: accent.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  item['badge'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Title
                              Text(
                                item['title'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  fontFamily:
                                      GoogleFonts.plusJakartaSans().fontFamily,
                                  color: isDark
                                      ? AppColors.darkText
                                      : AppColors.textDark,
                                  height: 1.15,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Subtitle
                              Text(
                                item['subtitle'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.textMuted,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Feature Pills
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: features.map((feat) {
                                  return GlassContainer(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    borderRadius: BorderRadius.circular(16),
                                    opacity: isDark ? 0.2 : 0.5,
                                    blur: 10,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons.checkmark_alt_circle_fill,
                                          size: 14,
                                          color: accent,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          feat,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                              ? Colors.white.withOpacity(0.9)
                                              : AppColors.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Controls: Page Indicator & Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Smooth Indicator Dots
                      Row(
                        children: List.generate(_slides.length, (i) {
                          final isSel = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            width: isSel ? 26 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? currentAccent
                                  : (isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.6)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }),
                      ),

                      // Next / Get Started Action Button
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _onNextTap,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: currentAccent,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: currentAccent.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage == _slides.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                CupertinoIcons.arrow_right,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
