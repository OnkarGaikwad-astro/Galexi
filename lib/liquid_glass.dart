import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlassCard extends StatefulWidget {
  final Widget child;
  final double height;
  final BorderRadius borderRadius;

  const LiquidGlassCard({
    super.key,
    required this.child,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_controller.value);

        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: widget.height,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.30),
                    Colors.blue.withOpacity(0.08),
                    Colors.purple.withOpacity(0.12),
                  ],
                  stops: [
                    (t - 0.25).clamp(0.0, 1.0),
                    t,
                    (t + 0.25).clamp(0.0, 1.0),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  // outer depth shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  // inner glow illusion
                  BoxShadow(
                    color: Colors.white.withOpacity(0.25),
                    blurRadius: 6,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // main content
                  widget.child,

                  // moving reflection stripe
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.15,
                        child: Transform.translate(
                          offset: Offset(
                            -100 + (200 * t),
                            0,
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.transparent,
                                  Colors.white,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
