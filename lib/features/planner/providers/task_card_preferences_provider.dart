library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayflow/features/planner/domain/task_item.dart';

const _kTaskCardPrefsKey = 'task_card_preferences_v1';

class TaskCardPreferences {
  final int reminderCount;
  final String backgroundStyle;

  const TaskCardPreferences({
    this.reminderCount = 0,
    this.backgroundStyle = 'aurora',
  });

  TaskCardPreferences copyWith({
    int? reminderCount,
    String? backgroundStyle,
  }) {
    return TaskCardPreferences(
      reminderCount: reminderCount ?? this.reminderCount,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reminder_count': reminderCount,
      'background_style': backgroundStyle,
    };
  }

  factory TaskCardPreferences.fromJson(Map<String, dynamic> json) {
    return TaskCardPreferences(
      reminderCount: (json['reminder_count'] as num?)?.toInt() ?? 0,
      backgroundStyle: json['background_style'] as String? ?? 'aurora',
    );
  }
}

class TaskCardPreferencesNotifier
    extends StateNotifier<Map<String, TaskCardPreferences>> {
  TaskCardPreferencesNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTaskCardPrefsKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    state = {
      for (final entry in decoded.entries)
        entry.key: TaskCardPreferences.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        ),
    };
  }

  Future<void> setPreference(
      String taskKey, TaskCardPreferences preference) async {
    state = {
      ...state,
      taskKey: preference,
    };

    await _persist();
  }

  TaskCardPreferences preferenceOf(String taskKey) {
    return state[taskKey] ?? const TaskCardPreferences();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      for (final entry in state.entries) entry.key: entry.value.toJson(),
    };
    await prefs.setString(_kTaskCardPrefsKey, jsonEncode(payload));
  }
}

String taskPreferenceKey(TaskItem task) {
  if (task.cloudId != null && task.cloudId!.isNotEmpty) {
    return 'cloud:${task.cloudId}';
  }
  if (task.id != null) {
    return 'local:${task.id}';
  }
  return 'fallback:${task.userId}:${task.title.hashCode}';
}

final taskCardPreferencesProvider = StateNotifierProvider<
    TaskCardPreferencesNotifier, Map<String, TaskCardPreferences>>((ref) {
  return TaskCardPreferencesNotifier();
});
