import 'package:flutter_test/flutter_test.dart';
import 'package:byte_task/domain/models/inbox_item.dart';

void main() {
  group('InboxItem Model Tests', () {
    test('creates item with provided values and auto-generated UUID', () {
      final item = InboxItem.create(
        type: InboxItemType.note,
        title: 'Meeting Notes',
        content: 'Discuss quarterly project roadmap.',
        tags: ['work', 'planning'],
      );

      expect(item.id, isNotEmpty);
      expect(item.type, equals(InboxItemType.note));
      expect(item.title, equals('Meeting Notes'));
      expect(item.content, equals('Discuss quarterly project roadmap.'));
      expect(item.tags, equals(['work', 'planning']));
      expect(item.isArchived, isFalse);
      expect(item.createdAt, isNotNull);
      expect(item.updatedAt, isNotNull);
    });

    group('Tag Sanitization & Cleaning', () {
      test(
        'cleans tags: trims, strips hash symbol, removes empty, deduplicates',
        () {
          final rawTags = [
            '  #flutter ',
            '#FLUTTER',
            'dart',
            '  ',
            '#',
            'coding',
            'dart ',
          ];
          final cleaned = InboxItem.cleanTags(rawTags);

          expect(cleaned, equals(['flutter', 'dart', 'coding']));
        },
      );
    });

    group('Smart Fallback Title Generation for Empty/Whitespace Titles', () {
      test('auto-titles note from first line of content', () {
        final item = InboxItem.create(
          type: InboxItemType.note,
          title: '   ',
          content: 'Buy groceries\nMilk, eggs, and bread',
        );

        expect(item.title, equals('Buy groceries'));
      });

      test('auto-titles note if entire content is blank', () {
        final item = InboxItem.create(
          type: InboxItemType.note,
          title: '',
          content: '',
        );

        expect(item.title, equals('Untitled Note'));
      });

      test('auto-titles link from domain name and segment', () {
        final item = InboxItem.create(
          type: InboxItemType.link,
          title: '',
          content: 'https://flutter.dev/docs',
        );

        expect(item.title, equals('flutter.dev / docs'));
      });

      test('auto-titles image from filename', () {
        final item = InboxItem.create(
          type: InboxItemType.image,
          title: '  ',
          content: 'C:\\Users\\Photos\\landscape_wallpaper.jpg',
        );

        expect(item.title, equals('landscape_wallpaper.jpg'));
      });
    });

    group('Serialization & Deserialization', () {
      test('serializes to JSON and parses back correctly', () {
        final now = DateTime.now();
        final original = InboxItem(
          id: 'test-id-123',
          type: InboxItemType.link,
          title: 'Dart Docs',
          content: 'https://dart.dev',
          tags: const ['dart', 'docs'],
          createdAt: now,
          updatedAt: now,
          isArchived: true,
        );

        final json = original.toJson();
        final restored = InboxItem.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.type, equals(original.type));
        expect(restored.title, equals(original.title));
        expect(restored.content, equals(original.content));
        expect(restored.tags, equals(original.tags));
        expect(restored.isArchived, isTrue);
        expect(
          restored.createdAt.millisecondsSinceEpoch,
          equals(original.createdAt.millisecondsSinceEpoch),
        );
      });

      test('handles missing or malformed JSON fields safely', () {
        final item = InboxItem.fromJson({
          'type': 'unknown_type',
          'title': null,
          'content': null,
        });

        expect(item.id, isNotEmpty);
        expect(item.type, equals(InboxItemType.note));
        expect(item.title, isEmpty);
        expect(item.content, isEmpty);
        expect(item.tags, isEmpty);
        expect(item.isArchived, isFalse);
      });
    });

    group('copyWith', () {
      test(
        'creates updated clone with modified fields and updated timestamp',
        () {
          final item = InboxItem.create(
            type: InboxItemType.note,
            title: 'Original Title',
            content: 'Original Content',
            tags: ['initial'],
          );

          final updated = item.copyWith(
            title: 'Modified Title',
            tags: ['initial', 'updated'],
            isArchived: true,
          );

          expect(updated.id, equals(item.id));
          expect(updated.title, equals('Modified Title'));
          expect(updated.content, equals('Original Content'));
          expect(updated.tags, equals(['initial', 'updated']));
          expect(updated.isArchived, isTrue);
        },
      );
    });
  });
}
