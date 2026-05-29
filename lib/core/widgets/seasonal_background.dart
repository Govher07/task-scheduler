import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_controller.dart';

class SeasonalBackground extends ConsumerWidget {
  const SeasonalBackground({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(moodThemeProvider);

    switch (selectedTheme) {
      case MoodTheme.winterFrost:
        return const _WinterWeatherBackground();

      case MoodTheme.springBloom:
        return const _SpringBloomBackground();

      default:
        return const SizedBox.shrink();
    }
  }
}

class SeasonalForegroundSnow extends ConsumerWidget {
  const SeasonalForegroundSnow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(moodThemeProvider);

    switch (selectedTheme) {
      case MoodTheme.winterFrost:
        return const _ForegroundSnowLayer();

      default:
        return const SizedBox.shrink();
    }
  }
}

/* -------------------------------------------------------------------------- */
/*                                WINTER THEME                                */
/* -------------------------------------------------------------------------- */

class _WinterWeatherBackground extends StatefulWidget {
  const _WinterWeatherBackground();

  @override
  State<_WinterWeatherBackground> createState() =>
      _WinterWeatherBackgroundState();
}

class _WinterWeatherBackgroundState extends State<_WinterWeatherBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_SnowParticle> _snowParticles;
  late final List<_GlowParticle> _glowParticles;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    final random = math.Random(2026);

    _snowParticles = List.generate(130, (_) {
      return _SnowParticle(
        startX: random.nextDouble(),
        startY: random.nextDouble(),
        radius: 0.8 + random.nextDouble() * 2.2,
        speed: 0.22 + random.nextDouble() * 0.55,
        drift: -18 + random.nextDouble() * 36,
        opacity: 0.22 + random.nextDouble() * 0.38,
        blur: random.nextDouble() * 1.8,
      );
    });

    _glowParticles = List.generate(8, (_) {
      return _GlowParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 56 + random.nextDouble() * 110,
        phase: random.nextDouble(),
        opacity: 0.08 + random.nextDouble() * 0.14,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _WinterWeatherPainter(
                  progress: _controller.value,
                  snowParticles: _snowParticles,
                  glowParticles: _glowParticles,
                  isForeground: false,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ForegroundSnowLayer extends StatefulWidget {
  const _ForegroundSnowLayer();

  @override
  State<_ForegroundSnowLayer> createState() => _ForegroundSnowLayerState();
}

class _ForegroundSnowLayerState extends State<_ForegroundSnowLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_SnowParticle> _snowParticles;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    final random = math.Random(88);

    _snowParticles = List.generate(55, (_) {
      return _SnowParticle(
        startX: random.nextDouble(),
        startY: random.nextDouble(),
        radius: 1.1 + random.nextDouble() * 2.4,
        speed: 0.35 + random.nextDouble() * 0.75,
        drift: -24 + random.nextDouble() * 48,
        opacity: 0.28 + random.nextDouble() * 0.42,
        blur: random.nextDouble() * 1.4,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _WinterWeatherPainter(
                  progress: _controller.value,
                  snowParticles: _snowParticles,
                  glowParticles: const [],
                  isForeground: true,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WinterWeatherPainter extends CustomPainter {
  const _WinterWeatherPainter({
    required this.progress,
    required this.snowParticles,
    required this.glowParticles,
    required this.isForeground,
  });

  final double progress;
  final List<_SnowParticle> snowParticles;
  final List<_GlowParticle> glowParticles;
  final bool isForeground;

  @override
  void paint(Canvas canvas, Size size) {
    if (!isForeground) {
      _drawBackground(canvas, size);
      _drawFrostGlows(canvas, size);
      _drawMagicGlows(canvas, size);
    }

    _drawSnow(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8FBAD4), Color(0xFFBFD7EA), Color(0xFFE6F0F8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  void _drawFrostGlows(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36);

    paint.color = const Color(0xFF0369A1).withValues(alpha: 0.16);
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.18),
      130,
      paint,
    );

    paint.color = Colors.white.withValues(alpha: 0.20);
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.24),
      155,
      paint,
    );

    paint.color = const Color(0xFF38BDF8).withValues(alpha: 0.14);
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.78),
      145,
      paint,
    );

    paint.color = const Color(0xFFBAE6FD).withValues(alpha: 0.20);
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.80),
      115,
      paint,
    );
  }

  void _drawMagicGlows(Canvas canvas, Size size) {
    for (final glow in glowParticles) {
      final pulse =
          0.55 + 0.45 * math.sin((progress + glow.phase) * math.pi * 2);

      final paint = Paint()
        ..color = const Color(
          0xFF38BDF8,
        ).withValues(alpha: glow.opacity * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);

      canvas.drawCircle(
        Offset(glow.x * size.width, glow.y * size.height),
        glow.size * pulse,
        paint,
      );
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    for (final particle in snowParticles) {
      final animatedY = (particle.startY + progress * particle.speed) % 1.0;

      final wave = math.sin(
        progress * math.pi * 2 + particle.startY * math.pi * 5,
      );

      final x = particle.startX * size.width + wave * particle.drift;
      final y = animatedY * size.height;
      final center = Offset(x, y);

      if (isForeground) {
        final shadowPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(
            0xFF0284C7,
          ).withValues(alpha: particle.opacity * 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

        canvas.drawCircle(
          center.translate(1.2, 2),
          particle.radius * 1.85,
          shadowPaint,
        );
      }

      final snowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: particle.opacity);

      if (particle.blur > 0.5) {
        snowPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, particle.blur);
      }

      canvas.drawCircle(center, particle.radius, snowPaint);

      final highlightPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(
          0xFFE0F2FE,
        ).withValues(alpha: particle.opacity * 0.35);

      canvas.drawCircle(
        center.translate(-0.4, -0.4),
        particle.radius * 0.42,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WinterWeatherPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/* -------------------------------------------------------------------------- */
/*                       SPRING REAL IMAGE BACKGROUND                         */
/* -------------------------------------------------------------------------- */

class _SpringBloomBackground extends StatelessWidget {
  const _SpringBloomBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/spring.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),

            // Soft white wash so text/cards stay readable.
            Container(color: Colors.white.withValues(alpha: 0.42)),

            // Soft pink overlay to keep the spring mood.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFF7FA).withValues(alpha: 0.38),
                    const Color(0xFFFFE8F0).withValues(alpha: 0.24),
                    Colors.white.withValues(alpha: 0.32),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Extra center readability layer.
            Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.78,
                    colors: [
                      Colors.white.withValues(alpha: 0.34),
                      Colors.white.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                         WINTER SNOW CAP WIDGETS                            */
/* -------------------------------------------------------------------------- */

class SnowCapped extends ConsumerWidget {
  const SnowCapped({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.snowHeight = 7,
    this.opacity = 0.92,
    this.horizontalInset = 2,
    this.snowWidthFactor = 1.0,
  });

  final Widget child;
  final double borderRadius;
  final double snowHeight;
  final double opacity;
  final double horizontalInset;
  final double snowWidthFactor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(moodThemeProvider);

    if (selectedTheme != MoodTheme.winterFrost) {
      return child;
    }

    final safeSnowWidthFactor = snowWidthFactor.clamp(0.25, 1.0).toDouble();

    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -1,
          left: horizontalInset,
          right: horizontalInset,
          height: snowHeight,
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: safeSnowWidthFactor,
                heightFactor: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(borderRadius),
                  ),
                  child: CustomPaint(
                    painter: _SnowCapPainter(
                      borderRadius: borderRadius,
                      opacity: opacity,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SnowCappedCard extends StatelessWidget {
  const SnowCappedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 18,
    this.snowHeight = 10,
    this.horizontalInset = 2,
    this.snowWidthFactor = 1.0,
    this.color,
    this.elevation = 2,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double snowHeight;
  final double horizontalInset;
  final double snowWidthFactor;
  final Color? color;
  final double elevation;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SnowCapped(
      borderRadius: borderRadius,
      snowHeight: snowHeight,
      horizontalInset: horizontalInset,
      snowWidthFactor: snowWidthFactor,
      child: Card(
        margin: margin,
        color: color ?? colorScheme.surfaceContainerHighest,
        elevation: elevation,
        clipBehavior: clipBehavior,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SnowCappedText extends ConsumerWidget {
  const SnowCappedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.center,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(moodThemeProvider);
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = defaultStyle.merge(style);

    if (selectedTheme != MoodTheme.winterFrost) {
      return Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: effectiveStyle,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          style: effectiveStyle,
        ),
        IgnorePointer(
          child: ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 0.36,
              child: Text(
                text,
                textAlign: textAlign,
                maxLines: maxLines,
                overflow: overflow,
                style: effectiveStyle.copyWith(
                  color: Colors.white.withValues(alpha: 0.96),
                  shadows: [
                    Shadow(
                      color: const Color(0xFFBAE6FD).withValues(alpha: 0.75),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SnowCapPainter extends CustomPainter {
  const _SnowCapPainter({this.borderRadius = 18, this.opacity = 0.92});

  final double? borderRadius;
  final double? opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    if (width <= 0 || height <= 0) return;

    final safeOpacity = opacity ?? 0.92;
    final safeBorderRadius = borderRadius ?? 18.0;
    final edgeRadius = safeBorderRadius.clamp(0.0, width / 2).toDouble();

    final snowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: safeOpacity);

    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFBAE6FD).withValues(alpha: 0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);

    final path = Path()
      ..moveTo(edgeRadius * 0.75, 0)
      ..lineTo(width - edgeRadius * 0.75, 0)
      ..cubicTo(
        width - edgeRadius * 0.25,
        0,
        width,
        height * 0.14,
        width,
        height * 0.42,
      )
      ..cubicTo(
        width * 0.86,
        height * 0.66,
        width * 0.76,
        height * 0.26,
        width * 0.62,
        height * 0.46,
      )
      ..cubicTo(
        width * 0.48,
        height * 0.70,
        width * 0.36,
        height * 0.30,
        width * 0.22,
        height * 0.50,
      )
      ..cubicTo(0, height * 0.70, edgeRadius * 0.25, 0, edgeRadius * 0.75, 0)
      ..close();

    canvas.drawPath(path.shift(const Offset(0, 1)), shadowPaint);
    canvas.drawPath(path, snowPaint);

    final blobPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: safeOpacity);

    final frostPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE0F2FE).withValues(alpha: 0.58);

    final blobRadius = height * 0.16;
    final frostRadius = height * 0.06;

    final blobs = [
      Offset(width * 0.16, height * 0.36),
      Offset(width * 0.34, height * 0.28),
      Offset(width * 0.53, height * 0.38),
      Offset(width * 0.72, height * 0.27),
      Offset(width * 0.84, height * 0.36),
    ];

    for (final blob in blobs) {
      canvas.drawCircle(blob, blobRadius, blobPaint);
      canvas.drawCircle(blob.translate(-0.5, -0.5), frostRadius, frostPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowCapPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.opacity != opacity;
  }
}

/* -------------------------------------------------------------------------- */
/*                                  MODELS                                    */
/* -------------------------------------------------------------------------- */

class _SnowParticle {
  const _SnowParticle({
    required this.startX,
    required this.startY,
    required this.radius,
    required this.speed,
    required this.drift,
    required this.opacity,
    required this.blur,
  });

  final double startX;
  final double startY;
  final double radius;
  final double speed;
  final double drift;
  final double opacity;
  final double blur;
}

class _GlowParticle {
  const _GlowParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.opacity,
  });

  final double x;
  final double y;
  final double size;
  final double phase;
  final double opacity;
}
