import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/inbox_item.dart';
import '../../../core/utils.dart';
import '../../../view_models/inbox_view_model.dart';

/// Screen to create a new item or edit an existing item.
class CreateEditScreen extends StatefulWidget {
  const CreateEditScreen({super.key, this.itemToEdit, this.initialType});

  final InboxItem? itemToEdit;
  final InboxItemType? initialType;

  @override
  State<CreateEditScreen> createState() => _CreateEditScreenState();
}

class _CreateEditScreenState extends State<CreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late InboxItemType _selectedType;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagInputController;
  late List<String> _tags;
  bool _isSaving = false;

  bool get _isEditing => widget.itemToEdit != null;

  @override
  void initState() {
    super.initState();
    _selectedType =
        widget.itemToEdit?.type ?? widget.initialType ?? InboxItemType.note;
    _titleController = TextEditingController(
      text: widget.itemToEdit?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.itemToEdit?.content ?? '',
    );
    _tagInputController = TextEditingController();
    _tags = List<String>.from(widget.itemToEdit?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag(String rawTag) {
    var tag = rawTag.trim();
    if (tag.startsWith('#')) {
      tag = tag.substring(1).trim();
    }
    if (tag.isEmpty) return;

    // Check duplicate (case-insensitive)
    final exists = _tags.any((t) => t.toLowerCase() == tag.toLowerCase());
    if (!exists) {
      setState(() {
        _tags.add(tag);
        _tagInputController.clear();
      });
    } else {
      _tagInputController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.removeWhere((t) => t.toLowerCase() == tag.toLowerCase());
    });
  }

  Future<void> _pickImage() async {
    final viewModel = context.read<InboxViewModel>();
    final path = await viewModel.pickImageFile();
    if (path != null && mounted) {
      setState(() {
        _contentController.text = path;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty && mounted) {
      setState(() {
        _contentController.text = text;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawTitle = _titleController.text.trim();
    var rawContent = _contentController.text.trim();

    if (_selectedType == InboxItemType.link) {
      rawContent = AppUtils.normalizeUrl(rawContent);
    }

    setState(() => _isSaving = true);
    final viewModel = context.read<InboxViewModel>();

    try {
      if (_isEditing) {
        await viewModel.updateItem(
          id: widget.itemToEdit!.id,
          title: rawTitle.isNotEmpty ? rawTitle : null,
          content: rawContent,
          type: _selectedType,
          tags: _tags,
        );
      } else {
        await viewModel.createItem(
          type: _selectedType,
          title: rawTitle,
          content: rawContent,
          tags: _tags,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Item updated successfully.' : 'Saved to Inbox.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save item: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allExistingTags = context.watch<InboxViewModel>().allTags;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Item' : 'New Item'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Type Selector (Segmented buttons)
            SegmentedButton<InboxItemType>(
              segments: [
                ButtonSegment(
                  value: InboxItemType.note,
                  label: const Text('Note'),
                  icon: Icon(InboxItemType.note.icon),
                ),
                ButtonSegment(
                  value: InboxItemType.link,
                  label: const Text('Link'),
                  icon: Icon(InboxItemType.link.icon),
                ),
                ButtonSegment(
                  value: InboxItemType.image,
                  label: const Text('Image'),
                  icon: Icon(InboxItemType.image.icon),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedType = set.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Title Field (Optional, auto-generated if blank)
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title (Optional)',
                hintText: _getTitleHint(),
                prefixIcon: const Icon(Icons.title_rounded),
                helperText:
                    'Leave blank to automatically infer a title from content.',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // Type-Specific Content Input
            _buildTypeSpecificInput(context),
            const SizedBox(height: 24),

            // Tags Section
            Text(
              'Tags',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Add Tag Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagInputController,
                    decoration: const InputDecoration(
                      labelText: 'Add a tag',
                      hintText: 'e.g. work, recipe, ideas',
                      prefixIcon: Icon(Icons.tag_rounded),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: _addTag,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add tag',
                  onPressed: () => _addTag(_tagInputController.text),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Active tags chips
            if (_tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text('#$tag'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTag(tag),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Suggested existing tags
            if (allExistingTags.isNotEmpty) ...[
              Text(
                'Existing Tags:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: allExistingTags.map((tag) {
                  final isAlreadyAdded = _tags.any(
                    (t) => t.toLowerCase() == tag.toLowerCase(),
                  );
                  return ActionChip(
                    label: Text(
                      '#$tag',
                      style: TextStyle(
                        color: isAlreadyAdded
                            ? colorScheme.outline
                            : colorScheme.primary,
                      ),
                    ),
                    avatar: isAlreadyAdded
                        ? const Icon(Icons.check, size: 14)
                        : const Icon(Icons.add, size: 14),
                    onPressed: isAlreadyAdded ? null : () => _addTag(tag),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTitleHint() {
    switch (_selectedType) {
      case InboxItemType.note:
        return 'e.g. Meeting Highlights, Book Summary';
      case InboxItemType.link:
        return 'e.g. Documentation, Favorite Article';
      case InboxItemType.image:
        return 'e.g. Screenshot, Wireframe Sketch';
    }
  }

  Widget _buildTypeSpecificInput(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (_selectedType) {
      case InboxItemType.note:
        return TextFormField(
          controller: _contentController,
          maxLines: 8,
          minLines: 4,
          decoration: const InputDecoration(
            labelText: 'Note Content *',
            hintText: 'Type your notes, thoughts, checklists, or code here...',
            alignLabelWithHint: true,
          ),
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Note content cannot be empty.';
            }
            return null;
          },
        );

      case InboxItemType.link:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Web URL *',
                hintText: 'https://example.com/article',
                prefixIcon: const Icon(Icons.link_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste_rounded),
                  tooltip: 'Paste from clipboard',
                  onPressed: _pasteFromClipboard,
                ),
                helperText: 'e.g. flutter.dev or https://news.ycombinator.com',
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a web URL.';
                }
                final normalized = AppUtils.normalizeUrl(value);
                if (!AppUtils.isValidUrl(normalized)) {
                  return 'Please enter a valid website address.';
                }
                return null;
              },
            ),
          ],
        );

      case InboxItemType.image:
        final currentContent = _contentController.text.trim();
        final hasImage = currentContent.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Pick Image from Device'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Image Path or Image URL *',
                hintText: 'Local path or https://.../image.png',
                prefixIcon: const Icon(Icons.image_search_rounded),
                suffixIcon: hasImage
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _contentController.clear();
                          });
                        },
                      )
                    : null,
                helperText: 'Pick a file or paste an image link.',
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please select a local image or provide an image URL.';
                }
                return null;
              },
            ),

            // Live Image Preview
            if (hasImage) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: colorScheme.surfaceContainerHighest,
                  child: _buildLiveImagePreview(currentContent),
                ),
              ),
            ],

            const SizedBox(height: 14),
            // Sample Preset Photos for easy instant testing
            Text(
              'Or try a sample image preset:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.landscape, size: 14),
                  label: const Text('Nature Photo'),
                  onPressed: () {
                    setState(() {
                      _contentController.text = 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80';
                      if (_titleController.text.isEmpty) {
                        _titleController.text = 'Mountain Landscape';
                      }
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.laptop_mac, size: 14),
                  label: const Text('Desk Workspace'),
                  onPressed: () {
                    setState(() {
                      _contentController.text = 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=800&q=80';
                      if (_titleController.text.isEmpty) {
                        _titleController.text = 'Code Workspace';
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildLiveImagePreview(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Image.network(
        pathOrUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey),
              SizedBox(height: 4),
              Text('Unable to preview network image URL'),
            ],
          ),
        ),
      );
    }

    final file = File(pathOrUrl);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Center(child: Text('Unable to preview local image file')),
      );
    }

    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey),
          SizedBox(height: 4),
          Text('Local file not found at path'),
        ],
      ),
    );
  }
}
