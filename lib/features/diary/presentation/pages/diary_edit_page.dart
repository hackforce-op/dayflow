/// DayFlow - 日记编辑页面（富文本版）
///
/// 支持创建新日记和编辑已有日记。
/// 使用 flutter_quill 富文本编辑器，支持：
/// - Markdown 格式排版（加粗、斜体、标题、列表等）
/// - 插入图片（上传到 Supabase Storage）
/// - 记录地理位置（需要用户授权）
/// - 情绪标签选择
library;

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/supabase/supabase_client.dart';
import 'package:dayflow/features/auth/providers/auth_provider.dart';
import 'package:dayflow/features/diary/data/diary_repository.dart';
import 'package:dayflow/features/diary/domain/diary_entry.dart';
import 'package:dayflow/features/diary/providers/diary_provider.dart';
import 'package:dayflow/features/diary/presentation/widgets/diary_image_embed.dart';
import 'package:dayflow/features/diary/presentation/widgets/mood_selector.dart';
import 'package:dayflow/shared/utils/date_utils.dart';
import 'package:dayflow/shared/widgets/blur_dialog.dart';

/// 日记编辑页面
class DiaryEditPage extends ConsumerStatefulWidget {
  /// 日记 ID，为 null 表示新建模式
  final int? diaryId;

  /// 所属日记本 ID（新建日记时使用）
  final int? notebookId;

  const DiaryEditPage({super.key, this.diaryId, this.notebookId});

  @override
  ConsumerState<DiaryEditPage> createState() => _DiaryEditPageState();
}

class _DiaryEditPageState extends ConsumerState<DiaryEditPage> {
  static const Uuid _uuid = Uuid();

  /// IP 粗略定位提示是否已在本次应用会话中显示过
  static bool _ipWarningShownThisSession = false;

  /// Quill 富文本控制器
  late QuillController _quillController;

  /// 当前选中的情绪
  Mood? _selectedMood;

  /// 当前日期（用于展示，创建后不可更改）
  DateTime _date = DateTime.now();

  /// 地理位置坐标字符串（纬度,经度）
  String? _location;

  /// 地点名称（可读的地址信息）
  String? _locationName;

  /// 已上传图片 URL 列表（用于在列表页展示封面）
  final List<String> _uploadedImageUrls = [];

  /// 已持久化到当前日记的图片 URL，用于保存时清理云端残留
  final List<String> _persistedImageUrls = [];

  /// 编辑期间被移除、待在保存后清理的图片 URL
  final Set<String> _pendingRemovedImageUrls = <String>{};

  /// data URI → 云端公网 URL 的映射，后台上传完成后填充，保存时统一替换
  final Map<String, String> _dataUriToCloudUrl = {};

  /// 是否为编辑模式
  bool get _isEditing => widget.diaryId != null;

  /// 上次绑定的日记 ID（防止重复绑定）
  int? _lastBoundEntryId;

  /// 控制器版本号，用于强制重建工具栏（修复撤销/重做）
  int _controllerVersion = 0;

  /// 编辑器滚动控制器，跨 rebuild 保持滚动位置
  final ScrollController _editorScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 初始化 Quill 控制器（空白文档）
    _quillController = QuillController.basic();
    _quillController.addListener(_handleEditorDocumentChanged);
    Future.microtask(_initializeEditor);
  }

  /// 初始化编辑器：新建或加载已有日记
  Future<void> _initializeEditor() async {
    final editorNotifier = ref.read(diaryEditorProvider.notifier);
    editorNotifier.reset();

    if (_isEditing) {
      await editorNotifier.loadEntry(widget.diaryId!);
      return;
    }

    final authState = ref.read(authProvider);
    if (authState is AuthStateAuthenticated) {
      editorNotifier.initNew(
        authState.userProfile.id,
        notebookId: widget.notebookId,
      );
    }

    // 新建日记：根据已保存的偏好自动获取位置
    await _autoCaptureLoctionIfAllowed();
  }

  /// 新建日记时自动处理位置记录
  ///
  /// - 如果用户之前允许过 → 自动获取位置
  /// - 如果是首次（尚未询问过）→ 弹窗询问并记住选择
  /// - 如果用户之前拒绝过 → 不打扰
  Future<void> _autoCaptureLoctionIfAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    final pref = prefs.getString(AppConstants.locationPermPrefsKey);

    if (pref == 'true') {
      await _doCapture();
    } else if (pref == null) {
      // 首次使用：弹窗询问
      if (!mounted) return;
      final allow = await showBlurDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('记录当前位置'),
          content: const Text(
            'DayFlow 可以在每次写日记时自动记录您的当前位置。\n\n'
            '您的选择将被记住，之后新建日记时将自动应用此偏好。\n'
            '您随时可以在设置中更改。',
          ),
          actions: [
            TextButton(
              onPressed: () => ctx.pop(false),
              child: const Text('不需要'),
            ),
            FilledButton(
              onPressed: () => ctx.pop(true),
              child: const Text('允许'),
            ),
          ],
        ),
      );

      if (allow == true) {
        await prefs.setString(AppConstants.locationPermPrefsKey, 'true');
        await _doCapture();
      } else if (allow == false) {
        await prefs.setString(AppConstants.locationPermPrefsKey, 'false');
      }
    }
    // pref == 'false' → 用户之前拒绝过，不打扰
  }

  @override
  void dispose() {
    _quillController.removeListener(_handleEditorDocumentChanged);
    _quillController.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  /// 将 Quill Delta JSON 字符串加载到控制器
  void _loadContentToEditor(String content) {
    Document newDoc;
    try {
      if (content.trim().isEmpty) {
        newDoc = Document();
      } else {
        final json = jsonDecode(content);
        if (json is List) {
          // 兼容历史图片 embed 数据格式，避免重新打开后图片被静默吞掉。
          newDoc = Document.fromJson(normalizeDiaryDeltaImageInserts(json));
        } else {
          newDoc = Document();
          newDoc.insert(0, content);
        }
      }
    } catch (_) {
      // 解析失败时，当成纯文本插入
      newDoc = Document();
      newDoc.insert(0, content);
    }
    // 替换控制器并递增版本号，使工具栏重建以重新订阅 changes 流
    final oldController = _quillController;
    oldController.removeListener(_handleEditorDocumentChanged);
    _quillController = QuillController(
      document: newDoc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _quillController.addListener(_handleEditorDocumentChanged);
    oldController.dispose();
    _syncImageStateFromDocument(rebuild: false);
    setState(() => _controllerVersion++);
  }

  void _handleEditorDocumentChanged() {
    _syncImageStateFromDocument();
  }

  void _syncImageStateFromDocument({bool rebuild = true}) {
    final nextImageUrls = _extractImageUrlsFromDocument();
    final nextPendingRemoved = <String>{
      ..._pendingRemovedImageUrls,
      ..._persistedImageUrls.where((url) => !nextImageUrls.contains(url)),
    }..removeWhere(nextImageUrls.contains);

    final imageListChanged =
        !_sameStringLists(_uploadedImageUrls, nextImageUrls);
    final pendingChanged =
        nextPendingRemoved.length != _pendingRemovedImageUrls.length ||
            !nextPendingRemoved.containsAll(_pendingRemovedImageUrls);
    if (!imageListChanged && !pendingChanged) {
      return;
    }

    void applyChanges() {
      _uploadedImageUrls
        ..clear()
        ..addAll(nextImageUrls);
      _pendingRemovedImageUrls
        ..clear()
        ..addAll(nextPendingRemoved);
    }

    if (rebuild && mounted) {
      setState(applyChanges);
      return;
    }
    applyChanges();
  }

  List<String> _extractImageUrlsFromDocument() {
    final imageUrls = <String>[];
    final operations = _quillController.document.toDelta().toJson();
    for (final operation in operations) {
      final insert = operation['insert'];
      if (insert is Map) {
        var imageUrl = resolveDiaryImageSource(insert['image'] ?? insert);
        if (imageUrl != null && imageUrl.isNotEmpty) {
          // 使用已上传的云端 URL（如果存在映射）
          imageUrl = _dataUriToCloudUrl[imageUrl] ?? imageUrl;
          imageUrls.add(imageUrl);
        }
      }
    }
    return imageUrls;
  }

  bool _sameStringLists(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  List<String> _splitImageUrls(String? imageUrls) {
    if (imageUrls == null || imageUrls.trim().isEmpty) {
      return const [];
    }
    return imageUrls
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  /// 获取编辑器中的内容，序列化为 JSON
  ///
  /// 保存前将 data URI 替换为已上传的云端公网 URL
  String _getEditorContent() {
    final delta = _quillController.document.toDelta().toJson();
    // 将 data URI 替换为云端 URL
    if (_dataUriToCloudUrl.isNotEmpty) {
      for (final op in delta) {
        if (op is Map && op['insert'] is Map) {
          final insert = op['insert'] as Map;
          final image = insert['image'];
          if (image is String && _dataUriToCloudUrl.containsKey(image)) {
            insert['image'] = _dataUriToCloudUrl[image];
          }
        }
      }
    }
    // 保存前统一图片 embed 结构，避免未来再出现重开后图片丢失的兼容问题。
    return jsonEncode(normalizeDiaryDeltaImageInserts(delta));
  }

  /// 从 Delta 中提取纯文本预览（判断是否为空）
  String _getPlainTextPreview() {
    return _quillController.document.toPlainText();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final editorState = ref.watch(diaryEditorProvider);
    final theme = Theme.of(context);
    final currentUserId = switch (authState) {
      AuthStateAuthenticated(:final userProfile) => userProfile.id,
      _ => null,
    };

    // 监听编辑器状态，将数据库内容绑定到 Quill 控制器
    ref.listen<DiaryEditorState>(diaryEditorProvider, (prev, next) {
      if (next is DiaryEditorLoaded) {
        // 首次加载或日记 ID 变化时，重新绑定内容
        final needsRebind =
            prev is! DiaryEditorLoaded || _lastBoundEntryId != next.entry.id;

        if (needsRebind) {
          _lastBoundEntryId = next.entry.id;
          final savedImageUrls = _splitImageUrls(next.entry.imageUrls);
          _persistedImageUrls
            ..clear()
            ..addAll(savedImageUrls);
          _pendingRemovedImageUrls.clear();
          _loadContentToEditor(next.entry.content);
          setState(() {
            _selectedMood = next.entry.mood;
            _date = next.entry.date;
            _location = next.entry.location;
            _locationName = next.entry.locationName;
          });
        }
      } else if (next is DiaryEditorSaved) {
        _persistedImageUrls
          ..clear()
          ..addAll(_splitImageUrls(next.entry.imageUrls));
        _pendingRemovedImageUrls.clear();
        // 导航和 SnackBar 由 _saveEntry() 在所有准备工作完成后统一控制，
        // 避免 listener 在 save() 内部同步触发 pop 导致的时序问题。
      } else if (next is DiaryEditorError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: ${next.message}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑日记' : '写日记'),
        actions: [
          // 位置按钮
          IconButton(
            icon: Icon(
              _location != null ? Icons.location_on : Icons.location_off,
              color: _location != null ? theme.colorScheme.primary : null,
            ),
            tooltip: _location != null ? '已记录位置' : '记录位置',
            onPressed: _captureLocation,
          ),
          // 保存按钮
          if (editorState is DiaryEditorSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: '保存',
              onPressed: _saveEntry,
            ),
          // 编辑模式下显示删除按钮
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // 日记元信息区（日期/情绪/位置）
          _buildMetaSection(theme),
          // Quill 工具栏（含图片按钮）
          QuillSimpleToolbar(
            key: ValueKey('toolbar_$_controllerVersion'),
            controller: _quillController,
            config: QuillSimpleToolbarConfig(
              showAlignmentButtons: true,
              showBackgroundColorButton: false,
              showClearFormat: true,
              showCodeBlock: false,
              showColorButton: false,
              showDirection: false,
              showDividers: true,
              showFontFamily: false,
              showFontSize: true,
              showHeaderStyle: true,
              showIndent: false,
              showInlineCode: false,
              showLink: false,
              showListBullets: true,
              showListCheck: true,
              showListNumbers: true,
              showQuote: true,
              showSearchButton: false,
              showSmallButton: false,
              showStrikeThrough: true,
              showSubscript: false,
              showSuperscript: false,
              showUndo: true,
              showRedo: true,
              toolbarIconAlignment: WrapAlignment.start,
              customButtons: [
                QuillToolbarCustomButtonOptions(
                  icon: const Icon(Icons.image_outlined, size: 20),
                  tooltip: '插入图片',
                  onPressed: _pickAndUploadImage,
                ),
              ],
            ),
          ),
          // 已上传图片计数提示
          if (_uploadedImageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Text(
                '${_uploadedImageUrls.length} 张图片，点击图片可调大小、对齐或删除',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          // 富文本编辑区（占满剩余空间）
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: QuillEditor.basic(
                controller: _quillController,
                scrollController: _editorScrollController,
                config: QuillEditorConfig(
                  placeholder: '记录今天的故事...',
                  autoFocus: false,
                  padding: const EdgeInsets.all(8),
                  embedBuilders: [
                    DiaryImageEmbedBuilder(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      maxHeight: 360,
                      onImageTap: _showImageActions,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建元信息区域（日期、情绪、位置）
  Widget _buildMetaSection(ThemeData theme) {
    final locationLabel = _displayLocationLabel(_locationName);

    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期时间行（可点击选择日期）
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${AppDateUtils.formatChineseDate(_date)} ${AppDateUtils.formatWeekday(_date)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppDateUtils.formatTimeWithSeconds(_date),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit_calendar,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 情绪选择器
          MoodSelector(
            selectedMood: _selectedMood,
            onMoodSelected: (mood) => setState(() => _selectedMood = mood),
          ),
          // 位置展示行（有位置时才显示）
          if (locationLabel != null) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  size: 13,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locationLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 点击 X 清除位置
                GestureDetector(
                  onTap: () => setState(() {
                    _location = null;
                    _locationName = null;
                  }),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 选择日记日期
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
      builder: blurPopupBuilder,
    );
    if (picked != null && mounted) {
      setState(() {
        // 保留原来的时间部分，只替换日期
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
          _date.second,
        );
      });
      // 同步到编辑器状态
      ref.read(diaryEditorProvider.notifier).updateDate(_date);
    }
  }

  /// 选取图片、压缩后上传到 Supabase Storage，然后插入到 Quill 中
  ///
  /// 性能优化：
  /// - 在后台线程压缩图片（max 1200px 宽）
  /// - 本地优先：压缩后立即用 data URI 插入编辑器（即时预览）
  /// - 异步上传至云端，完成后自动替换为公网 URL
  Future<void> _pickAndUploadImage() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthStateAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录后再上传图片')),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.first;
    final rawBytes = pickedFile.bytes ??
        (pickedFile.path != null
            ? await File(pickedFile.path!).readAsBytes()
            : null);
    if (rawBytes == null || rawBytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法读取图片文件')),
        );
      }
      return;
    }

    // 压缩图片
    final compressedBytes = await _compressImageForUpload(rawBytes);

    // 立即以 data URI 插入编辑器，用户无需等待上传
    final base64Str = base64Encode(compressedBytes);
    final dataUri = 'data:image/png;base64,$base64Str';

    final baseOffset = _quillController.selection.baseOffset;
    final extentOffset = _quillController.selection.extentOffset;
    final index =
        baseOffset < 0 ? _quillController.document.length - 1 : baseOffset;
    final length =
        baseOffset < 0 || extentOffset < 0 ? 0 : extentOffset - baseOffset;

    _insertImageEmbed(
      dataUri,
      index: index,
      replaceLength: length < 0 ? 0 : length,
    );

    // 异步上传到云端（不阻塞 UI）
    _uploadImageInBackground(
      authState: authState,
      compressedBytes: compressedBytes,
      extension: 'png',
      localDataUri: dataUri,
    );
  }

  /// 后台上传图片到 Supabase Storage，完成后替换编辑器中的 data URI
  Future<void> _uploadImageInBackground({
    required AuthStateAuthenticated authState,
    required Uint8List compressedBytes,
    required String extension,
    required String localDataUri,
  }) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final storagePath = _buildDiaryImageStoragePath(
        authState.userProfile.id,
        extension,
      );

      await supabase.storage.from('diary-images').uploadBinary(
            storagePath,
            compressedBytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: _imageMimeType(extension),
            ),
          );

      final publicUrl =
          supabase.storage.from('diary-images').getPublicUrl(storagePath);

      // 记录映射关系，保存时统一替换（避免在编辑中替换导致图片闪烁）
      _dataUriToCloudUrl[localDataUri] = publicUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '图片上传失败: $e\n图片已在本地显示，保存时将重试上传',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  /// 获取当前地理位置（弹窗请求权限）
  Future<void> _captureLocation() async {
    // 如果已有位置，先询问是否刷新
    if (_location != null) {
      final reset = await showBlurDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('重新获取位置'),
          content: Text('当前位置：$_locationName\n是否重新获取？'),
          actions: [
            TextButton(
              onPressed: () => ctx.pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => ctx.pop(true),
              child: const Text('重新获取'),
            ),
          ],
        ),
      );
      if (reset != true) return;
      await _doCapture();
      return;
    }

    // 检查是否已保存过偏好
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    final pref = prefs.getString(AppConstants.locationPermPrefsKey);

    if (pref == null) {
      // 首次询问：弹窗告知并记住选择
      final allow = await showBlurDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('记录当前位置'),
          content: const Text(
            'DayFlow 将获取您的当前地理位置，用于在日记中展示记录地点。\n\n'
            '您的选择将被记住，之后新建日记时将自动应用此偏好。',
          ),
          actions: [
            TextButton(
              onPressed: () => ctx.pop(false),
              child: const Text('不允许'),
            ),
            FilledButton(
              onPressed: () => ctx.pop(true),
              child: const Text('允许'),
            ),
          ],
        ),
      );

      // 保存用户的选择
      if (allow == true) {
        await prefs.setString(AppConstants.locationPermPrefsKey, 'true');
        await _doCapture();
      } else if (allow == false) {
        await prefs.setString(AppConstants.locationPermPrefsKey, 'false');
      }
    } else if (pref == 'true') {
      await _doCapture();
    } else {
      // 用户之前拒绝过，再次询问
      final allow = await showBlurDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('启用位置记录'),
          content: const Text('您之前选择了不记录位置。\n是否重新启用？'),
          actions: [
            TextButton(
              onPressed: () => ctx.pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => ctx.pop(true),
              child: const Text('启用'),
            ),
          ],
        ),
      );
      if (allow == true) {
        await prefs.setString(AppConstants.locationPermPrefsKey, 'true');
        await _doCapture();
      }
    }
  }

  /// 实际执行位置获取（含反向地理编码）
  Future<void> _doCapture() async {
    try {
      final capturedLocation = await _resolveCurrentLocation();
      final locationStr =
          '${capturedLocation.latitude},${capturedLocation.longitude}';

      // 反向地理编码：通过 HTTP API 将坐标转换为地名
      final locationName = await _reverseGeocode(
        capturedLocation.latitude,
        capturedLocation.longitude,
      );

      if (mounted) {
        setState(() {
          _location = locationStr;
          _locationName =
              locationName ?? capturedLocation.fallbackLabel ?? '当前位置附近';
        });
        if (capturedLocation.isApproximate && !_ipWarningShownThisSession) {
          _ipWarningShownThisSession = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('当前设备使用 IP 粗略定位，结果可能有偏差')),
          );
        } else if (!capturedLocation.isApproximate && locationName == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已获取坐标，但暂未解析出准确地名')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取位置失败: ${_errorMessage(e)}')),
        );
      }
    }
  }

  Future<_CapturedLocationResult> _resolveCurrentLocation() async {
    if (_shouldUseApproximateLocationFallback()) {
      return _resolveApproximateLocationFromIp();
    }

    try {
      return await _resolveCurrentLocationWithGeolocator();
    } on UnimplementedError {
      return _resolveApproximateLocationFromIp();
    } on MissingPluginException {
      return _resolveApproximateLocationFromIp();
    } on UnsupportedError {
      return _resolveApproximateLocationFromIp();
    } on PlatformException catch (error) {
      if (_looksLikeUnsupportedLocationError(error)) {
        return _resolveApproximateLocationFromIp();
      }
      rethrow;
    } on Exception catch (error) {
      if (_looksLikeUnsupportedLocationError(error)) {
        return _resolveApproximateLocationFromIp();
      }
      rethrow;
    } catch (error) {
      if (_looksLikeUnsupportedLocationError(error)) {
        return _resolveApproximateLocationFromIp();
      }
      rethrow;
    }
  }

  Future<_CapturedLocationResult>
      _resolveCurrentLocationWithGeolocator() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('请在系统设置中开启定位服务');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('需要位置权限，请在系统设置中手动开启');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('位置权限被永久拒绝，请在系统设置中开启');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    );

    return _CapturedLocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      isApproximate: false,
    );
  }

  Future<_CapturedLocationResult> _resolveApproximateLocationFromIp() async {
    final primary = await _fetchJson(
      Uri.https('ipwho.is', '/', {'lang': 'zh'}),
      headers: {
        'Accept': 'application/json',
      },
    );
    final primaryResult = _capturedLocationFromIpWhoIs(primary);
    if (primaryResult != null) {
      return primaryResult;
    }

    final fallback = await _fetchJson(
      Uri.https('ipapi.co', '/json/'),
      headers: {
        'Accept': 'application/json',
      },
    );
    final fallbackResult = _capturedLocationFromIpApi(fallback);
    if (fallbackResult != null) {
      return fallbackResult;
    }

    throw Exception('当前设备暂不支持系统定位，且 IP 定位服务不可用');
  }

  _CapturedLocationResult? _capturedLocationFromIpWhoIs(
    Map<String, dynamic>? data,
  ) {
    if (data == null) {
      return null;
    }

    final success = data['success'];
    if (success is bool && !success) {
      return null;
    }

    final latitude =
        _numberValue(data['latitude']) ?? _numberValue(data['lat']);
    final longitude =
        _numberValue(data['longitude']) ?? _numberValue(data['lon']);
    if (latitude == null || longitude == null) {
      return null;
    }

    return _CapturedLocationResult(
      latitude: latitude,
      longitude: longitude,
      fallbackLabel: _joinUniqueParts([
        _stringValue(data['city']),
        _stringValue(data['region']),
        _stringValue(data['country']),
      ]),
      isApproximate: true,
    );
  }

  _CapturedLocationResult? _capturedLocationFromIpApi(
    Map<String, dynamic>? data,
  ) {
    if (data == null) {
      return null;
    }

    final latitude = _numberValue(data['latitude']);
    final longitude = _numberValue(data['longitude']);
    if (latitude == null || longitude == null) {
      return null;
    }

    return _CapturedLocationResult(
      latitude: latitude,
      longitude: longitude,
      fallbackLabel: _joinUniqueParts([
        _stringValue(data['city']),
        _stringValue(data['region']),
        _stringValue(data['country_name']),
      ]),
      isApproximate: true,
    );
  }

  /// 判断是否优先使用 IP 粗略定位
  ///
  /// Web 平台和 Linux 桌面端均不直接支持系统精确定位，
  /// 优先走 IP 定位以避免报错。
  bool _shouldUseApproximateLocationFallback() {
    if (kIsWeb) return true;
    return Platform.isLinux;
  }

  bool _looksLikeUnsupportedLocationError(Object error) {
    final message = error.toString().toLowerCase();
    final platformCode =
        error is PlatformException ? error.code.toLowerCase() : '';
    return platformCode.contains('unsupported') ||
        platformCode.contains('not_implemented') ||
        platformCode.contains('unimplemented') ||
        platformCode.contains('not-supported') ||
        message.contains('missingpluginexception') ||
        message.contains('unimplemented') ||
        message.contains('unsupported') ||
        message.contains('not supported') ||
        message.contains('platform not supported') ||
        message.contains('platformexception(unsupported') ||
        message.contains('not implemented') ||
        message.contains('platform');
  }

  void _insertImageEmbed(
    String imageUrl, {
    required int index,
    required int replaceLength,
  }) {
    var insertAt = index;
    var replaceLen = replaceLength;

    // 确保 block embed 在行首：如果光标不在行首，先插入换行符把文本断开。
    // Quill delta 中 BlockEmbed 必须独占一行，否则保存后重新打开可能丢失图片。
    final plainText = _quillController.document.toPlainText();
    if (insertAt > 0 &&
        insertAt <= plainText.length &&
        plainText[insertAt - 1] != '\n') {
      _quillController
        ..skipRequestKeyboard = true
        ..replaceText(insertAt, replaceLen, '\n', null);
      insertAt += 1;
      replaceLen = 0;
    }

    _quillController
      ..skipRequestKeyboard = true
      ..replaceText(
        insertAt,
        replaceLen,
        BlockEmbed.image(imageUrl),
        null,
      );
    _ensureEmbedTrailingNewline(insertAt + 1);
    _applyImageStyle(
      insertAt,
      width: kDiaryImageDefaultWidth,
      alignment: DiaryImageAlignment.center,
    );
    _quillController.moveCursorToPosition(insertAt + 2);
  }

  void _ensureEmbedTrailingNewline(int index) {
    final plainText = _quillController.document.toPlainText();
    final hasTrailingNewline =
        index < plainText.length && plainText[index] == '\n';
    if (hasTrailingNewline) {
      return;
    }

    _quillController
      ..skipRequestKeyboard = true
      ..replaceText(index, 0, '\n', null);
  }

  /// 通过 OpenStreetMap Nominatim API 进行反向地理编码
  Future<String?> _reverseGeocode(double lat, double lon) async {
    final nominatim = await _reverseGeocodeWithNominatim(lat, lon);
    if (nominatim != null) {
      return nominatim;
    }

    final bigDataCloud = await _reverseGeocodeWithBigDataCloud(lat, lon);
    if (bigDataCloud != null) {
      return bigDataCloud;
    }

    return null;
  }

  Future<String?> _reverseGeocodeWithNominatim(double lat, double lon) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'lat': '$lat',
        'lon': '$lon',
        'format': 'jsonv2',
        'accept-language': 'zh-CN',
        'addressdetails': '1',
        'zoom': '18',
      },
    );

    final data = await _fetchJson(
      uri,
      headers: {
        'User-Agent': 'DayFlow/1.0 (reverse-geocoding)',
        'Accept': 'application/json',
      },
    );
    if (data == null) {
      return null;
    }

    final address = _asStringMap(data['address']);
    if (address != null) {
      final label = _joinUniqueParts([
        _firstNonEmpty(address, ['city', 'town', 'county', 'municipality']),
        _firstNonEmpty(address, ['city_district', 'district', 'suburb']),
        _firstNonEmpty(address, ['road', 'pedestrian', 'residential']),
        _firstNonEmpty(address, ['amenity', 'shop', 'building', 'tourism']),
      ]);
      if (label != null) {
        return label;
      }
    }

    return _displayNameCandidate(data['display_name'] as String?);
  }

  Future<String?> _reverseGeocodeWithBigDataCloud(
    double lat,
    double lon,
  ) async {
    final uri = Uri.https(
      'api.bigdatacloud.net',
      '/data/reverse-geocode-client',
      {
        'latitude': '$lat',
        'longitude': '$lon',
        'localityLanguage': 'zh',
      },
    );

    final data = await _fetchJson(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );
    if (data == null) {
      return null;
    }

    return _joinUniqueParts([
      _stringValue(data['city']),
      _stringValue(data['locality']),
      _stringValue(data['principalSubdivision']),
    ]);
  }

  /// 通用 HTTP GET JSON 请求（使用 package:http，兼容 Web 平台）
  Future<Map<String, dynamic>?> _fetchJson(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.get(uri, headers: headers).timeout(
            const Duration(seconds: 6),
          );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      debugPrint('[反向地理编码失败] $uri -> $e');
    }
    return null;
  }

  Map<String, String>? _asStringMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final result = <String, String>{};
    for (final entry in raw.entries) {
      final value = _stringValue(entry.value);
      if (value != null) {
        result[entry.key.toString()] = value;
      }
    }
    return result;
  }

  String? _firstNonEmpty(Map<String, String> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key]?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _joinUniqueParts(List<String?> values) {
    final parts = <String>[];
    for (final value in values) {
      final part = value?.trim();
      if (part == null || part.isEmpty || _looksLikeCoordinates(part)) {
        continue;
      }
      if (!parts.contains(part)) {
        parts.add(part);
      }
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' ');
  }

  String? _displayNameCandidate(String? rawDisplayName) {
    final displayName = rawDisplayName?.trim();
    if (displayName == null || displayName.isEmpty) {
      return null;
    }
    if (_looksLikeCoordinates(displayName)) {
      return null;
    }

    final parts = displayName
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return _joinUniqueParts(parts.take(4).toList());
  }

  String? _stringValue(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  double? _numberValue(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  String _errorMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  String _normalizeImageExtension(String? extension) {
    final value = (extension ?? 'jpg').trim().toLowerCase();
    return switch (value) {
      'jpeg' => 'jpg',
      'png' => 'png',
      'gif' => 'gif',
      'webp' => 'webp',
      'bmp' => 'bmp',
      _ => 'jpg',
    };
  }

  String _imageMimeType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'bmp' => 'image/bmp',
      _ => 'image/jpeg',
    };
  }

  /// 压缩图片用于上传：限制最大宽度 1200px
  ///
  /// 手机拍摄的照片通常 4000×3000 (12MP)，文件大小可达 5-10MB。
  /// 缩放到 1200px 宽后通常 < 500KB，上传速度提升 10-20 倍。
  Future<Uint8List> _compressImageForUpload(Uint8List rawBytes) async {
    const maxDimension = 1200;
    try {
      final codec = await ui.instantiateImageCodec(rawBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      codec.dispose();
      image.dispose();

      // 已经足够小，直接返回原始字节
      if (width <= maxDimension && height <= maxDimension) {
        return rawBytes;
      }

      // 等比缩放
      final int targetWidth;
      final int targetHeight;
      if (width > height) {
        targetWidth = maxDimension;
        targetHeight = (height * maxDimension / width).round();
      } else {
        targetHeight = maxDimension;
        targetWidth = (width * maxDimension / height).round();
      }

      final resizedCodec = await ui.instantiateImageCodec(
        rawBytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final resizedFrame = await resizedCodec.getNextFrame();
      final resizedImage = resizedFrame.image;
      resizedCodec.dispose();

      final byteData =
          await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      resizedImage.dispose();

      if (byteData == null) return rawBytes;
      return Uint8List.fromList(byteData.buffer.asUint8List());
    } catch (e) {
      debugPrint('[图片压缩] 压缩失败，使用原图: $e');
      return rawBytes;
    }
  }

  Future<void> _showImageActions(
    String imageUrl,
    int documentOffset,
    DiaryImageStyle style,
  ) async {
    final maxWidth = _editableImageMaxWidth();
    final minWidth =
        maxWidth < kDiaryImageMinWidth ? maxWidth : kDiaryImageMinWidth;

    await showBlurDialog<void>(
      context: context,
      builder: (dialogContext) {
        var currentWidth = clampDiaryImageWidth(
          style.width,
          maxWidth: maxWidth,
        );
        var currentAlignment = style.alignment;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void updateStyle({
              double? width,
              DiaryImageAlignment? alignment,
            }) {
              currentWidth = width ?? currentWidth;
              currentAlignment = alignment ?? currentAlignment;
              setDialogState(() {});
              _applyImageStyle(
                documentOffset,
                width: currentWidth,
                alignment: currentAlignment,
              );
            }

            // 根据可用宽度计算尺寸预设值
            final presets = <(String, double)>[
              ('25%', maxWidth * 0.25),
              ('50%', maxWidth * 0.50),
              ('75%', maxWidth * 0.75),
              ('全宽', maxWidth),
            ];

            return AlertDialog(
              title: const Text('调整图片'),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 快捷尺寸按钮行 ──
                    Text(
                      '快捷尺寸',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: presets.map((preset) {
                        final (label, width) = preset;
                        final clampedWidth =
                            clampDiaryImageWidth(width, maxWidth: maxWidth);
                        final isActive =
                            (currentWidth - clampedWidth).abs() < 2;
                        return ChoiceChip(
                          label: Text(label),
                          selected: isActive,
                          onSelected: (_) =>
                              updateStyle(width: clampedWidth),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // ── 精确宽度滑块 ──
                    Text(
                      '精确宽度 ${currentWidth.round()} px',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Slider(
                      min: minWidth,
                      max: maxWidth,
                      value: currentWidth.clamp(minWidth, maxWidth),
                      onChanged: (value) => updateStyle(width: value),
                    ),
                    const SizedBox(height: 8),
                    // ── 对齐方式 / 排列方式 ──
                    Text(
                      '排列方式',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<DiaryImageAlignment>(
                      segments: const [
                        ButtonSegment(
                          value: DiaryImageAlignment.left,
                          icon: Icon(Icons.format_align_left, size: 18),
                          label: Text('左对齐'),
                        ),
                        ButtonSegment(
                          value: DiaryImageAlignment.center,
                          icon: Icon(Icons.format_align_center, size: 18),
                          label: Text('居中'),
                        ),
                        ButtonSegment(
                          value: DiaryImageAlignment.right,
                          icon: Icon(Icons.format_align_right, size: 18),
                          label: Text('右对齐'),
                        ),
                      ],
                      selected: {currentAlignment},
                      showSelectedIcon: false,
                      onSelectionChanged: (selected) {
                        if (selected.isNotEmpty) {
                          updateStyle(alignment: selected.first);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '提示：左/右对齐配合较小尺寸，可模拟文字环绕效果。\n'
                      '删除已保存的图片后，云端文件会在保存日记时一起清理。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('关闭'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _removeImageEmbed(documentOffset, imageUrl);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('删除图片'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _applyImageStyle(
    int documentOffset, {
    required double width,
    required DiaryImageAlignment alignment,
  }) {
    final styleString = buildDiaryImageStyleString(
      width: clampDiaryImageWidth(width, maxWidth: _editableImageMaxWidth()),
      alignment: alignment,
    );
    _quillController
      ..skipRequestKeyboard = true
      ..formatText(documentOffset, 1, StyleAttribute(styleString));
  }

  Future<void> _removeImageEmbed(int documentOffset, String imageUrl) async {
    _quillController
      ..skipRequestKeyboard = true
      ..replaceText(
        documentOffset,
        1,
        '',
        TextSelection.collapsed(offset: documentOffset),
      );

    if (_persistedImageUrls.contains(imageUrl)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图片已移除，保存日记后会同步清理云端文件')),
        );
      }
      return;
    }

    unawaited(
      ref.read(diaryRepositoryProvider).deleteStorageImagesByUrls([imageUrl]),
    );
  }

  double _editableImageMaxWidth() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final candidate = screenWidth - 120;
    if (candidate < 180) {
      return 180;
    }
    if (candidate > 720) {
      return 720;
    }
    return candidate;
  }

  String? _displayLocationLabel(String? rawLabel) {
    final label = rawLabel?.trim();
    if (label == null || label.isEmpty) {
      return null;
    }
    if (_looksLikeCoordinates(label)) {
      return '当前位置附近';
    }
    return label;
  }

  bool _looksLikeCoordinates(String value) {
    return RegExp(r'^-?\d+(?:\.\d+)?\s*,\s*-?\d+(?:\.\d+)?$').hasMatch(value);
  }

  /// 保存日记
  Future<void> _saveEntry() async {
    final authState = ref.read(authProvider);
    if (!_isEditing && authState is! AuthStateAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前登录状态无效，请重新登录后重试')),
      );
      return;
    }

    final content = _getEditorContent();
    final currentImageUrls = extractDiaryImageSourcesFromContent(content);
    final plainText = _getPlainTextPreview().trim();

    if (plainText.isEmpty && currentImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入日记内容或至少插入一张图片')),
      );
      return;
    }

    final remoteImageUrls = currentImageUrls
        .where((url) => !isDiaryImageDataUri(url))
        .toList(growable: false);
    final pendingDataUris = currentImageUrls
        .where(isDiaryImageDataUri)
        .toSet()
        .toList(growable: false);

    final removedImageUrls = <String>{
      ..._pendingRemovedImageUrls,
      ..._persistedImageUrls.where((url) => !remoteImageUrls.contains(url)),
    };

    final savedEntry = await ref.read(diaryEditorProvider.notifier).save(
          content,
          _selectedMood,
          location: _location,
          locationName: _locationName,
          imageUrls:
              remoteImageUrls.isNotEmpty ? remoteImageUrls.join(',') : null,
          removedImageUrls: removedImageUrls.toList(growable: false),
        );

    if (savedEntry == null || authState is! AuthStateAuthenticated) {
      return;
    }

    // ── 在 pop 之前捕获所有引用 ──
    // pop 之后 widget 将被 dispose，ref 不再可用。
    // 必须在此处一次性获取所有后续操作需要的依赖。
    final userId = (authState as AuthStateAuthenticated).userProfile.id;
    final repository = ref.read(diaryRepositoryProvider);
    final supabase = ref.read(supabaseClientProvider);

    // 启动后台图片上传任务（在 pop 前捕获所有引用）
    if (pendingDataUris.isNotEmpty) {
      unawaited(
        _finalizePendingImagesAfterSave(
          repository: repository,
          supabase: supabase,
          savedEntry: savedEntry,
          userId: userId,
          initialContent: content,
          pendingDataUris: pendingDataUris,
        ),
      );
    }

    // ── 所有后台任务已启动，现在安全地导航离开 ──
    if (!mounted) return;
    ref.invalidate(diaryListProvider(userId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('日记已保存')),
    );
    context.pop();
  }

  /// 保存成功后在后台继续上传未完成的本地图片，并将日记内容回写为云端 URL。
  ///
  /// 所有外部依赖（repository、supabase）必须由调用方在 pop 前捕获并传入，
  /// 因为此方法在 widget dispose 后仍在执行，不能访问 ref。
  Future<void> _finalizePendingImagesAfterSave({
    required DiaryRepository repository,
    required SupabaseClient supabase,
    required DiaryEntry savedEntry,
    required String userId,
    required String initialContent,
    required List<String> pendingDataUris,
  }) async {
    final uploadedMappings = await _uploadDataUrisToCloud(
      userId: userId,
      dataUris: pendingDataUris,
      supabase: supabase,
    );
    if (uploadedMappings.isEmpty) {
      return;
    }

    _dataUriToCloudUrl.addAll(uploadedMappings);
    final latestEntry = savedEntry.id != null
        ? await repository.getEntryById(savedEntry.id!)
        : null;
    final baseEntry = latestEntry ?? savedEntry;
    final updatedContent = _replaceImageUrlsInContent(
      latestEntry?.content ?? initialContent,
      uploadedMappings,
    );
    final updatedRemoteImageUrls = extractDiaryImageSourcesFromContent(
      updatedContent,
    ).where((url) => !isDiaryImageDataUri(url)).toList(growable: false);

    try {
      await repository.updateEntry(
        baseEntry.copyWith(
          content: updatedContent,
          imageUrls: updatedRemoteImageUrls.isNotEmpty
              ? updatedRemoteImageUrls.join(',')
              : null,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (error) {
      debugPrint('[图片上传] 后台回写图片 URL 失败: $error');
    }
  }

  Future<Map<String, String>> _uploadDataUrisToCloud({
    required String userId,
    required List<String> dataUris,
    required SupabaseClient supabase,
  }) async {
    final uploadedMappings = <String, String>{};

    // 顺序上传更稳定，避免多图并发时出现路径冲突或瞬时失败。
    for (final dataUri in dataUris) {
      try {
        final separator = dataUri.indexOf(',');
        if (separator < 0) {
          continue;
        }

        final bytes = base64Decode(dataUri.substring(separator + 1));
        final storagePath = _buildDiaryImageStoragePath(userId, 'png');
        await supabase.storage.from('diary-images').uploadBinary(
              storagePath,
              Uint8List.fromList(bytes),
              fileOptions: const FileOptions(
                upsert: false,
                contentType: 'image/png',
              ),
            );
        final publicUrl =
            supabase.storage.from('diary-images').getPublicUrl(storagePath);
        uploadedMappings[dataUri] = publicUrl;
      } catch (error) {
        debugPrint('[图片上传] 后台上传单张图片失败: $error');
      }
    }

    return uploadedMappings;
  }

  String _replaceImageUrlsInContent(
    String content,
    Map<String, String> replacements,
  ) {
    if (content.trim().isEmpty || replacements.isEmpty) {
      return content;
    }

    try {
      final decoded = jsonDecode(content);
      if (decoded is! List) {
        return content;
      }

      for (final operation in decoded) {
        if (operation is! Map || operation['insert'] is! Map) {
          continue;
        }

        final insert = operation['insert'] as Map;
        final image = insert['image'];
        if (image is String && replacements.containsKey(image)) {
          insert['image'] = replacements[image];
        }
      }

      return jsonEncode(normalizeDiaryDeltaImageInserts(decoded));
    } catch (_) {
      return content;
    }
  }

  String _buildDiaryImageStoragePath(String userId, String extension) {
    return '$userId/${_uuid.v4()}.$extension';
  }

  /// 确认删除对话框
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showBlurDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这篇日记吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || widget.diaryId == null || !context.mounted) {
      return;
    }

    final deleted = await ref.read(diaryEditorProvider.notifier).delete();
    if (!context.mounted || !deleted) {
      return;
    }

    final authState = ref.read(authProvider);
    if (authState is AuthStateAuthenticated) {
      ref.invalidate(diaryListProvider(authState.userProfile.id));
    }
    context.pop();
  }
}

class _CapturedLocationResult {
  const _CapturedLocationResult({
    required this.latitude,
    required this.longitude,
    required this.isApproximate,
    this.fallbackLabel,
  });

  final double latitude;
  final double longitude;
  final bool isApproximate;
  final String? fallbackLabel;
}
