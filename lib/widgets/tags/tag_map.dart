import 'package:flutter/material.dart';
import 'package:chefoo/widgets/tags/tag.dart';

class TagMap extends StatefulWidget {
  final List<String> tags;
  final void Function(List<String>)? onSelectionChanged;

  const TagMap({
    Key? key, 
    required this.tags, 
    this.onSelectionChanged
    }) : super(key: key);

  @override
  State<TagMap> createState() => _TagMapState();
}

class _TagMapState extends State<TagMap> {
  Map<String, bool> selectedTags = {};

  @override
  void initState() {
    super.initState();
    // Initialize all tags as unselected
    for (var tag in widget.tags) {
      selectedTags[tag] = false;
    }
  }

  void _onTagTapped(String tag) {
    setState(() {
      selectedTags[tag] = !(selectedTags[tag] ?? false);
    });

    if(widget.onSelectionChanged != null) {
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
      spacing: 8.0, // gap between adjacent chips
      runSpacing: 4.0, // gap between lines
      children: widget.tags.map((tag) {
        return Tag(
          label: tag,
          selected: selectedTags[tag] ?? false,
          onTap: () => _onTagTapped(tag),
        );
      }).toList(),
    );
  }
}