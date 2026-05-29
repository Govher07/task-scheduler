import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.forceShow = false});

  final bool forceShow;

  static const seenWelcomeKey = 'has_seen_welcome_v1';

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();

  bool _checkingStatus = true;
  int _currentPage = 0;

  static const List<_WelcomePageData> _pages = [
    _WelcomePageData(
      icon: Icons.fact_check_outlined,
      title: 'Plan. Prioritize.\nGet it done.',
      subtitle:
          'A simple scheduler to help\nyou stay focused and\nachieve more every day.',
    ),
    _WelcomePageData(
      icon: Icons.flag_outlined,
      title: 'Organize your\ngoals and tasks.',
      subtitle:
          'Break big goals into smaller\ntasks and track your progress\nstep by step.',
    ),
    _WelcomePageData(
      icon: Icons.lightbulb_outline,
      title: 'Get smart task\nrecommendations.',
      subtitle:
          'Let the app suggest what to\nwork on next based on priority,\neffort, and deadlines.',
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _checkWelcomeStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkWelcomeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool(WelcomeScreen.seenWelcomeKey) ?? false;

    if (!mounted) return;

    if (hasSeenWelcome && !widget.forceShow) {
      context.go('/home');
      return;
    }

    setState(() {
      _checkingStatus = false;
    });
  }

  Future<void> _continueToApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(WelcomeScreen.seenWelcomeKey, true);

    if (!mounted) return;

    context.go('/home');
  }

  Future<void> _goToNextPage() async {
    if (_isLastPage) {
      await _continueToApp();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goToPage(int index) async {
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingStatus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _continueToApp,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return _WelcomePage(page: _pages[index]);
                      },
                    ),
                  ),

                  _PageDots(
                    count: _pages.length,
                    currentIndex: _currentPage,
                    onDotPressed: _goToPage,
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: _goToNextPage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 1.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isLastPage ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 20,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomePageData {
  const _WelcomePageData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.page});

  final _WelcomePageData page;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _WelcomeIllustration(icon: page.icon),
            const SizedBox(height: 28),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 31,
                height: 1.18,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                height: 1.38,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 175,
      width: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(top: 10, left: 48, child: _Sparkle(size: 16)),
          const Positioned(top: 62, left: 16, child: _Sparkle(size: 22)),
          const Positioned(top: 14, right: 54, child: _Sparkle(size: 16)),
          const Positioned(top: 70, right: 20, child: _Sparkle(size: 22)),

          Container(
            width: 116,
            height: 136,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Icon(icon, size: 68, color: Colors.black),
          ),

          Positioned(
            right: 54,
            bottom: 16,
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(
                Icons.arrow_forward,
                size: 28,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome, size: size, color: Colors.black);
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.currentIndex,
    required this.onDotPressed,
  });

  final int count;
  final int currentIndex;
  final ValueChanged<int> onDotPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: GestureDetector(
            onTap: () => onDotPressed(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: isActive ? 28 : 14,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: isActive ? Colors.black : Colors.white,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
            ),
          ),
        );
      }),
    );
  }
}
