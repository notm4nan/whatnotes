import 'package:flutter/material.dart';

/// Horizontal scrolling list of tags for filtering inbox items.
class TagChipList extends StatelessWidget {
  const TagChipList({
    super.key,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  });

  final List<String> tags;
  final String? selectedTag;
  final ValueChanged<String?> onTagSelected;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: tags.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedTag == null;
            return FilterChip(
              label: const Text('All Tags'),
              selected: isSelected,
              onSelected: (_) => onTagSelected(null),
              backgroundColor: isSelected ? null : theme.colorScheme.surface,
            );
          }

          final tag = tags[index - 1];
          final isSelected = selectedTag?.toLowerCase() == tag.toLowerCase();

          return FilterChip(
            label: Text('#$tag'),
            selected: isSelected,
            onSelected: (selected) {
              onTagSelected(selected ? tag : null);
            },
            backgroundColor: isSelected ? null : theme.colorScheme.surface,
          );
        },
      ),
    );
  }
}
