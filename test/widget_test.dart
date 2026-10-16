import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:byte_task/data/repositories/inbox_repository.dart';
import 'package:byte_task/data/services/shared_preferences_storage_service.dart';
import 'package:byte_task/domain/models/inbox_item.dart';
import 'package:byte_task/ui/core/app_theme.dart';
import 'package:byte_task/ui/features/create_edit/views/create_edit_screen.dart';
import 'package:byte_task/ui/features/inbox/views/inbox_screen.dart';
import 'package:byte_task/ui/view_models/inbox_view_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget(InboxViewModel viewModel) {
    return ChangeNotifierProvider<InboxViewModel>.value(
      value: viewModel,
      child: MaterialApp(theme: AppTheme.lightTheme, home: const InboxScreen()),
    );
  }

  testWidgets('InboxScreen displays initial items and search bar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = SharedPreferencesStorageService();
    final repo = InboxRepository(storageService: storage);
    await repo.init(seedIfEmpty: true);

    final viewModel = InboxViewModel(repository: repo);

    await tester.pumpWidget(createTestWidget(viewModel));
    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text('WhatNotes'), findsOneWidget);

    // Verify Search hint exists
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText ==
                'Search notes, links, images, tags...',
      ),
      findsOneWidget,
    );

    // Verify seeded items are rendered
    expect(find.text('Welcome to your Offline Inbox!'), findsOneWidget);
    expect(find.text('Flutter Documentation & Guides'), findsOneWidget);

    // Verify FloatingActionButton exists
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Searching filters items in the inbox', (
    WidgetTester tester,
  ) async {
    final storage = SharedPreferencesStorageService();
    final repo = InboxRepository(storageService: storage);
    await repo.init(seedIfEmpty: true);

    final viewModel = InboxViewModel(repository: repo);

    await tester.pumpWidget(createTestWidget(viewModel));
    await tester.pumpAndSettle();

    // Enter search text
    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'Documentation');
    await tester.pumpAndSettle();

    // Only Flutter Documentation item should match
    expect(find.text('Flutter Documentation & Guides'), findsOneWidget);
    expect(find.text('Welcome to your Offline Inbox!'), findsNothing);
  });

  testWidgets('Archiving an item moves it from Inbox to Archive view', (
    WidgetTester tester,
  ) async {
    final storage = SharedPreferencesStorageService();
    final repo = InboxRepository(storageService: storage);
    await repo.init(seedIfEmpty: false);

    // Add 1 test note
    final note = InboxItem.create(
      type: InboxItemType.note,
      title: 'Note to Archive',
      content: 'This will be moved to archive.',
    );
    await repo.addItem(note);

    final viewModel = InboxViewModel(repository: repo);

    await tester.pumpWidget(createTestWidget(viewModel));
    await tester.pumpAndSettle();

    expect(find.text('Note to Archive'), findsOneWidget);

    // Tap archive button on the card
    final archiveButton = find.byTooltip('Archive');
    expect(archiveButton, findsOneWidget);
    await tester.tap(archiveButton);
    await tester.pumpAndSettle();

    // Note is now archived, so active inbox shows empty state
    expect(find.text('Note to Archive'), findsNothing);
    expect(find.text('Your Inbox is empty'), findsOneWidget);

    // Switch to Archive view using the app bar action button
    final viewArchiveButton = find.byTooltip('View Archive (1)');
    expect(viewArchiveButton, findsOneWidget);
    await tester.tap(viewArchiveButton);
    await tester.pumpAndSettle();

    // Verify Archive view is active and displays the item
    expect(find.text('Archived Items'), findsOneWidget);
    expect(find.text('Note to Archive'), findsOneWidget);
  });

  testWidgets('Creates a new note using CreateEditScreen', (
    WidgetTester tester,
  ) async {
    final storage = SharedPreferencesStorageService();
    final repo = InboxRepository(storageService: storage);
    await repo.init(seedIfEmpty: false);

    final viewModel = InboxViewModel(repository: repo);

    await tester.pumpWidget(
      ChangeNotifierProvider<InboxViewModel>.value(
        value: viewModel,
        child: const MaterialApp(
          home: CreateEditScreen(initialType: InboxItemType.note),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Fill title and content
    final titleField = find.widgetWithText(TextFormField, 'Title (Optional)');
    await tester.enterText(titleField, 'Test User Note');

    final contentField = find.widgetWithText(TextFormField, 'Note Content *');
    await tester.enterText(contentField, 'Created inside widget test.');

    // Add a tag
    final tagField = find.widgetWithText(TextField, 'Add a tag');
    await tester.enterText(tagField, 'flutter');
    await tester.tap(find.byTooltip('Add tag'));
    await tester.pumpAndSettle();

    expect(find.text('#flutter'), findsOneWidget);

    // Tap Save button
    final saveButton = find.text('Save');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify item was created in viewModel and repository
    expect(viewModel.items.length, equals(1));
    expect(viewModel.items.first.title, equals('Test User Note'));
    expect(
      viewModel.items.first.content,
      equals('Created inside widget test.'),
    );
    expect(viewModel.items.first.tags, contains('flutter'));
  });
}
