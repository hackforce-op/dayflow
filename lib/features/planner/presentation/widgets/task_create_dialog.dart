/// DayFlow - 新建任务对话框
///
/// 用于快速创建新任务的弹窗表单。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dayflow/features/auth/providers/auth_provider.dart';
import 'package:dayflow/features/planner/domain/task_item.dart';
import 'package:dayflow/features/planner/data/task_repository.dart';
import 'package:dayflow/shared/widgets/blur_dialog.dart';
import 'package:dayflow/shared/widgets/custom_date_picker.dart';

enum PlannerPreset {
  study,
  birthday,
  anniversary,
  countdown,
}

extension PlannerPresetLabel on PlannerPreset {
  String get label {
    return switch (this) {
      PlannerPreset.study => '学习计划',
      PlannerPreset.birthday => '生日提醒',
      PlannerPreset.anniversary => '纪念日',
      PlannerPreset.countdown => '倒数日',
    };
  }

  IconData get icon {
    return switch (this) {
      PlannerPreset.study => Icons.menu_book_rounded,
      PlannerPreset.birthday => Icons.cake_rounded,
      PlannerPreset.anniversary => Icons.favorite_rounded,
      PlannerPreset.countdown => Icons.hourglass_bottom_rounded,
    };
  }
}

enum CycleUnit {
  second,
  minute,
  hour,
  day,
  week,
  month,
  year,
}

extension CycleUnitLabel on CycleUnit {
  String get label {
    return switch (this) {
      CycleUnit.second => '秒',
      CycleUnit.minute => '分钟',
      CycleUnit.hour => '小时',
      CycleUnit.day => '天',
      CycleUnit.week => '周',
      CycleUnit.month => '月',
      CycleUnit.year => '年',
    };
  }
}

enum StudyScheduleType {
  deadline,
  interval,
}

enum ReminderMode {
  none,
  yearly,
  custom,
}

enum AnniversaryRepeatType {
  none,
  weekly,
  monthly,
  yearly,
  custom,
}

class _TaskDraft {
  final DateTime? dueDate;
  final String metadata;

  const _TaskDraft({
    required this.dueDate,
    required this.metadata,
  });
}

/// 新建任务对话框
class TaskCreateDialog extends ConsumerStatefulWidget {
  const TaskCreateDialog({super.key});

  @override
  ConsumerState<TaskCreateDialog> createState() => _TaskCreateDialogState();
}

class _TaskCreateDialogState extends ConsumerState<TaskCreateDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;

  PlannerPreset? _selectedPreset = PlannerPreset.study;
  PlannerPreset? _lastPreset = PlannerPreset.study;
  bool _customMode = false;

  DateTime? _customDueDate = DateTime.now();
  int _customReminderCount = 1;
  int _customRepeatEvery = 1;
  CycleUnit _customRepeatUnit = CycleUnit.day;
  bool _customAllDay = false;

  StudyScheduleType _studyScheduleType = StudyScheduleType.deadline;
  DateTime _studyDeadline = DateTime.now().add(const Duration(days: 1));
  int _studyReminderCount = 2;
  int _studyIntervalEvery = 1;
  CycleUnit _studyIntervalUnit = CycleUnit.day;

  DateTime _birthdayDate = DateTime.now();
  bool _birthdayAllDay = true;
  String _birthdayCalendar = '阳历';
  ReminderMode _birthdayReminderMode = ReminderMode.yearly;
  final Set<int> _birthdayReminderDays = <int>{1, 7};

  DateTime _anniversaryDate = DateTime.now();
  bool _anniversaryAllDay = true;
  AnniversaryRepeatType _anniversaryRepeatType = AnniversaryRepeatType.yearly;
  int _anniversaryCustomEvery = 1;
  CycleUnit _anniversaryCustomUnit = CycleUnit.month;
  ReminderMode _anniversaryReminderMode = ReminderMode.yearly;
  final Set<int> _anniversaryReminderDays = <int>{1, 7};

  DateTime _countdownDateTime =
      DateTime.now().add(const Duration(days: 1, hours: 2));
  bool _countdownAutoDelete = false;
  int _countdownReminderCount = 1;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 920;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isWide ? 960 : 680,
          maxHeight: size.height * 0.86,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(
              child: isWide
                  ? Row(
                      children: [
                        SizedBox(
                          width: 250,
                          child: _buildPresetRail(context),
                        ),
                        VerticalDivider(
                          width: 1,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        Expanded(
                          child: _buildForm(context),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildPresetChips(context),
                        const Divider(height: 1),
                        Expanded(child: _buildForm(context)),
                      ],
                    ),
            ),
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _createTask,
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('创建规划'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '新建规划',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _activateCustomMode,
              onLongPress: _restorePreset,
              icon: Icon(_customMode ? Icons.edit_note : Icons.tune),
              label: Text(_customMode ? '自定义中' : '自定义'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetRail(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '规划预设',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: PlannerPreset.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final preset = PlannerPreset.values[index];
                final selected = !_customMode && _selectedPreset == preset;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _selectPreset(preset),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: selected
                          ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withAlpha(190)
                          : Theme.of(context).colorScheme.surfaceContainerLow,
                    ),
                    child: Row(
                      children: [
                        Icon(preset.icon),
                        const SizedBox(width: 10),
                        Expanded(child: Text(preset.label)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _customMode ? '长按右上角“自定义”可恢复上一次预设。' : '点击预设后自动填充常用规则。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChips(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        scrollDirection: Axis.horizontal,
        children: [
          for (final preset in PlannerPreset.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(preset.icon, size: 18),
                label: Text(preset.label),
                selected: !_customMode && _selectedPreset == preset,
                onSelected: (_) => _selectPreset(preset),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '规划标题',
              hintText: '例如：高数复习冲刺',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: '详细说明',
              hintText: '补充计划背景、提醒对象或执行细节',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Text('优先级', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('高'),
                selected: _priority == TaskPriority.high,
                onSelected: (_) =>
                    setState(() => _priority = TaskPriority.high),
              ),
              ChoiceChip(
                label: const Text('中'),
                selected: _priority == TaskPriority.medium,
                onSelected: (_) =>
                    setState(() => _priority = TaskPriority.medium),
              ),
              ChoiceChip(
                label: const Text('低'),
                selected: _priority == TaskPriority.low,
                onSelected: (_) => setState(() => _priority = TaskPriority.low),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_customMode || _selectedPreset == null)
            _buildCustomModeSection(context)
          else
            _buildPresetSection(context, _selectedPreset!),
        ],
      ),
    );
  }

  Widget _buildPresetSection(BuildContext context, PlannerPreset preset) {
    return switch (preset) {
      PlannerPreset.study => _buildStudyPreset(context),
      PlannerPreset.birthday => _buildBirthdayPreset(context),
      PlannerPreset.anniversary => _buildAnniversaryPreset(context),
      PlannerPreset.countdown => _buildCountdownPreset(context),
    };
  }

  Widget _buildCustomModeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('自定义规划', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _DateLine(
          label: _customDueDate == null
              ? '选择时间'
              : '执行时间：${_formatDateTime(_customDueDate!, includeTime: !_customAllDay)}',
          icon: Icons.schedule,
          onTap: () async {
            final initial = _customDueDate ?? DateTime.now();
            final picked = await _pickDateTime(context, initial,
                includeTime: !_customAllDay);
            if (picked == null) {
              return;
            }
            setState(() {
              _customDueDate = picked;
            });
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _customAllDay,
          title: const Text('全天事件'),
          subtitle: const Text('开启后忽略时分秒，仅按日期提醒'),
          onChanged: (value) {
            setState(() {
              _customAllDay = value;
            });
          },
        ),
        _buildStepper(
          context,
          label: '提醒次数',
          value: _customReminderCount,
          min: 0,
          max: 10,
          onChanged: (value) => setState(() => _customReminderCount = value),
        ),
        const SizedBox(height: 8),
        _buildStepper(
          context,
          label: '循环间隔',
          value: _customRepeatEvery,
          min: 1,
          max: 100,
          onChanged: (value) => setState(() => _customRepeatEvery = value),
        ),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<CycleUnit>(
                value: _customRepeatUnit,
                decoration: const InputDecoration(labelText: '单位'),
                items: CycleUnit.values
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _customRepeatUnit = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStudyPreset(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('学习计划', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<StudyScheduleType>(
          segments: const [
            ButtonSegment(
              value: StudyScheduleType.deadline,
              label: Text('截止时间'),
            ),
            ButtonSegment(
              value: StudyScheduleType.interval,
              label: Text('按周期'),
            ),
          ],
          selected: <StudyScheduleType>{_studyScheduleType},
          onSelectionChanged: (selection) {
            setState(() {
              _studyScheduleType = selection.first;
            });
          },
        ),
        const SizedBox(height: 10),
        if (_studyScheduleType == StudyScheduleType.deadline) ...[
          _DateLine(
            label: '截止：${_formatDateTime(_studyDeadline, includeTime: true)}',
            icon: Icons.event_available,
            onTap: () async {
              final picked = await _pickDateTime(
                context,
                _studyDeadline,
                includeTime: true,
              );
              if (picked == null) {
                return;
              }
              setState(() {
                _studyDeadline = picked;
              });
            },
          ),
          _buildStepper(
            context,
            label: '提醒次数',
            value: _studyReminderCount,
            min: 0,
            max: 10,
            onChanged: (value) => setState(() => _studyReminderCount = value),
          ),
        ] else ...[
          _buildStepper(
            context,
            label: '每隔',
            value: _studyIntervalEvery,
            min: 1,
            max: 100,
            onChanged: (value) => setState(() => _studyIntervalEvery = value),
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<CycleUnit>(
                  value: _studyIntervalUnit,
                  decoration: const InputDecoration(labelText: '单位'),
                  items: const [
                    CycleUnit.second,
                    CycleUnit.minute,
                    CycleUnit.hour,
                    CycleUnit.day,
                    CycleUnit.month,
                    CycleUnit.year,
                  ]
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _studyIntervalUnit = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '示例：每 $_studyIntervalEvery${_studyIntervalUnit.label} 推进一次学习步骤',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildBirthdayPreset(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('生日提醒', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _birthdayCalendar,
          decoration: const InputDecoration(labelText: '历法类型'),
          items: const [
            DropdownMenuItem(value: '阳历', child: Text('阳历')),
            DropdownMenuItem(value: '阴历', child: Text('阴历')),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _birthdayCalendar = value;
            });
          },
        ),
        const SizedBox(height: 8),
        _DateLine(
          label: '生日日期：${_formatDateTime(_birthdayDate, includeTime: false)}',
          icon: Icons.cake,
          onTap: () async {
            final picked = await _pickDate(context, _birthdayDate);
            if (picked == null) {
              return;
            }
            setState(() {
              _birthdayDate = picked;
            });
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _birthdayAllDay,
          title: const Text('全天提醒'),
          onChanged: (value) {
            setState(() {
              _birthdayAllDay = value;
            });
          },
        ),
        const SizedBox(height: 6),
        _buildReminderModeSelector(
          context,
          mode: _birthdayReminderMode,
          onChanged: (value) {
            setState(() {
              _birthdayReminderMode = value;
            });
          },
        ),
        if (_birthdayReminderMode == ReminderMode.custom)
          _buildReminderDaysEditor(
            context,
            selected: _birthdayReminderDays,
          ),
      ],
    );
  }

  Widget _buildAnniversaryPreset(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('纪念日', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _DateLine(
          label:
              '纪念日期：${_formatDateTime(_anniversaryDate, includeTime: false)}',
          icon: Icons.event,
          onTap: () async {
            final picked = await _pickDate(context, _anniversaryDate);
            if (picked == null) {
              return;
            }
            setState(() {
              _anniversaryDate = picked;
            });
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _anniversaryAllDay,
          title: const Text('全天事件'),
          onChanged: (value) {
            setState(() {
              _anniversaryAllDay = value;
            });
          },
        ),
        DropdownButtonFormField<AnniversaryRepeatType>(
          value: _anniversaryRepeatType,
          decoration: const InputDecoration(labelText: '循环规则'),
          items: const [
            DropdownMenuItem(
                value: AnniversaryRepeatType.none, child: Text('不重复')),
            DropdownMenuItem(
                value: AnniversaryRepeatType.weekly, child: Text('每周')),
            DropdownMenuItem(
                value: AnniversaryRepeatType.monthly, child: Text('每月')),
            DropdownMenuItem(
                value: AnniversaryRepeatType.yearly, child: Text('每年')),
            DropdownMenuItem(
                value: AnniversaryRepeatType.custom, child: Text('自定义间隔')),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _anniversaryRepeatType = value;
            });
          },
        ),
        if (_anniversaryRepeatType == AnniversaryRepeatType.custom) ...[
          const SizedBox(height: 8),
          _buildStepper(
            context,
            label: '每隔',
            value: _anniversaryCustomEvery,
            min: 1,
            max: 100,
            onChanged: (value) =>
                setState(() => _anniversaryCustomEvery = value),
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<CycleUnit>(
                  value: _anniversaryCustomUnit,
                  decoration: const InputDecoration(labelText: '单位'),
                  items: const [
                    CycleUnit.day,
                    CycleUnit.week,
                    CycleUnit.month,
                    CycleUnit.year,
                  ]
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _anniversaryCustomUnit = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        _buildReminderModeSelector(
          context,
          mode: _anniversaryReminderMode,
          onChanged: (value) {
            setState(() {
              _anniversaryReminderMode = value;
            });
          },
        ),
        if (_anniversaryReminderMode == ReminderMode.custom)
          _buildReminderDaysEditor(
            context,
            selected: _anniversaryReminderDays,
          ),
      ],
    );
  }

  Widget _buildCountdownPreset(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('倒数日', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _DateLine(
          label:
              '目标时间：${_formatDateTime(_countdownDateTime, includeTime: true)}',
          icon: Icons.timer,
          onTap: () async {
            final picked = await _pickDateTime(
              context,
              _countdownDateTime,
              includeTime: true,
            );
            if (picked == null) {
              return;
            }
            setState(() {
              _countdownDateTime = picked;
            });
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _countdownAutoDelete,
          title: const Text('完成后自动删除'),
          subtitle: const Text('到时并标记完成后可自动清理记录'),
          onChanged: (value) {
            setState(() {
              _countdownAutoDelete = value;
            });
          },
        ),
        _buildStepper(
          context,
          label: '提醒次数',
          value: _countdownReminderCount,
          min: 0,
          max: 10,
          onChanged: (value) {
            setState(() {
              _countdownReminderCount = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildReminderModeSelector(
    BuildContext context, {
    required ReminderMode mode,
    required ValueChanged<ReminderMode> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('不提醒'),
          selected: mode == ReminderMode.none,
          onSelected: (_) => onChanged(ReminderMode.none),
        ),
        ChoiceChip(
          label: const Text('每年提醒'),
          selected: mode == ReminderMode.yearly,
          onSelected: (_) => onChanged(ReminderMode.yearly),
        ),
        ChoiceChip(
          label: const Text('自定义提醒'),
          selected: mode == ReminderMode.custom,
          onSelected: (_) => onChanged(ReminderMode.custom),
        ),
      ],
    );
  }

  Widget _buildReminderDaysEditor(
    BuildContext context, {
    required Set<int> selected,
  }) {
    const options = <int>[0, 1, 3, 7, 14, 30];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (days) => FilterChip(
              label: Text(days == 0 ? '当天' : '提前$days天'),
              selected: selected.contains(days),
              onSelected: (enabled) {
                setState(() {
                  if (enabled) {
                    selected.add(days);
                  } else {
                    selected.remove(days);
                  }
                });
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildStepper(
    BuildContext context, {
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Text('$label：', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: 8),
        IconButton(
          onPressed: value <= min ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value'),
        IconButton(
          onPressed: value >= max ? null : () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  void _activateCustomMode() {
    setState(() {
      if (_selectedPreset != null) {
        _lastPreset = _selectedPreset;
      }
      _customMode = true;
      _selectedPreset = null;
    });
  }

  void _restorePreset() {
    if (_lastPreset == null) {
      return;
    }
    setState(() {
      _customMode = false;
      _selectedPreset = _lastPreset;
    });
  }

  void _selectPreset(PlannerPreset preset) {
    setState(() {
      _customMode = false;
      _selectedPreset = preset;
      _lastPreset = preset;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = preset.label;
      }
    });
  }

  Future<DateTime?> _pickDate(
    BuildContext context,
    DateTime initial,
  ) async {
    return showCustomDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2300),
    );
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime initial, {
    required bool includeTime,
  }) async {
    final date = await showCustomDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2300),
    );
    if (date == null) {
      return null;
    }
    if (!includeTime) {
      return DateTime(date.year, date.month, date.day);
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: blurPopupBuilder,
    );

    if (time == null) {
      return DateTime(date.year, date.month, date.day, initial.hour,
          initial.minute, initial.second);
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  String _formatDateTime(DateTime dateTime, {required bool includeTime}) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');

    if (!includeTime) {
      return '$y-$m-$d';
    }

    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  DateTime _addCycle(DateTime base, int every, CycleUnit unit) {
    return switch (unit) {
      CycleUnit.second => base.add(Duration(seconds: every)),
      CycleUnit.minute => base.add(Duration(minutes: every)),
      CycleUnit.hour => base.add(Duration(hours: every)),
      CycleUnit.day => base.add(Duration(days: every)),
      CycleUnit.week => base.add(Duration(days: 7 * every)),
      CycleUnit.month => DateTime(
          base.year, base.month + every, base.day, base.hour, base.minute),
      CycleUnit.year => DateTime(
          base.year + every, base.month, base.day, base.hour, base.minute),
    };
  }

  DateTime _nextBirthdayDate(DateTime birthday, {required bool allDay}) {
    final now = DateTime.now();
    final candidate = DateTime(
      now.year,
      birthday.month,
      birthday.day,
      allDay ? 8 : birthday.hour,
      allDay ? 0 : birthday.minute,
    );

    if (candidate.isAfter(now)) {
      return candidate;
    }

    return DateTime(
      now.year + 1,
      birthday.month,
      birthday.day,
      allDay ? 8 : birthday.hour,
      allDay ? 0 : birthday.minute,
    );
  }

  DateTime _normalizeDueDate(DateTime dateTime, bool allDay) {
    if (!allDay) {
      return dateTime;
    }
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 8);
  }

  _TaskDraft _buildTaskDraft() {
    if (_customMode || _selectedPreset == null) {
      final dueDate = _customDueDate == null
          ? null
          : _normalizeDueDate(_customDueDate!, _customAllDay);

      return _TaskDraft(
        dueDate: dueDate,
        metadata:
            '[自定义规划]\n提醒次数: $_customReminderCount\n循环: 每$_customRepeatEvery${_customRepeatUnit.label}',
      );
    }

    switch (_selectedPreset!) {
      case PlannerPreset.study:
        if (_studyScheduleType == StudyScheduleType.deadline) {
          return _TaskDraft(
            dueDate: _studyDeadline,
            metadata:
                '[学习计划]\n模式: 截止时间\n截止: ${_formatDateTime(_studyDeadline, includeTime: true)}\n提醒次数: $_studyReminderCount',
          );
        }

        final dueDate =
            _addCycle(DateTime.now(), _studyIntervalEvery, _studyIntervalUnit);
        return _TaskDraft(
          dueDate: dueDate,
          metadata:
              '[学习计划]\n模式: 间隔推进\n间隔: 每$_studyIntervalEvery${_studyIntervalUnit.label}\n预计下次: ${_formatDateTime(dueDate, includeTime: true)}',
        );
      case PlannerPreset.birthday:
        final dueDate =
            _nextBirthdayDate(_birthdayDate, allDay: _birthdayAllDay);
        final reminder = switch (_birthdayReminderMode) {
          ReminderMode.none => '不提醒',
          ReminderMode.yearly => '每年提醒',
          ReminderMode.custom => _birthdayReminderDays.isEmpty
              ? '自定义提醒(空)'
              : '自定义提醒: ${_birthdayReminderDays.toList()..sort()}',
        };

        return _TaskDraft(
          dueDate: dueDate,
          metadata:
              '[生日提醒]\n历法: $_birthdayCalendar\n全天: ${_birthdayAllDay ? '是' : '否'}\n提醒: $reminder',
        );
      case PlannerPreset.anniversary:
        final dueDate = _normalizeDueDate(_anniversaryDate, _anniversaryAllDay);
        final repeatLabel = switch (_anniversaryRepeatType) {
          AnniversaryRepeatType.none => '不重复',
          AnniversaryRepeatType.weekly => '每周',
          AnniversaryRepeatType.monthly => '每月',
          AnniversaryRepeatType.yearly => '每年',
          AnniversaryRepeatType.custom =>
            '每$_anniversaryCustomEvery${_anniversaryCustomUnit.label}',
        };
        final reminder = switch (_anniversaryReminderMode) {
          ReminderMode.none => '不提醒',
          ReminderMode.yearly => '每年提醒',
          ReminderMode.custom => _anniversaryReminderDays.isEmpty
              ? '自定义提醒(空)'
              : '自定义提醒: ${_anniversaryReminderDays.toList()..sort()}',
        };
        return _TaskDraft(
          dueDate: dueDate,
          metadata:
              '[纪念日]\n循环: $repeatLabel\n全天: ${_anniversaryAllDay ? '是' : '否'}\n提醒: $reminder',
        );
      case PlannerPreset.countdown:
        return _TaskDraft(
          dueDate: _countdownDateTime,
          metadata:
              '[倒数日]\n目标: ${_formatDateTime(_countdownDateTime, includeTime: true)}\n提醒次数: $_countdownReminderCount\n到期自动删除: ${_countdownAutoDelete ? '是' : '否'}',
        );
    }
  }

  /// 创建任务
  Future<void> _createTask() async {
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : (_selectedPreset?.label ?? '新规划');

    if (title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入规划标题')),
      );
      return;
    }

    final authState = ref.read(authProvider);
    if (authState is! AuthStateAuthenticated) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录后再创建任务')),
      );
      return;
    }

    final draft = _buildTaskDraft();
    final detail = _descController.text.trim();
    final mergedDescription = [
      if (detail.isNotEmpty) detail,
      draft.metadata,
    ].join('\n\n');

    final task = TaskItem(
      title: title,
      description:
          mergedDescription.trim().isNotEmpty ? mergedDescription.trim() : null,
      priority: _priority,
      status: TaskStatus.todo,
      dueDate: draft.dueDate,
      sortOrder: 0,
      createdAt: DateTime.now(),
      userId: authState.userProfile.id,
    );

    await ref.read(taskRepositoryProvider).createTask(task);

    if (!mounted) {
      return;
    }

    Navigator.pop(context, true);
  }
}

class _DateLine extends StatelessWidget {
  const _DateLine({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Icon(icon),
      onTap: onTap,
    );
  }
}
