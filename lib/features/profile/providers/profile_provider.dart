library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dayflow/features/auth/providers/auth_provider.dart';
import 'package:dayflow/features/profile/data/profile_repository.dart';

final profileDataProvider = FutureProvider<ProfileData>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthStateAuthenticated) {
    throw StateError('未登录，无法读取资料');
  }

  return ref
      .read(profileRepositoryProvider)
      .fetchProfile(authState.userProfile);
});
