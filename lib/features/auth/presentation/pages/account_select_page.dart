library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/router/app_router.dart';
import 'package:dayflow/features/auth/providers/auth_provider.dart';
import 'package:dayflow/features/auth/providers/remembered_accounts_provider.dart';

class AccountSelectPage extends ConsumerWidget {
  const AccountSelectPage({super.key});

  String _initialOf(String value) {
    if (value.isEmpty) {
      return '?';
    }
    return value.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(rememberedAccountsProvider);
    final authState = ref.watch(authProvider);
    final currentUser =
        authState is AuthStateAuthenticated ? authState.userProfile : null;

    if (currentUser != null &&
        !accounts.any((account) => account.email == currentUser.email)) {
      Future.microtask(() {
        ref.read(rememberedAccountsProvider.notifier).remember(currentUser);
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '请选择要登录的账号',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  if (currentUser != null)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            _initialOf(
                                currentUser.displayName ?? currentUser.email),
                          ),
                        ),
                        title:
                            Text(currentUser.displayName ?? currentUser.email),
                        subtitle: Text(currentUser.email),
                        trailing: FilledButton(
                          onPressed: () => context.go(RoutePaths.diary),
                          child: const Text('继续'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: accounts.isEmpty
                        ? const Center(
                            child: Text('还没有已记住的账号，先登录一个账号吧。'),
                          )
                        : ListView.separated(
                            itemCount: accounts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final account = accounts[index];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: account.avatarUrl != null
                                        ? NetworkImage(account.avatarUrl!)
                                        : null,
                                    child: account.avatarUrl == null
                                        ? Text(
                                            _initialOf(account.displayName ??
                                                account.email),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                      account.displayName ?? account.email),
                                  subtitle: Text(account.email),
                                  onTap: () {
                                    context.go(
                                      '${RoutePaths.login}?email=${Uri.encodeComponent(account.email)}',
                                    );
                                  },
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: '移除记录',
                                    onPressed: () {
                                      ref
                                          .read(rememberedAccountsProvider
                                              .notifier)
                                          .remove(account.email);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go(RoutePaths.login),
                    child: const Text('使用其他账号登录'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go(RoutePaths.register),
                    child: const Text('创建新账号'),
                  ),
                  if (currentUser != null)
                    TextButton(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).signOut();
                        if (context.mounted) {
                          context.go(RoutePaths.login);
                        }
                      },
                      child: const Text('退出当前账号并切换'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
