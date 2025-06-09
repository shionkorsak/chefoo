import 'package:flutter/material.dart';
import 'package:chefoo/widgets/tags/tag.dart';
import 'dart:math';

class TagMap extends StatefulWidget {
  final List<String> tags;
  final void Function(List<String>)? onSelectionChanged;
  final double? fontSize;
  final bool isTappable;
  final bool isLongPressable;
  final Color? backgroundColor;
  final Color? selectedBorderColor;

  const TagMap({
    Key? key,
    required this.tags,
    this.onSelectionChanged,
    this.fontSize,
    this.isTappable = true,
    this.isLongPressable = true,
    this.backgroundColor,
    this.selectedBorderColor,
  }) : super(key: key);

  @override
  State<TagMap> createState() => _TagMapState();
}

class _TagMapState extends State<TagMap> {
  Map<String, bool> selectedTags = {};
  bool _isShaking = false;
  final Random _random = Random();

  // Store unique random parameters for each tag
  Map<String, Map<String, double>> _tagParameters = {};

  @override
  void initState() {
    super.initState();
    // Initialize all tags and generate random parameters
    for (var tag in widget.tags) {
      selectedTags[tag] = false;
      _tagParameters[tag] = {
        'offset': 0.3 + (_random.nextDouble() * 0.4), // 0.3 to 0.7
        'phase': _random.nextDouble() * 2 * pi,
        'rotation': _random.nextDouble() * 2 * pi,
        'frequency': 0.8 + (_random.nextDouble() * 0.4), // 0.8 to 1.2
      };
    }
  }

  void _startShaking() {
    if (!widget.isLongPressable) return;

    setState(() {
      _isShaking = true;
    });
  }

  void _stopShaking() {
    setState(() {
      _isShaking = false;
    });
  }

  void _onTagTapped(String tag, bool isSelected) {
    if (!widget.isTappable) return;
    if (_isShaking) {
      _stopShaking();
      return;
    }
    setState(() {
      if (tag == "No Preference" && isSelected) {
        selectedTags.updateAll((key, value) => key == "No Preference");
      } else {
        selectedTags["No Preference"] = false;
        selectedTags[tag] = isSelected;
      }
    });

    if (widget.onSelectionChanged != null) {
      final selected = selectedTags.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      widget.onSelectionChanged!(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: widget.tags.map((tag) {
        final params = _tagParameters[tag]!;

        return Tag(
          label: tag,
          selected: selectedTags[tag] ?? false,
          onSelected: widget.isTappable &&
                  (!selectedTags["No Preference"]! || tag == "No Preference")
              ? (isSelected) => _onTagTapped(tag, isSelected)
              : null,
          fontSize: widget.fontSize,
          isShaking: _isShaking,
          shakeOffset: params['offset'],
          shakePhase: params['phase'],
          rotationPhase: params['rotation'],
          frequency: params['frequency'],
          isTappable: widget.isTappable,
          isLongPressable: widget.isLongPressable,
          backgroundColor: widget.backgroundColor,
          selectedBorderColor: widget.selectedBorderColor,
          onLongPress: widget.isLongPressable
              ? () {
                  if (!_isShaking) {
                    _startShaking();
                  }
                }
              : null,
        );
      }).toList(),
    );
  }
}
