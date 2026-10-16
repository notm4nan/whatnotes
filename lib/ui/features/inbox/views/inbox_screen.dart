import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/filter_options.dart';
import '../../../../domain/models/inbox_item.dart';
import '../../../../data/services/auth_service.dart';
import '../../../core/theme_controller.dart';
import '../../../view_models/inbox_view_model.dart';
import '../../create_edit/views/create_edit_screen.dart';
import '../../item_detail/views/item_detail_screen.dart';
import '../widgets/empty_inbox_view.dart';
import '../widgets/item_card.dart';

/// Main Inbox screen displaying saved items, search bar,
/// type and tag filters, sort options, and creation actions.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateScreen({InboxItemType? initialType}) {
    final viewModel = context.read<InboxViewModel>();
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => ChangeNotifierProvider.value(
          value: viewModel,
          child: CreateEditScreen(initialType: initialType),
        ),
      ),
    );
  }

  void _openEditScreen(InboxItem item) {
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

  void _openDetailScreen(InboxItem item) {
    final viewModel = context.read<InboxViewModel>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: viewModel,
          child: ItemDetailScreen(itemId: item.id),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    InboxViewModel viewModel,
    InboxItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text(
          'Are you sure you want to delete "${item.title}"? This cannot be undone.',
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

    if (confirmed == true && mounted) {
      await viewModel.deleteItem(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${item.title}".'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCreateBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Add to Inbox',
                        style: Theme.of(sheetContext).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF3CD),
                    child: Icon(Icons.notes_rounded, color: Color(0xFF856404)),
                  ),
                  title: const Text('Note'),
                  subtitle: const Text(
                    'Quick thoughts, checklists, or snippets',
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openCreateScreen(initialType: InboxItemType.note);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFD0EBFF),
                    child: Icon(Icons.link_rounded, color: Color(0xFF1864AB)),
                  ),
                  title: const Text('Web Link'),
                  subtitle: const Text('Bookmarks, articles, or resources'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openCreateScreen(initialType: InboxItemType.link);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFC3FAE8),
                    child: Icon(Icons.image_rounded, color: Color(0xFF087F5B)),
                  ),
                  title: const Text('Image'),
                  subtitle: const Text(
                    'Photos, screenshots, or visual inspirations',
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openCreateScreen(initialType: InboxItemType.image);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewModel = context.watch<InboxViewModel>();
    final themeController = Provider.of<ThemeController?>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.note_alt_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                viewModel.isArchivedView ? 'Archived Items' : 'WhatNotes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<AppThemeMode>(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Choose theme',
            initialValue: themeController?.mode ?? AppThemeMode.light,
            onSelected: (mode) => themeController?.setMode(mode),
            itemBuilder: (_) => const [
              PopupMenuItem(value: AppThemeMode.light, child: Text('Light')),
              PopupMenuItem(value: AppThemeMode.dark, child: Text('Dark')),
              PopupMenuItem(value: AppThemeMode.retro, child: Text('Retro')),
            ],
          ),
          // Sort Options Menu
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort items',
            initialValue: viewModel.sortOption,
            onSelected: (option) => viewModel.setSortOption(option),
            itemBuilder: (context) => SortOption.values.map((option) {
              return PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    Icon(
                      option.icon,
                      size: 18,
                      color: viewModel.sortOption == option
                          ? colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      option.label,
                      style: TextStyle(
                        fontWeight: viewModel.sortOption == option
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: viewModel.sortOption == option
                            ? colorScheme.primary
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          // View toggle: Inbox vs Archived
          IconButton(
            icon: Icon(
              viewModel.isArchivedView
                  ? Icons.inbox_rounded
                  : Icons.archive_outlined,
            ),
            tooltip: viewModel.isArchivedView
                ? 'Back to Inbox (${viewModel.activeCount})'
                : 'View Archive (${viewModel.archivedCount})',
            onPressed: () {
              viewModel.setViewFilter(
                viewModel.isArchivedView
                    ? InboxViewFilter.active
                    : InboxViewFilter.archived,
              );
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: widget.authService == null
                ? null
                : () async => widget.authService!.signOut(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.errorMessage != null
          ? _ErrorRetryView(
              message: viewModel.errorMessage!,
              onRetry: viewModel.init,
            )
          : Column(
              children: [
                // Top Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: viewModel.isArchivedView
                          ? 'Search archive...'
                          : 'Search notes, links, images, tags...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                viewModel.setSearchQuery('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (text) => viewModel.setSearchQuery(text),
                  ),
                ),

                // Item Type Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ItemTypeFilter.values.map((filter) {
                        final isSelected = viewModel.typeFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter.label),
                            selected: isSelected,
                            onSelected: (_) => viewModel.setTypeFilter(filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Compact tag dropdown keeps the filter row clean on small screens.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(10),
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.35,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: viewModel.selectedTag ?? '',
                          icon: const Icon(Icons.expand_more_rounded),
                          hint: const Text('All Tags'),
                          isDense: true,
                          borderRadius: BorderRadius.circular(12),
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('All Tags'),
                            ),
                            ...viewModel.allTags.map(
                              (tag) => DropdownMenuItem<String>(
                                value: tag,
                                child: Text('#$tag'),
                              ),
                            ),
                          ],
                          onChanged: (tag) => viewModel.setSelectedTag(
                            tag == null || tag.isEmpty ? null : tag,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Active view info bar if in archive or filtering
                if (viewModel.isArchivedView || viewModel.hasActiveFilters)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          viewModel.isArchivedView
                              ? 'Viewing Archived (${viewModel.items.length})'
                              : 'Filtered Results (${viewModel.items.length})',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (viewModel.hasActiveFilters)
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              viewModel.clearFilters();
                            },
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Reset filters'),
                          ),
                      ],
                    ),
                  ),

                // Items List or Empty State
                Expanded(
                  child: viewModel.items.isEmpty
                      ? EmptyInboxView(
                          isArchived: viewModel.isArchivedView,
                          hasFilters: viewModel.hasActiveFilters,
                          onClearFilters: () {
                            _searchController.clear();
                            viewModel.clearFilters();
                          },
                          onAddNew: () => _openCreateScreen(),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 80),
                          itemCount: viewModel.items.length,
                          itemBuilder: (context, index) {
                            final item = viewModel.items[index];
                            return ItemCard(
                              key: ValueKey(item.id),
                              item: item,
                              onTap: () => _openDetailScreen(item),
                              onEdit: () => _openEditScreen(item),
                              onDelete: () =>
                                  _confirmDelete(context, viewModel, item),
                              onToggleArchive: () async {
                                await viewModel.toggleArchive(item.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        item.isArchived
                                            ? 'Restored to inbox.'
                                            : 'Moved to archive.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () {
                                          viewModel.toggleArchive(item.id);
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                              onTagTap: (tag) => viewModel.setSelectedTag(tag),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBottomSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
      ),
    );
  }
}

class _ErrorRetryView extends StatelessWidget {
  const _ErrorRetryView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
