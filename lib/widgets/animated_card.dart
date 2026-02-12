import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme/app_theme.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double borderRadius;
  final bool enableAnimation;
  final bool enableShadow;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius = 16,
    this.enableAnimation = true,
    this.enableShadow = false,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableAnimation && widget.onTap != null) {
      HapticFeedback.lightImpact();
      _controller.forward();
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableAnimation) {
      _controller.reverse();
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.enableAnimation) {
      _controller.reverse();
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: widget.margin,
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.enableShadow || _isPressed
            ? [
                BoxShadow(
                  color: _isPressed
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: _isPressed ? 12 : 8,
                  offset: Offset(0, _isPressed ? 3 : 2),
                ),
              ]
            : null,
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: widget.enableAnimation
            ? ScaleTransition(scale: _scaleAnimation, child: card)
            : card,
      );
    }

    return card;
  }
}

/// A card with built-in fade-in animation
class FadeInCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const FadeInCard({
    super.key,
    required this.child,
    this.delay = 0,
  });

  @override
  State<FadeInCard> createState() => _FadeInCardState();
}

class _FadeInCardState extends State<FadeInCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
