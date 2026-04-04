library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/features/auth/domain/user_profile.dart';

class RememberedAccount {
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime lastUsedAt;

  const RememberedAccount({
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.lastUsedAt,
  });

  RememberedAccount copyWith({
    String? email,
    String? displayName,
    String? avatarUrl,
    DateTime? lastUsedAt,
  }) {
    return RememberedAccount(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'last_used_at': lastUsedAt.toIso8601String(),
    };
  }

  factory RememberedAccount.fromJson(Map<String, dynamic> json) {
    return RememberedAccount(
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      lastUsedAt: DateTime.tryParse(json['last_used_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class RememberedAccountsNotifier
    extends StateNotifier<List<RememberedAccount>> {
  RememberedAccountsNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.rememberedAccountsPrefsKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return;
    }

    final parsed = decoded
        .whereType<Map>()
        .map((entry) => RememberedAccount.fromJson(
              Map<String, dynamic>.from(entry),
            ))
        .toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));

    state = parsed;
  }

  Future<void> remember(UserProfile profile) async {
    final now = DateTime.now();
    final updated = [
      profile.email,
      ...state
          .where((item) => item.email != profile.email)
          .map((item) => item.email)
    ];

    final map = {
      for (final item in state) item.email: item,
      profile.email: RememberedAccount(
        email: profile.email,
        displayName: profile.displayName,
        avatarUrl: profile.avatarUrl,
        lastUsedAt: now,
      ),
    };

    state = updated.map((email) => map[email]!).toList();
    await _persist();
  }

  Future<void> remove(String email) async {
    state = state.where((item) => item.email != email).toList();
    await _persist();
  }

  Future<void> clear() async {
    state = const [];
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.rememberedAccountsPrefsKey,
      jsonEncode(state.map((item) => item.toJson()).toList()),
    );
  }
}

final rememberedAccountsProvider =
    StateNotifierProvider<RememberedAccountsNotifier, List<RememberedAccount>>(
        (ref) {
  return RememberedAccountsNotifier();
});
