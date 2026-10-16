import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Supported types of items in the personal inbox.
enum InboxItemType {
  note,
  link,
  image;

  String get displayName {
    switch (this) {
      case InboxItemType.note:
        return 'Note';
      case InboxItemType.link:
        return 'Link';
      case InboxItemType.image:
        return 'Image';
    }
  }

  IconData get icon {
    switch (this) {
      case InboxItemType.note:
        return Icons.notes_rounded;
      case InboxItemType.link:
        return Icons.link_rounded;
      case InboxItemType.image:
        return Icons.image_rounded;
    }
  }
}

/// Core model representing a saved item in the local inbox.
class InboxItem {
  InboxItem({
    required this.id,
    this.ownerId,
    required this.type,
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
  });

  /// Factory to create a brand new item with automatic UUID and timestamps.
  factory InboxItem.create({
    String? ownerId,
    required InboxItemType type,
    required String title,
    required String content,
    List<String> tags = const [],
    bool isArchived = false,
  }) {
    final now = DateTime.now();
    final sanitizedTitle = title.trim();
    final sanitizedContent = content.trim();
    final cleanTagsList = cleanTags(tags);

    // Auto-generate title if user left it blank
    final effectiveTitle = sanitizedTitle.isNotEmpty
        ? sanitizedTitle
        : _generateDefaultTitle(type, sanitizedContent);

    return InboxItem(
      id: const Uuid().v4(),
      ownerId: ownerId,
      type: type,
      title: effectiveTitle,
      content: sanitizedContent,
      tags: cleanTagsList,
      createdAt: now,
      updatedAt: now,
      isArchived: isArchived,
    );
  }

  final String id;
  final String? ownerId;
  final InboxItemType type;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;

  /// Helper to sanitize a list of tag strings:
  /// trims, strips '#' prefix if user typed it, deduplicates (case-insensitively).
  static List<String> cleanTags(List<String> rawTags) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in rawTags) {
      var trimmed = raw.trim();
      if (trimmed.startsWith('#')) {
        trimmed = trimmed.substring(1).trim();
      }
      if (trimmed.isEmpty) continue;
      final lower = trimmed.toLowerCase();
      if (!seen.contains(lower)) {
        seen.add(lower);
        result.add(trimmed);
      }
    }
    return List.unmodifiable(result);
  }

  /// Generates a reasonable fallback title based on content when empty.
  static String _generateDefaultTitle(InboxItemType type, String content) {
    if (content.isEmpty) {
      return 'Untitled ${type.displayName}';
    }

    switch (type) {
      case InboxItemType.note:
        // Use first non-empty line of the note up to 50 characters
        final firstLine = content
            .split('\n')
            .firstWhere(
              (line) => line.trim().isNotEmpty,
              orElse: () => 'Untitled Note',
            )
            .trim();
        if (firstLine.length > 50) {
          return '${firstLine.substring(0, 47)}...';
        }
        return firstLine.isNotEmpty ? firstLine : 'Untitled Note';

      case InboxItemType.link:
        try {
          final uri = Uri.parse(content);
          if (uri.host.isNotEmpty) {
            final host = uri.host.replaceFirst(RegExp(r'^www\.'), '');
            final path = uri.path.trim();
            if (path.length > 1 && path != '/') {
              final segment = uri.pathSegments.isNotEmpty
                  ? uri.pathSegments.last
                  : '';
              if (segment.isNotEmpty) {
                return '$host / $segment';
              }
            }
            return host;
          }
        } catch (_) {}
        return 'Saved Link';

      case InboxItemType.image:
        try {
          // If it's a file path or URL, extract filename
          final clean = content.split('?').first;
          final filename = clean.split(RegExp(r'[\\/]')).last;
          if (filename.isNotEmpty) {
            return filename;
          }
        } catch (_) {}
        return 'Saved Image';
    }
  }

  /// Create a copy with modified fields; automatically updates [updatedAt].
  InboxItem copyWith({
    String? id,
    String? ownerId,
    InboxItemType? type,
    String? title,
    String? content,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
  }) {
    return InboxItem(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      title: title != null ? title.trim() : this.title,
      content: content != null ? content.trim() : this.content,
      tags: tags != null ? cleanTags(tags) : this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isArchived: isArchived ?? this.isArchived,
    );
  }

  /// Convert to JSON Map for local persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'type': type.name,
      'title': title,
      'content': content,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isArchived': isArchived,
    };
  }

  /// Create model from JSON Map.
  factory InboxItem.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'note';
    final parsedType = InboxItemType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => InboxItemType.note,
    );

    final rawTags = json['tags'];
    final List<String> tagsList = rawTags is List
        ? rawTags.map((e) => e.toString()).toList()
        : const [];

    return InboxItem(
      id: json['id'] as String? ?? const Uuid().v4(),
      ownerId: json['ownerId'] as String?,
      type: parsedType,
      title: (json['title'] as String? ?? '').trim(),
      content: (json['content'] as String? ?? '').trim(),
      tags: cleanTags(tagsList),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InboxItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          title == other.title &&
          content == other.content &&
          isArchived == other.isArchived &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      title.hashCode ^
      content.hashCode ^
      isArchived.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}
