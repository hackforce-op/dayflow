library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/router/app_router.dart';
import 'package:dayflow/features/auth/providers/auth_provider.dart';
import 'package:dayflow/features/profile/data/profile_repository.dart';
import 'package:dayflow/features/profile/presentation/widgets/profile_edit_dialog.dart';
import 'package:dayflow/features/settings/presentation/pages/settings_page.dart';
import 'package:dayflow/shared/widgets/app_bottom_nav.dart';
import 'package:dayflow/shared/widgets/blur_dialog.dart';

class AppShellScaffold extends ConsumerStatefulWidget {
  const AppShellScaffold({
    required this.child,
    required this.currentIndex,
    super.key,
  });

  final Widget child;
  final int currentIndex;

  @override
  ConsumerState<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends ConsumerState<AppShellScaffold> {
  static const _minWidth = 220.0;
  static const _maxWidth = 420.0;
  static const _desktopBreakpoint = 960.0;
  static const _toggleRailWidth = 44.0;

  double _sidebarWidth = 280;
  bool _sidebarCollapsed = false;
  String? _sidebarProfileUserId;
  String? _sidebarDisplayNameOverride;
  String? _sidebarAvatarUrlOverride;

  @override
  void initState() {
    super.initState();
    _loadSidebarWidth();
  }

  Future<void> _loadSidebarWidth() async {
    final prefs = await SharedPreferences.getInstance();
    final storedWidth = prefs.getDouble(AppConstants.sidebarWidthPrefsKey);
    final storedCollapsed =
        prefs.getBool(AppConstants.sidebarCollapsedPrefsKey);
    if (!mounted) {
      return;
    }

    setState(() {
      if (storedWidth != null) {
        _sidebarWidth = storedWidth.clamp(_minWidth, _maxWidth);
      }
      _sidebarCollapsed = storedCollapsed ?? false;
    });
  }

  Future<void> _persistSidebarWidth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.sidebarWidthPrefsKey, _sidebarWidth);
    await prefs.setBool(
      AppConstants.sidebarCollapsedPrefsKey,
      _sidebarCollapsed,
    );
  }

  void _toggleSidebarCollapsed() {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
      if (!_sidebarCollapsed && _sidebarWidth < _minWidth) {
        _sidebarWidth = 280;
      }
    });
    unawaited(_persistSidebarWidth());
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    if (width < _desktopBreakpoint) {
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: AppBottomNav(currentIndex: widget.currentIndex),
      );
    }

    final authState = ref.watch(authProvider);
    final authenticatedUser =
        authState is AuthStateAuthenticated ? authState.userProfile : null;
    final usesLocalProfileOverride = authenticatedUser != null &&
        authenticatedUser.id == _sidebarProfileUserId;
    final userName = authenticatedUser != null
        ? (usesLocalProfileOverride &&
                _sidebarDisplayNameOverride != null &&
                _sidebarDisplayNameOverride!.trim().isNotEmpty
            ? _sidebarDisplayNameOverride!
            : (authenticatedUser.displayName ?? authenticatedUser.email))
        : '未登录用户';
    final userEmail = authenticatedUser?.email ?? '登录后可同步数据';
    final avatarUrl = authenticatedUser != null
        ? (usesLocalProfileOverride
            ? _sidebarAvatarUrlOverride
            : authenticatedUser.avatarUrl)
        : null;

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: _sidebarCollapsed ? 0 : _sidebarWidth,
            clipBehavior: _sidebarCollapsed ? Clip.none : Clip.hardEdge,
            decoration: _sidebarCollapsed
                ? null
                : BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.surface,
                        theme.colorScheme.surfaceContainerLow,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
            child: _sidebarCollapsed
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showProfileCard(context),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage: avatarUrl != null &&
                                            avatarUrl.isNotEmpty
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child:
                                        avatarUrl == null || avatarUrl.isEmpty
                                            ? Text(_initialOf(userName))
                                            : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        Text(
                                          userEmail,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _NavTile(
                            icon: Icons.book_outlined,
                            selectedIcon: Icons.book,
                            label: '日记',
                            selected: widget.currentIndex == 0,
                            onTap: () => context.go(RoutePaths.diary),
                          ),
                          _NavTile(
                            icon: Icons.calendar_today_outlined,
                            selectedIcon: Icons.calendar_today,
                            label: '规划',
                            selected: widget.currentIndex == 1,
                            onTap: () => context.go(RoutePaths.planner),
                          ),
                          _NavTile(
                            icon: Icons.newspaper_outlined,
                            selectedIcon: Icons.newspaper,
                            label: '新闻',
                            selected: widget.currentIndex == 2,
                            onTap: () => context.go(RoutePaths.news),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => showSettingsDialog(context),
                              icon: const Icon(Icons.settings_outlined),
                              label: const Text('设置'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          Container(
            width: _toggleRailWidth,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  IconButton(
                    tooltip: _sidebarCollapsed ? '展开侧边栏' : '收起侧边栏',
                    onPressed: _toggleSidebarCollapsed,
                    icon: Icon(
                      _sidebarCollapsed
                          ? Icons.keyboard_double_arrow_right
                          : Icons.keyboard_double_arrow_left,
                    ),
                  ),
                  if (_sidebarCollapsed) ...[
                    const SizedBox(height: 12),
                    RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        'DayFlow',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!_sidebarCollapsed)
            MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _sidebarWidth = (_sidebarWidth + details.delta.dx)
                        .clamp(_minWidth, _maxWidth);
                  });
                },
                onHorizontalDragEnd: (_) => _persistSidebarWidth(),
                child: Container(
                  width: 8,
                  color: theme.colorScheme.outlineVariant.withAlpha(90),
                ),
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Future<void> _showProfileCard(BuildContext context) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthStateAuthenticated) {
      return;
    }

    final profileRepo = ref.read(profileRepositoryProvider);
    final userId = authState.userProfile.id;
    final profile = await profileRepo.fetchProfile(authState.userProfile);
    if (!mounted || !context.mounted) {
      return;
    }

    final result = await showSettingsSafeProfileDialog(
      context,
      profileRepo,
      userId,
      profile,
    );
    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _sidebarProfileUserId = userId;
      _sidebarDisplayNameOverride = result.displayName;
      _sidebarAvatarUrlOverride = result.avatarUrl;
    });
  }

  Future<ProfileEditResult?> showSettingsSafeProfileDialog(
    BuildContext context,
    ProfileRepository profileRepo,
    String userId,
    ProfileData profile,
  ) {
    return showBlurDialog<ProfileEditResult>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '编辑个人资料',
      builder: (_) => ProfileEditDialog(
        profile: profile,
        onUploadAvatar: (image) => profileRepo.uploadAvatar(
          userId: userId,
          bytes: image.bytes,
          fileExtension: image.fileExtension,
          mimeType: image.mimeType,
        ),
        onSave: (displayName, avatarUrl) => profileRepo.updateProfile(
          userId: profile.userId,
          displayName: displayName,
          avatarUrl: avatarUrl,
        ),
      ),
    );
  }

  String _initialOf(String value) {
    if (value.isEmpty) {
      return '?';
    }
    return value.substring(0, 1).toUpperCase();
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        selected: selected,
        selectedTileColor:
            Theme.of(context).colorScheme.primaryContainer.withAlpha(150),
        leading: Icon(selected ? selectedIcon : icon),
        title: Text(label),
        onTap: onTap,
      ),
    );
  }
}
