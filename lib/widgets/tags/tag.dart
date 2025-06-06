import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';
import 'dart:math';

class Tag extends StatefulWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final double? fontSize;
  final bool isShaking;
  final double? shakeOffset;
  final double? shakePhase;
  final double? rotationPhase;
  final double? frequency;
  final bool isTappable;
  final bool isLongPressable;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? selectedBorderColor;
  final int? labelMaxLines;  // Add this parameter
  final TextOverflow? labelOverflow;  // Add this parameter

  const Tag({
    Key? key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.fontSize,
    this.isShaking = false,
    this.shakeOffset,
    this.shakePhase,
    this.rotationPhase,
    this.frequency,
    this.isTappable = true,
    this.isLongPressable = true,
    this.onLongPress,
    this.backgroundColor,
    this.selectedBorderColor,
    this.labelMaxLines,  // Add this to constructor
    this.labelOverflow,  // Add this to constructor
  }) : super(key: key);

  @override
  State<Tag> createState() => _TagState();
}

class _TagState extends State<Tag> with SingleTickerProviderStateMixin {
  late bool _selected;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;

    _shakeController = AnimationController(
      duration: Duration(milliseconds: 500), // animation speed
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOutSine,
    ));

    // Start shaking immediately if isShaking is true from the beginning
    if (widget.isShaking) {
      final randomStart = (widget.shakePhase ?? 0.0) / (2 * pi);
      _shakeController.value = randomStart;
      _shakeController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant Tag oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _selected = widget.selected;
    }

    if (oldWidget.isShaking != widget.isShaking) {
      if (widget.isShaking) {
        // Add random starting point for this tag's animation
        final randomStart = (widget.shakePhase ?? 0.0) / (2 * pi);
        _shakeController.value = randomStart;
        _shakeController.repeat(reverse: true);
      } else {
        _shakeController.stop();
        _shakeController.reset();
      }
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Only handle tap if tappable and callback is provided
    if (!widget.isTappable || widget.onSelected == null) return;

    setState(() {
      _selected = !_selected;
    });
    widget.onSelected!(_selected);
  }

  void _handleLongPress() {
    // Only handle long press if long-pressable and callback is provided
    if (!widget.isLongPressable || widget.onLongPress == null) return;

    widget.onLongPress!();
  }

  @override
  Widget build(BuildContext context) {
    final double effectiveFontSize =
        widget.fontSize ?? AppTextStyles.detail.fontSize!;
    final EdgeInsetsGeometry effectivePadding = EdgeInsets.symmetric(
      horizontal: effectiveFontSize * 1.0,
      vertical: effectiveFontSize * 0.4,
    );

    // Use provided colors or fall back to defaults
    final Color effectiveBackgroundColor =
        widget.backgroundColor ?? AppColors.secondary.withOpacity(0.4);
    final Color effectiveBorderColor =
        widget.selectedBorderColor ?? AppColors.primary;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeOffset = widget.shakeOffset ?? 0.5;
        final shakePhase = widget.shakePhase ?? 0.0;
        final rotationPhase = widget.rotationPhase ?? 0.0;
        final frequency = widget.frequency ?? 1.0;

        // Use the animation value with the unique phase offset for more randomization
        final animValue = (_shakeController.value + (shakePhase / (2 * pi))) *
            2 *
            pi *
            frequency;

        return Transform.translate(
          offset: widget.isShaking
              ? Offset(
                  shakeOffset * sin(animValue + shakePhase) * 2.5,
                  shakeOffset * cos(animValue + shakePhase + pi / 4) * 1.5,
                )
              : Offset.zero,
          child: Transform.rotate(
            angle: widget.isShaking
                ? shakeOffset * sin(animValue * 2 + rotationPhase) * 0.05
                : 0,
            child: GestureDetector(
              onTap: widget.isTappable ? _handleTap : null,
              onLongPress: widget.isLongPressable ? _handleLongPress : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: effectivePadding,
                    decoration: BoxDecoration(
                      color: effectiveBackgroundColor,
                      borderRadius: kRadius30,
                    ),
                    child: Text(
                      widget.label,
                      style: AppTextStyles.detail.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: effectiveFontSize,
                      ),
                      maxLines: widget.labelMaxLines, // Use the maxLines property
                      overflow: widget.labelOverflow ?? TextOverflow.clip, // Use the overflow property
                    ),
                  ),
                  if (_selected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: kRadius30,
                          border: Border.all(
                            color: effectiveBorderColor,
                            width: effectiveFontSize * 0.15,
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
