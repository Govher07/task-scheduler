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
  bool _checkingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkWelcomeStatus();
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

  @override
  Widget build(BuildContext context) {
    if (_checkingStatus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 28),

                  const _WelcomeIllustration(),

                  const SizedBox(height: 56),

                  const Text(
                    'Plan. Prioritize.\nGet it done.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      height: 1.25,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'A simple scheduler to help\nyou stay focused and\nachieve more every day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      height: 1.5,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 48),

                  const _PageDots(),

                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: OutlinedButton(
                      onPressed: _continueToApp,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 1.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 24,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(top: 12, left: 64, child: _Sparkle(size: 18)),
          const Positioned(top: 74, left: 28, child: _Sparkle(size: 24)),
          const Positioned(top: 18, right: 72, child: _Sparkle(size: 18)),
          const Positioned(top: 82, right: 34, child: _Sparkle(size: 24)),

          Container(
            width: 138,
            height: 158,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              size: 82,
              color: Colors.black,
            ),
          ),

          Positioned(
            right: 92,
            bottom: 26,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(
                Icons.arrow_downward,
                size: 34,
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
  const _PageDots();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(isActive: true),
        SizedBox(width: 16),
        _Dot(isActive: false),
        SizedBox(width: 16),
        _Dot(isActive: false),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.black : Colors.white,
        border: Border.all(color: Colors.black, width: 1.6),
      ),
    );
  }
}
