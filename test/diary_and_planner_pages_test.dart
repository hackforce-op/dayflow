import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:dayflow/features/auth/data/auth_repository.dart' as auth_data;
import 'package:dayflow/features/auth/domain/user_profile.dart';
import 'package:dayflow/features/auth/providers/auth_provider.dart';
import 'package:dayflow/features/diary/data/diary_repository.dart';
import 'package:dayflow/features/diary/domain/diary_entry.dart';
import 'package:dayflow/features/diary/presentation/pages/diary_list_page.dart';
import 'package:dayflow/features/planner/data/task_repository.dart';
import 'package:dayflow/features/planner/domain/task_item.dart';
import 'package:dayflow/features/planner/presentation/pages/planner_page.dart';

void main() {
  final testUser = UserProfile(
    id: 'user-1',
    email: 'tester@example.com',
    displayName: '测试用户',
    createdAt: DateTime(2026, 1, 1),
  );

  group('DiaryListPage', () {
    testWidgets('loads authenticated diary entries and supports search', (
      tester,
    ) async {
      final repository = _FakeDiaryRepository([
        DiaryEntry(
          id: 1,
          content: '今天完成了规划页测试梳理',
          mood: Mood.happy,
          date: DateTime(2026, 3, 29),
          createdAt: DateTime(2026, 3, 29, 8),
          updatedAt: DateTime(2026, 3, 29, 9),
          userId: testUser.id,
        ),
        DiaryEntry(
          id: 2,
          content: '晚上散步后整理了发布说明',
          mood: Mood.calm,
          date: DateTime(2026, 3, 30),
          createdAt: DateTime(2026, 3, 30, 20),
          updatedAt: DateTime(2026, 3, 30, 21),
          userId: testUser.id,
        ),
      ]);

      await _pumpTestApp(
        tester,
        child: const DiaryListPage(),
        overrides: [
          authProvider.overrideWith(
            (ref) => _TestAuthNotifier(AuthStateAuthenticated(testUser)),
          ),
          diaryRepositoryProvider.overrideWithValue(repository),
        ],
      );

      expect(find.text('我的日记'), findsOneWidget);
      expect(find.textContaining('今天完成了规划页测试梳理'), findsOneWidget);
      expect(find.textContaining('晚上散步后整理了发布说明'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '散步');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.textContaining('晚上散步后整理了发布说明'), findsOneWidget);
      expect(find.textContaining('今天完成了规划页测试梳理'), findsNothing);
    });

    testWidgets('deletes an entry by swipe and refreshes the list', (
      tester,
    ) async {
      final repository = _FakeDiaryRepository([
        DiaryEntry(
          id: 10,
          content: '需要被删除的日记',
          mood: Mood.tired,
          date: DateTime(2026, 3, 30),
          createdAt: DateTime(2026, 3, 30, 9),
          updatedAt: DateTime(2026, 3, 30, 9),
          userId: testUser.id,
        ),
      ]);

      await _pumpTestApp(
        tester,
        child: const DiaryListPage(),
        overrides: [
          authProvider.overrideWith(
            (ref) => _TestAuthNotifier(AuthStateAuthenticated(testUser)),
          ),
          diaryRepositoryProvider.overrideWithValue(repository),
        ],
      );

      expect(find.text('需要被删除的日记'), findsOneWidget);

      await tester.drag(find.byType(Dismissible), const Offset(-800, 0));
      await tester.pumpAndSettle();

      expect(find.text('需要被删除的日记'), findsNothing);
      expect(find.text('还没有日记，点击 + 开始写第一篇吧！'), findsOneWidget);
    });
  });

  group('PlannerPage', () {
    testWidgets('loads today tasks and filters by status', (tester) async {
      final repository = _FakeTaskRepository([
        TaskItem(
          id: 1,
          title: '准备评审材料',
          description: '整理今天的迭代说明',
          priority: TaskPriority.high,
          status: TaskStatus.todo,
          dueDate: DateTime.now(),
          createdAt: DateTime(2026, 3, 30, 9),
          userId: testUser.id,
        ),
        TaskItem(
          id: 2,
          title: '完成晨间复盘',
          priority: TaskPriority.medium,
          status: TaskStatus.done,
          dueDate: DateTime.now(),
          createdAt: DateTime(2026, 3, 30, 7),
          userId: testUser.id,
        ),
      ]);

      await _pumpTestApp(
        tester,
        child: const PlannerPage(),
        overrides: [
          authProvider.overrideWith(
            (ref) => _TestAuthNotifier(AuthStateAuthenticated(testUser)),
          ),
          taskRepositoryProvider.overrideWithValue(repository),
        ],
      );

      expect(find.text('准备评审材料'), findsOneWidget);
      expect(find.text('完成晨间复盘'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('✅ 已完成').last);
      await tester.pumpAndSettle();

      expect(find.text('完成晨间复盘'), findsOneWidget);
      expect(find.text('准备评审材料'), findsNothing);
    });

    testWidgets('toggles task status and supports swipe delete',
        (tester) async {
      final repository = _FakeTaskRepository([
        TaskItem(
          id: 9,
          title: '补全 widget test',
          priority: TaskPriority.high,
          status: TaskStatus.todo,
          dueDate: DateTime.now(),
          createdAt: DateTime(2026, 3, 30, 10),
          userId: testUser.id,
        ),
      ]);

      await _pumpTestApp(
        tester,
        child: const PlannerPage(),
        overrides: [
          authProvider.overrideWith(
            (ref) => _TestAuthNotifier(AuthStateAuthenticated(testUser)),
          ),
          taskRepositoryProvider.overrideWithValue(repository),
        ],
      );

      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);

      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.timelapse), findsOneWidget);

      await tester.drag(find.byType(Dismissible), const Offset(-800, 0));
      await tester.pumpAndSettle();

      expect(find.text('补全 widget test'), findsNothing);
      expect(find.text('今天还没有任务，点击 + 创建一个吧！'), findsOneWidget);
    });
  });
}

Future<void> _pumpTestApp(
  WidgetTester tester, {
  required Widget child,
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: child,
      ),
    ),
  );

  await tester.pump();
  await tester.pumpAndSettle();
}

class _FakeAuthRepository implements auth_data.AuthRepository {
  @override
  supabase.User? getCurrentUser() => null;

  @override
  Stream<supabase.AuthState> get onAuthStateChange =>
      Stream<supabase.AuthState>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState) : super(_FakeAuthRepository()) {
    state = initialState;
  }
}

class _FakeDiaryRepository implements DiaryRepository {
  _FakeDiaryRepository(List<DiaryEntry> seedEntries)
      : _entries = List<DiaryEntry>.from(seedEntries);

  final List<DiaryEntry> _entries;

  @override
  Future<void> deleteEntry(int id, String userId) async {
    _entries.removeWhere((entry) => entry.id == id && entry.userId == userId);
  }

  @override
  Future<List<DiaryEntry>> getAllEntries(String userId) async {
    final filtered = _entries.where((entry) => entry.userId == userId).toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  @override
  Future<List<DiaryEntry>> getEntriesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final filtered = await getAllEntries(userId);
    return filtered
        .where(
          (entry) =>
              !entry.date.isBefore(startDate) && !entry.date.isAfter(endDate),
        )
        .toList();
  }

  @override
  Future<List<DiaryEntry>> searchEntries(String userId, String keyword) async {
    final filtered = await getAllEntries(userId);
    return filtered.where((entry) => entry.content.contains(keyword)).toList();
  }

  @override
  Future<void> syncWithCloud(String userId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTaskRepository implements TaskRepository {
  _FakeTaskRepository(List<TaskItem> seedTasks)
      : _tasks = List<TaskItem>.from(seedTasks),
        _nextId = (seedTasks
                .map((task) => task.id ?? 0)
                .fold<int>(0, (a, b) => a > b ? a : b)) +
            1;

  final List<TaskItem> _tasks;
  int _nextId;

  @override
  Future<TaskItem> createTask(TaskItem task) async {
    final created = task.copyWith(id: _nextId++);
    _tasks.add(created);
    return created;
  }

  @override
  Future<void> deleteTask(int taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
  }

  @override
  Future<List<TaskItem>> getAllTasks(String userId) async {
    return _tasks.where((task) => task.userId == userId).toList();
  }

  @override
  Future<List<TaskItem>> getTasksByStatus(
      String userId, TaskStatus status) async {
    return _tasks
        .where((task) => task.userId == userId && task.status == status)
        .toList();
  }

  @override
  Future<List<TaskItem>> getTodayTasks(String userId) async {
    final now = DateTime.now();
    return _tasks.where((task) {
      final dueDate = task.dueDate;
      return task.userId == userId &&
          dueDate != null &&
          dueDate.year == now.year &&
          dueDate.month == now.month &&
          dueDate.day == now.day;
    }).toList();
  }

  @override
  Future<void> updateTaskStatus(int taskId, TaskStatus status) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) {
      return;
    }

    _tasks[index] = _tasks[index].copyWith(status: status);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
