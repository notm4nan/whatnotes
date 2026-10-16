import 'package:flutter/material.dart';

import 'inbox_item.dart';

/// Screen view modes: Active inbox vs Archived items
enum InboxViewFilter {
  active,
  archived;

  String get displayName => this == active ? 'Inbox' : 'Archived';
  IconData get icon =>
      this == active ? Icons.inbox_rounded : Icons.archive_outlined;
}

/// Sort criteria for items in the inbox
enum SortOption {
  newestFirst('Newest First', Icons.arrow_downward_rounded),
  oldestFirst('Oldest First', Icons.arrow_upward_rounded),
  recentlyUpdated('Recently Updated', Icons.update_rounded),
  alphabetical('Title (A-Z)', Icons.sort_by_alpha_rounded);

  const SortOption(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Filter criteria for item types
enum ItemTypeFilter {
  all('All Items', null),
  notes('Notes', InboxItemType.note),
  links('Links', InboxItemType.link),
  images('Images', InboxItemType.image);

  const ItemTypeFilter(this.label, this.targetType);

  final String label;
  final InboxItemType? targetType;
}
