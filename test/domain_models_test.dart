import 'package:flutter_test/flutter_test.dart';

import 'package:dayflow/features/diary/domain/diary_entry.dart';
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
