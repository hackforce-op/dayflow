/// DayFlow 底部导航栏组件
///
/// 此文件实现应用主界面的底部导航栏，包括：
/// - 三个标签页：日记、规划、新闻
/// - 与 go_router 集成，实现声明式导航
/// - 自动高亮当前选中的标签
///
/// 此组件作为 ShellRoute 的一部分使用，
/// 包裹在主页面的 Scaffold 中，提供统一的底部导航体验。
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 底部导航栏组件
///
/// 显示三个标签页：日记（diary）、规划（planner）、新闻（news），
/// 通过 [GoRouter] 管理页面切换。
///
/// [currentIndex] 用于指示当前选中的标签索引。
class AppBottomNav extends StatelessWidget {
  /// 创建底部导航栏
  ///
  /// [currentIndex] 当前选中的标签索引（0=日记，1=规划，2=新闻）
  const AppBottomNav({
    required this.currentIndex,
    super.key,
  });

  /// 当前选中的标签索引
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      // 当前选中的目标索引
      selectedIndex: currentIndex,
      // 标签点击回调：根据索引导航到对应路由
      onDestinationSelected: (index) => _onItemTapped(context, index),
      // 三个导航目标
      destinations: const [
        // 日记标签
        NavigationDestination(
          icon: Icon(Icons.book_outlined),
          selectedIcon: Icon(Icons.book),
          label: '日记',
          tooltip: '查看和编写日记',
        ),
        // 规划标签
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: '规划',
          tooltip: '管理日常任务和计划',
        ),
        // 新闻标签
        NavigationDestination(
          icon: Icon(Icons.newspaper_outlined),
          selectedIcon: Icon(Icons.newspaper),
          label: '新闻',
          tooltip: '浏览每日新闻摘要',
        ),
      ],
    );
  }

  /// 处理标签点击事件
  ///
  /// 根据点击的标签索引，使用 [GoRouter.go] 导航到对应路径。
  /// 使用 `go` 而非 `push` 以确保底部导航的页面切换
  /// 不会堆叠在导航栈中。
  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/diary');
      case 1:
        context.go('/planner');
      case 2:
        context.go('/news');
    }
  }
}

/// 根据当前路由路径计算底部导航栏的选中索引
///
/// 通过匹配当前 URL 路径的前缀来确定哪个标签应该被高亮。
/// 这个函数在 ShellRoute 的 builder 中使用。
///
/// [location] 当前路由的完整路径
/// 返回：对应的标签索引（0=日记，1=规划，2=新闻）
int calculateSelectedIndex(String location) {
  if (location.startsWith('/planner')) return 1;
  if (location.startsWith('/news')) return 2;
  // 默认选中日记标签（首页）
  return 0;
}
