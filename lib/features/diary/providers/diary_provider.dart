/// ============================================================================
/// DayFlow - 日记状态管理 (Providers)
/// ============================================================================
///
/// 该文件定义了日记模块的所有 Riverpod 状态管理逻辑，包括：
/// - [DiaryListState] / [DiaryListNotifier]：日记列表的加载、筛选、搜索
/// - [DiaryEditorState] / [DiaryEditorNotifier]：日记编辑器的状态管理
/// - [selectedDateProvider]：当前选中的日期筛选条件
///
/// ## 架构说明
///
/// 所有 Provider 均使用手动定义方式（非代码生成），确保与项目约定一致。
/// 状态使用 sealed class 模式，实现类型安全的状态匹配。
///
/// ## 数据流向
///
/// UI (ConsumerWidget) → Provider (StateNotifier) → Repository → DAO / Supabase
/// ============================================================================
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dayflow/features/diary/data/diary_repository.dart';
import 'package:dayflow/features/diary/domain/diary_entry.dart';

// ==============================================================================
// 日期筛选 Provider
// ==============================================================================

/// 当前选中日期 Provider
///
/// 用于日记列表页面的日期筛选功能。
/// 默认值为 null，表示不筛选（显示所有日记）。
/// 设置具体日期后，日记列表将只显示该日期范围内的条目。
///
/// 使用方式：
/// ```dart
/// // 读取当前选中日期
/// final date = ref.watch(selectedDateProvider);
///
/// // 设置筛选日期
/// ref.read(selectedDateProvider.notifier).state = DateTime.now();
///
/// // 清除筛选
/// ref.read(selectedDateProvider.notifier).state = null;
/// ```
final selectedDateProvider = StateProvider<DateTime?>((ref) => null);

/// 搜索关键词 Provider
///
/// 用于日记列表页面的搜索功能。
/// 默认值为空字符串，表示不搜索。
final searchKeywordProvider = StateProvider<String>((ref) => '');

// ==============================================================================
// 日记列表状态 (DiaryListState)
// ==============================================================================

/// 日记列表状态基类（密封类）
///
/// 使用 sealed class 模式实现类型安全的状态管理。
/// 包含三种状态：加载中、已加载（含数据）、错误。
///
/// 在 UI 中通过 switch 语句匹配不同状态：
/// ```dart
/// switch (state) {
///   case DiaryListLoading():
///     return CircularProgressIndicator();
///   case DiaryListData(:final entries):
///     return ListView(...);
///   case DiaryListError(:final message):
///     return Text(message);
/// }
/// ```
sealed class DiaryListState {
  const DiaryListState();
}

/// 日记列表加载中状态
class DiaryListLoading extends DiaryListState {
  const DiaryListLoading();
}

/// 日记列表已加载状态（包含数据）
///
/// [entries] 日记条目列表，可能为空列表（无数据）
class DiaryListData extends DiaryListState {
  /// 日记条目列表
  final List<DiaryEntry> entries;

  const DiaryListData(this.entries);
}

/// 日记列表错误状态
///
/// [message] 用户友好的错误提示消息
class DiaryListError extends DiaryListState {
  /// 错误信息
  final String message;

  const DiaryListError(this.message);
}

// ==============================================================================
// 日记列表 Notifier
// ==============================================================================

/// 日记列表状态通知器
///
/// 负责管理日记列表的加载、刷新、筛选和搜索逻辑。
/// 通过 [DiaryRepository] 获取数据，并将结果封装为 [DiaryListState]。
///
/// 支持的操作：
/// - [loadEntries]：加载指定用户的所有日记
/// - [loadByDateRange]：按日期范围筛选
/// - [search]：按关键词搜索
/// - [refresh]：刷新列表（保留当前筛选条件）
class DiaryListNotifier extends StateNotifier<DiaryListState> {
  /// 日记仓库引用
  final DiaryRepository _repository;

  /// 当前用户 ID（用于数据隔离）
  final String _userId;

  /// 当前搜索关键词（用于刷新时保留搜索条件）
  String _currentKeyword = '';

  /// 当前日期筛选范围（用于刷新时保留筛选条件）
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;

  /// 构造函数
  ///
  /// [repository] 日记数据仓库
  /// [userId] 当前登录用户的 ID
  ///
  /// 初始状态为 [DiaryListLoading]，创建后应立即调用 [loadEntries]。
  DiaryListNotifier({
    required DiaryRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const DiaryListLoading());

  /// 加载指定用户的所有日记条目
  ///
  /// 清除之前的筛选条件，显示全部日记。
  /// 成功时切换到 [DiaryListData] 状态，失败时切换到 [DiaryListError]。
  Future<void> loadEntries() async {
    state = const DiaryListLoading();
    _currentKeyword = '';
    _currentStartDate = null;
    _currentEndDate = null;

    try {
      final entries = await _repository.getAllEntries(_userId);
      state = DiaryListData(entries);
    } catch (e) {
      debugPrint('[DiaryListNotifier] 加载日记列表失败: $e');
      state = const DiaryListError('加载日记失败，请稍后重试');
    }
  }

  /// 按日期范围筛选日记
  ///
  /// [startDate] 起始日期（包含）
  /// [endDate] 结束日期（包含）
  Future<void> loadByDateRange(DateTime startDate, DateTime endDate) async {
    state = const DiaryListLoading();
    _currentStartDate = startDate;
    _currentEndDate = endDate;
    _currentKeyword = '';

    try {
      final entries = await _repository.getEntriesByDateRange(
        _userId,
        startDate,
        endDate,
      );
      state = DiaryListData(entries);
    } catch (e) {
      debugPrint('[DiaryListNotifier] 按日期范围筛选失败: $e');
      state = const DiaryListError('筛选日记失败，请稍后重试');
    }
  }

  /// 搜索日记内容
  ///
  /// 在日记正文中进行模糊搜索。
  /// 如果关键词为空，则加载所有日记。
  ///
  /// [keyword] 搜索关键词
  Future<void> search(String keyword) async {
    if (keyword.trim().isEmpty) {
      return loadEntries();
    }

    state = const DiaryListLoading();
    _currentKeyword = keyword;
    _currentStartDate = null;
    _currentEndDate = null;

    try {
      final entries = await _repository.searchEntries(_userId, keyword);
      state = DiaryListData(entries);
    } catch (e) {
      debugPrint('[DiaryListNotifier] 搜索日记失败: $e');
      state = const DiaryListError('搜索失败，请稍后重试');
    }
  }

  /// 刷新日记列表
  ///
  /// 保留当前的筛选/搜索条件，重新加载数据。
  /// 适用于下拉刷新场景。
  Future<void> refresh() async {
    if (_currentKeyword.isNotEmpty) {
      return search(_currentKeyword);
    }
    if (_currentStartDate != null && _currentEndDate != null) {
      return loadByDateRange(_currentStartDate!, _currentEndDate!);
    }
    return loadEntries();
  }

  /// 触发云端同步，然后刷新本地列表
  ///
  /// 先从云端拉取最新数据合并到本地，再重新加载列表。
  Future<void> syncAndRefresh() async {
    try {
      await _repository.syncWithCloud(_userId);
      await refresh();
    } catch (e) {
      debugPrint('[DiaryListNotifier] 同步刷新失败: $e');
    }
  }
}

// ==============================================================================
// 日记编辑器状态 (DiaryEditorState)
// ==============================================================================

/// 日记编辑器状态基类（密封类）
///
/// 管理日记编辑页面的状态流转：
/// - [DiaryEditorInitial]：初始状态（新建日记）
/// - [DiaryEditorLoaded]：已加载日记数据（编辑已有日记）
/// - [DiaryEditorSaving]：保存中
/// - [DiaryEditorSaved]：保存成功
/// - [DiaryEditorError]：操作失败
sealed class DiaryEditorState {
  const DiaryEditorState();
}

/// 编辑器初始状态
///
/// 用于新建日记的场景，此时没有已有数据。
class DiaryEditorInitial extends DiaryEditorState {
  const DiaryEditorInitial();
}

/// 编辑器已加载状态
///
/// 包含当前正在编辑的日记数据。
/// 可以是从数据库加载的已有日记，也可以是用户正在编辑的草稿。
///
/// [entry] 当前日记数据
/// [isDirty] 是否有未保存的修改
class DiaryEditorLoaded extends DiaryEditorState {
  /// 当前日记条目数据
  final DiaryEntry entry;

  /// 是否有未保存的更改
  final bool isDirty;

  const DiaryEditorLoaded({
    required this.entry,
    this.isDirty = false,
  });
}

/// 编辑器保存中状态
class DiaryEditorSaving extends DiaryEditorState {
  const DiaryEditorSaving();
}

/// 编辑器保存成功状态
///
/// [entry] 保存后的完整日记对象（包含数据库 ID）
class DiaryEditorSaved extends DiaryEditorState {
  /// 保存后的日记条目
  final DiaryEntry entry;

  const DiaryEditorSaved(this.entry);
}

/// 编辑器错误状态
///
/// [message] 用户友好的错误提示
class DiaryEditorError extends DiaryEditorState {
  /// 错误信息
  final String message;

  const DiaryEditorError(this.message);
}

// ==============================================================================
// 日记编辑器 Notifier
// ==============================================================================

/// 日记编辑器状态通知器
///
/// 负责管理日记编辑页面的完整生命周期：
/// - 初始化（新建或加载已有日记）
/// - 内容修改追踪
/// - 保存 / 更新 / 删除操作
/// - 自动保存草稿
///
/// 使用方式：
/// ```dart
/// // 新建日记
/// ref.read(diaryEditorProvider.notifier).initNew(userId);
///
/// // 编辑已有日记
/// ref.read(diaryEditorProvider.notifier).loadEntry(entryId);
///
/// // 保存日记
/// ref.read(diaryEditorProvider.notifier).save(content, mood);
/// ```
class DiaryEditorNotifier extends StateNotifier<DiaryEditorState> {
  /// 日记仓库引用
  final DiaryRepository _repository;

  /// 构造函数
  ///
  /// [repository] 日记数据仓库
  DiaryEditorNotifier({
    required DiaryRepository repository,
  })  : _repository = repository,
        super(const DiaryEditorInitial());

  /// 初始化新建日记
  ///
  /// 创建一个空白的日记模板，日期默认为今天。
  ///
  /// [userId] 当前登录用户 ID
  /// [date] 日记日期，默认为当天
  void initNew(String userId, {DateTime? date}) {
    final now = DateTime.now();
    final entry = DiaryEntry(
      content: '',
      mood: null,
      date: date ?? now,
      createdAt: now,
      updatedAt: now,
      userId: userId,
    );
    state = DiaryEditorLoaded(entry: entry, isDirty: false);
  }

  /// 加载已有日记进行编辑
  ///
  /// 根据日记 ID 从仓库中加载数据。
  ///
  /// [entryId] 日记条目 ID
  Future<void> loadEntry(int entryId) async {
    try {
      final entry = await _repository.getEntryById(entryId);
      if (entry != null) {
        state = DiaryEditorLoaded(entry: entry, isDirty: false);
      } else {
        state = const DiaryEditorError('日记不存在或已被删除');
      }
    } catch (e) {
      debugPrint('[DiaryEditorNotifier] 加载日记失败: $e');
      state = const DiaryEditorError('加载日记失败，请稍后重试');
    }
  }

  /// 更新编辑中的内容（标记为脏数据）
  ///
  /// 当用户修改日记内容或心情时调用，将 isDirty 标记为 true。
  /// 不触发数据库写入，仅更新内存中的状态。
  ///
  /// [content] 最新的日记正文
  /// [mood] 最新的心情选择
  void updateContent({String? content, Mood? mood}) {
    final currentState = state;
    if (currentState is DiaryEditorLoaded) {
      state = DiaryEditorLoaded(
        entry: currentState.entry.copyWith(
          content: content ?? currentState.entry.content,
          mood: mood ?? currentState.entry.mood,
          updatedAt: DateTime.now(),
        ),
        isDirty: true,
      );
    }
  }

  /// 保存日记（新建或更新）
  ///
  /// 根据日记是否有 ID 来判断是新建还是更新操作。
  /// 保存成功后切换到 [DiaryEditorSaved] 状态。
  ///
  /// [content] 日记正文内容
  /// [mood] 心情选择（可选）
  Future<void> save(String content, Mood? mood) async {
    final currentState = state;
    if (currentState is! DiaryEditorLoaded) return;

    state = const DiaryEditorSaving();

    try {
      final entryToSave = currentState.entry.copyWith(
        content: content,
        mood: mood,
        updatedAt: DateTime.now(),
      );

      DiaryEntry savedEntry;
      if (entryToSave.id == null) {
        // 新建日记
        savedEntry = await _repository.createEntry(entryToSave);
      } else {
        // 更新已有日记
        savedEntry = await _repository.updateEntry(entryToSave);
      }

      state = DiaryEditorSaved(savedEntry);
    } catch (e) {
      debugPrint('[DiaryEditorNotifier] 保存日记失败: $e');
      state = const DiaryEditorError('保存失败，请稍后重试');
      // 恢复到编辑状态，保留用户输入
      if (currentState is DiaryEditorLoaded) {
        state = DiaryEditorLoaded(
          entry: currentState.entry.copyWith(content: content, mood: mood),
          isDirty: true,
        );
      }
    }
  }

  /// 删除当前日记
  ///
  /// 弹出确认对话框后调用此方法执行删除。
  /// 删除成功后切换到 [DiaryEditorInitial] 状态。
  Future<bool> delete() async {
    final currentState = state;
    if (currentState is! DiaryEditorLoaded) return false;

    final entry = currentState.entry;
    if (entry.id == null) return false;

    try {
      await _repository.deleteEntry(entry.id!, entry.userId);
      state = const DiaryEditorInitial();
      return true;
    } catch (e) {
      debugPrint('[DiaryEditorNotifier] 删除日记失败: $e');
      state = const DiaryEditorError('删除失败，请稍后重试');
      return false;
    }
  }

  /// 自动保存草稿
  ///
  /// 当编辑器有未保存的修改时，自动保存当前内容。
  /// 通常在页面失去焦点或定时触发时调用。
  ///
  /// [content] 当前编辑器中的内容
  /// [mood] 当前选中的心情
  Future<void> autoSaveDraft(String content, Mood? mood) async {
    final currentState = state;
    if (currentState is! DiaryEditorLoaded || !currentState.isDirty) return;

    // 静默保存，不切换到 Saving 状态（避免 UI 闪烁）
    try {
      final entryToSave = currentState.entry.copyWith(
        content: content,
        mood: mood,
        updatedAt: DateTime.now(),
      );

      if (entryToSave.id == null) {
        final saved = await _repository.createEntry(entryToSave);
        state = DiaryEditorLoaded(entry: saved, isDirty: false);
      } else {
        final saved = await _repository.updateEntry(entryToSave);
        state = DiaryEditorLoaded(entry: saved, isDirty: false);
      }

      debugPrint('[DiaryEditorNotifier] 草稿自动保存成功');
    } catch (e) {
      debugPrint('[DiaryEditorNotifier] 草稿自动保存失败: $e');
    }
  }
}

// ==============================================================================
// Riverpod Providers（手动定义，非代码生成）
// ==============================================================================

/// 日记列表 StateNotifierProvider
///
/// 管理日记列表页面的状态。
/// 依赖 [diaryRepositoryProvider] 获取数据。
///
/// 注意：需要传入 userId 参数，使用 .family 修饰符。
///
/// 使用方式：
/// ```dart
/// final state = ref.watch(diaryListProvider('user-123'));
/// ref.read(diaryListProvider('user-123').notifier).loadEntries();
/// ```
final diaryListProvider =
    StateNotifierProvider.family<DiaryListNotifier, DiaryListState, String>(
  (ref, userId) {
    final repository = ref.watch(diaryRepositoryProvider);
    final notifier = DiaryListNotifier(
      repository: repository,
      userId: userId,
    );
    // 创建后自动加载数据
    notifier.loadEntries();
    return notifier;
  },
);

/// 日记编辑器 StateNotifierProvider
///
/// 管理日记编辑页面的状态。
/// 每次进入编辑页面时，应通过 notifier 初始化状态。
///
/// 使用方式：
/// ```dart
/// // 新建日记
/// ref.read(diaryEditorProvider.notifier).initNew('user-123');
///
/// // 编辑日记
/// ref.read(diaryEditorProvider.notifier).loadEntry(entryId);
///
/// // 保存日记
/// ref.read(diaryEditorProvider.notifier).save(content, mood);
/// ```
final diaryEditorProvider =
    StateNotifierProvider<DiaryEditorNotifier, DiaryEditorState>(
  (ref) {
    final repository = ref.watch(diaryRepositoryProvider);
    return DiaryEditorNotifier(repository: repository);
  },
);
