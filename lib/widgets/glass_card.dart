import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double blur;
  final double borderRadius;
  final double border;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.blur = 20,
    this.borderRadius = 24,
    this.border = 1.5,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin,
      child: GlassmorphicContainer(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        borderRadius: borderRadius,
        blur: blur,
        alignment: Alignment.bottomCenter,
        border: border,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFFFFFFFFF).withOpacity(0.05),
                  const Color(0xFFFFFFFF).withOpacity(0.02),
                ]
              : [
                  const Color(0xFFFFFFFFF).withOpacity(0.1),
                  const Color(0xFFFFFFFF).withOpacity(0.05),
                ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFFFFFFFFF).withOpacity(0.1),
                  const Color(0xFFFFFFFF).withOpacity(0.05),
                ]
              : [
                  const Color(0xFFFFFFFFF).withOpacity(0.2),
                  const Color(0xFFFFFFFF).withOpacity(0.1),
                ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
