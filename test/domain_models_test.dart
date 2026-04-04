import 'package:flutter_test/flutter_test.dart';

import 'package:dayflow/features/diary/domain/diary_entry.dart';
import 'package:dayflow/features/diary/presentation/widgets/diary_image_embed.dart';
import 'package:dayflow/features/planner/domain/task_item.dart';

void main() {
  group('Mood', () {
    test('parses stored values into enum instances', () {
      expect(Mood.fromValue('happy'), Mood.happy);
      expect(Mood.fromValue('grateful'), Mood.grateful);
    });

    test('exposes emoji and label separately', () {
      expect(Mood.happy.emoji, '😊');
      expect(Mood.happy.label, '开心');
    });

    test('returns null for unknown values', () {
      expect(Mood.fromValue('missing'), isNull);
    });

    test('diary copyWith can clear nullable fields explicitly', () {
      final entry = DiaryEntry(
        id: 1,
        cloudId: 'cloud-1',
        content: 'with image',
        mood: Mood.happy,
        date: DateTime(2026, 3, 31),
        createdAt: DateTime(2026, 3, 31, 8),
        updatedAt: DateTime(2026, 3, 31, 9),
        userId: 'user-1',
        location: '30.1,104.1',
        locationName: '成都',
        imageUrls: 'https://example.com/a.png',
      );

      final cleared = entry.copyWith(
        mood: null,
        location: null,
        locationName: null,
        imageUrls: null,
      );

      expect(cleared.mood, isNull);
      expect(cleared.location, isNull);
      expect(cleared.locationName, isNull);
      expect(cleared.imageUrls, isNull);
    });

    test('resolves diary image source from legacy embed payloads', () {
      expect(
        resolveDiaryImageSource('https://example.com/a.png'),
        'https://example.com/a.png',
      );
      expect(
        resolveDiaryImageSource({'image': 'https://example.com/b.png'}),
        'https://example.com/b.png',
      );
      expect(
        resolveDiaryImageSource('{"image":"https://example.com/c.png"}'),
        'https://example.com/c.png',
      );
      expect(
        resolveDiaryImageSource({
          'image': {'source': 'https://example.com/d.png'},
        }),
        'https://example.com/d.png',
      );
    });

    test('normalizes legacy diary delta image inserts', () {
      final normalized = normalizeDiaryDeltaImageInserts([
        {
          'insert': {
            'image': '{"source":"https://example.com/a.png"}',
          },
        },
        {
          'insert': '\n',
        },
      ]);

      expect(
        normalized.first,
        {
          'insert': {'image': 'https://example.com/a.png'},
        },
      );
    });

    test('extracts diary image sources from saved delta content', () {
      const content =
          '[{"insert":{"image":"https://example.com/a.png"}},'
          '{"insert":"\\n正文"},'
          '{"insert":{"image":"data:image/png;base64,AAAA"}},'
          '{"insert":"\\n"}]';

      expect(
        extractDiaryImageSourcesFromContent(content),
        [
          'https://example.com/a.png',
          'data:image/png;base64,AAAA',
        ],
      );
    });
  });

  group('Task models', () {
    test('falls back to todo for unknown task status values', () {
      expect(TaskStatus.fromValue('missing'), TaskStatus.todo);
    });

    test('marks unfinished tasks past due as overdue', () {
      final task = TaskItem(
        title: 'Review planner state',
        priority: TaskPriority.high,
        status: TaskStatus.todo,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
        userId: 'user-1',
      );

      expect(task.isOverdue, isTrue);
      expect(task.isDone, isFalse);
    });

    test('does not mark completed tasks as overdue', () {
      final task = TaskItem(
        title: 'Done task',
        status: TaskStatus.done,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
        userId: 'user-1',
      );

      expect(task.isOverdue, isFalse);
      expect(task.isDone, isTrue);
    });
  });
}
