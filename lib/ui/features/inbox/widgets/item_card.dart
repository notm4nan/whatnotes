import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../domain/models/inbox_item.dart';
import '../../../core/utils.dart';

/// Interactive card presenting a single inbox item (Note, Link, or Image).
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleArchive,
    this.onTagTap,
  });

  final InboxItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleArchive;
  final ValueChanged<String>? onTagTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Type Badge, Date, and Actions Menu
              Row(
                children: [
                  _TypeBadge(type: item.type),
                  const SizedBox(width: 8),
                  Text(
                    AppUtils.formatDateTime(item.createdAt),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      item.isArchived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    tooltip: item.isArchived ? 'Restore to Inbox' : 'Archive',
                    onPressed: onToggleArchive,
                    visualDensity: VisualDensity.compact,
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'open':
                          onTap();
                          break;
                        case 'edit':
                          onEdit();
                          break;
                        case 'archive':
                          onToggleArchive();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(
                              item.isArchived
                                  ? Icons.unarchive_outlined
                                  : Icons.archive_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(item.isArchived ? 'Restore' : 'Archive'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),

              // Content Preview based on Type
              _buildContentPreview(context),

              // Tags wrap
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: item.tags.map((tag) {
                    return InkWell(
                      onTap: onTagTap != null ? () => onTagTap!(tag) : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$tag',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentPreview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (item.type) {
      case InboxItemType.note:
        return Text(
          item.content,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        );

      case InboxItemType.link:
        final domain = AppUtils.extractDomain(item.content);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.link_rounded, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      domain,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.content,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                tooltip: 'Open in browser',
                onPressed: () => AppUtils.openUrl(context, item.content),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        );

      case InboxItemType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 160,
            width: double.infinity,
            color: colorScheme.surfaceContainerHighest,
            child: _buildImageWidget(context),
          ),
        );
    }
  }

  Widget _buildImageWidget(BuildContext context) {
    final content = item.content.trim();
    if (content.isEmpty) {
      return _buildImagePlaceholder(context, 'No image provided');
    }

    // Network image
    if (content.startsWith('http://') || content.startsWith('https://')) {
      return Image.network(
        content,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            _buildImagePlaceholder(context, 'Could not load network image'),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    // Local file
    final file = File(content);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            _buildImagePlaceholder(context, 'Could not read local image file'),
      );
    }

    return _buildImagePlaceholder(context, 'Local file not found');
  }

  Widget _buildImagePlaceholder(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_rounded,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final InboxItemType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color badgeColor;
    Color iconColor;

    switch (type) {
      case InboxItemType.note:
        badgeColor = Colors.amber.withValues(alpha: 0.15);
        iconColor = Colors.amber.shade800;
        break;
      case InboxItemType.link:
        badgeColor = colorScheme.primaryContainer.withValues(alpha: 0.5);
        iconColor = colorScheme.primary;
        break;
      case InboxItemType.image:
        badgeColor = Colors.teal.withValues(alpha: 0.15);
        iconColor = Colors.teal.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            type.displayName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: iconColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
