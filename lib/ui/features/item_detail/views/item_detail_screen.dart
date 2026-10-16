import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/inbox_item.dart';
import '../../../core/utils.dart';
import '../../../view_models/inbox_view_model.dart';
import '../../create_edit/views/create_edit_screen.dart';

/// Screen displaying the full details of an inbox item,
/// allowing the user to read, open links, view full images, copy content,
/// edit, archive/restore, and delete.
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  Future<void> _confirmDelete(BuildContext context, InboxItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text(
          'Are you sure you want to permanently delete "${item.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final viewModel = context.read<InboxViewModel>();
      await viewModel.deleteItem(item.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToEdit(BuildContext context, InboxItem item) {
    final viewModel = context.read<InboxViewModel>();
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => ChangeNotifierProvider.value(
          value: viewModel,
          child: CreateEditScreen(itemToEdit: item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewModel = context.watch<InboxViewModel>();

    final currentItem = viewModel.getItemById(itemId);

    if (currentItem == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Details')),
        body: const Center(child: Text('Item not found or deleted.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentItem.type.displayName),
        actions: [
          IconButton(
            icon: Icon(
              currentItem.isArchived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
            ),
            tooltip: currentItem.isArchived ? 'Restore to Inbox' : 'Archive',
            onPressed: () async {
              await viewModel.toggleArchive(currentItem.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      currentItem.isArchived
                          ? 'Item restored to Inbox.'
                          : 'Item archived.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _navigateToEdit(context, currentItem),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, currentItem),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header info: Type, Status, Created Date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      currentItem.type.icon,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentItem.type.displayName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (currentItem.isArchived)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Archived',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                AppUtils.formatDateTime(currentItem.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          SelectableText(
            currentItem.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),

          // Content Box depending on Type
          _buildContentSection(context, currentItem),
          const SizedBox(height: 24),

          // Tags Section
          if (currentItem.tags.isNotEmpty) ...[
            Text(
              'Tags',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currentItem.tags.map((tag) {
                return ActionChip(
                  label: Text('#$tag'),
                  onPressed: () {
                    viewModel.setSelectedTag(tag);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          const Divider(),
          const SizedBox(height: 12),

          // Timestamps Metadata
          Text(
            'Metadata',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _buildMetadataRow(
            'Created',
            AppUtils.formatDetailedDateTime(currentItem.createdAt),
            theme,
          ),
          const SizedBox(height: 4),
          _buildMetadataRow(
            'Last updated',
            AppUtils.formatDetailedDateTime(currentItem.updatedAt),
            theme,
          ),
          const SizedBox(height: 4),
          _buildMetadataRow('Item ID', currentItem.id, theme),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection(BuildContext context, InboxItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (item.type) {
      case InboxItemType.note:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copy Note',
                    onPressed: () => AppUtils.copyToClipboard(
                      context,
                      item.content,
                      message: 'Note copied to clipboard',
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              SelectableText(
                item.content,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ],
          ),
        );

      case InboxItemType.link:
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.language_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppUtils.extractDomain(item.content),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(
                  item.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            AppUtils.openUrl(context, item.content),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Open in Browser'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Copy Link',
                      onPressed: () => AppUtils.copyToClipboard(
                        context,
                        item.content,
                        message: 'Link copied to clipboard',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

      case InboxItemType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                width: double.infinity,
                color: colorScheme.surfaceContainerHighest,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: _buildDetailImage(context, item.content),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.content,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copy Image Path/URL',
                  onPressed: () => AppUtils.copyToClipboard(
                    context,
                    item.content,
                    message: 'Image path copied to clipboard',
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildDetailImage(BuildContext context, String content) {
    final trimmed = content.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Could not load image from network URL.'),
              ],
            ),
          ),
        ),
      );
    }

    final file = File(trimmed);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Could not read image file.'),
          ),
        ),
      );
    }

    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Local image file not found on disk.'),
          ],
        ),
      ),
    );
  }
}
