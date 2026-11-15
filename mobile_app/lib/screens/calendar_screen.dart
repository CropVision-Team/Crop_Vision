import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../theme/app_theme.dart';
import '../data/crop_growth_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _trackedCrops = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _loadTrackedCrops();
  }

  Future<void> _loadReminders() async {
    try {
      final service = context.read<SupabaseService>();
      final data = await service.fetchReminders().timeout(
            const Duration(seconds: 4),
            onTimeout: () => [],
          );
      if (!mounted) return;
      setState(() {
        _reminders = data.isNotEmpty ? data : _sampleReminders();
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _reminders = _sampleReminders();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadTrackedCrops() async {
    try {
      final service = context.read<SupabaseService>();
      final data = await service.fetchTrackedCrops().timeout(
            const Duration(seconds: 4),
            onTimeout: () => [],
          );
      if (!mounted) return;
      setState(() {
        _trackedCrops = data.isNotEmpty ? data : _sampleTrackedCrops();
      });
    } catch (_) {
      if (mounted) {
        setState(() => _trackedCrops = _sampleTrackedCrops());
      }
    }
  }

  List<Map<String, dynamic>> _sampleReminders() {
    final now = DateTime.now();
    return [
      {
        'id': 'rem-1',
        'title': 'Tomato: Copper Hydroxide Foliar Spray',
        'description': 'Target G2 Early Blight spots before rain',
        'reminder_date': now.toIso8601String(),
        'is_recurring': false,
      },
      {
        'id': 'rem-2',
        'title': 'Potato: Furrow Irrigation & Moisture Check',
        'description': 'Maintain 65-75% field capacity during tuber initiation',
        'reminder_date': now.add(const Duration(days: 2)).toIso8601String(),
        'is_recurring': true,
      },
      {
        'id': 'rem-3',
        'title': 'Corn: Leaf Health Scout & Borer Inspection',
        'description': 'Inspect whorl leaves for fall armyworm or rust pustules',
        'reminder_date': now.add(const Duration(days: 4)).toIso8601String(),
        'is_recurring': false,
      },
    ];
  }

  List<Map<String, dynamic>> _sampleTrackedCrops() {
    final now = DateTime.now();
    return [
      {
        'id': 'crop-1',
        'crop_name': 'Tomato',
        'planting_date': now.subtract(const Duration(days: 42)).toIso8601String().split('T')[0],
      },
      {
        'id': 'crop-2',
        'crop_name': 'Potato',
        'planting_date': now.subtract(const Duration(days: 28)).toIso8601String().split('T')[0],
      },
    ];
  }

  List<Map<String, dynamic>> _remindersForDay(DateTime day) {
    return _eventsForDay(day);
  }

  List<Map<String, dynamic>> _eventsForDay(DateTime day) {
    final List<Map<String, dynamic>> events = [];

    // 1. User/system reminders
    for (final r in _reminders) {
      final rawDate = r['reminder_date'];
      if (rawDate == null) continue;
      try {
        final date = DateTime.parse(rawDate as String);
        if (date.year == day.year && date.month == day.month && date.day == day.day) {
          events.add({
            'type': 'reminder',
            'title': r['title'] as String? ?? 'Farm Task',
            'description': r['description'] as String?,
            'icon': Icons.notifications_active_rounded,
            'color': AppColors.chlorotic,
          });
        }
      } catch (_) {}
    }

    // 2. Tracked / Planted crops events
    for (final crop in _trackedCrops) {
      final cropName = crop['crop_name'] as String? ?? 'Crop';
      final rawDate = crop['planting_date'] as String?;
      if (rawDate == null) continue;

      DateTime plantingDate;
      try {
        plantingDate = DateTime.parse(rawDate);
      } catch (_) {
        continue;
      }

      final emoji = getCropEmoji(cropName);

      // A. Planting Day event
      if (plantingDate.year == day.year &&
          plantingDate.month == day.month &&
          plantingDate.day == day.day) {
        events.add({
          'type': 'planting',
          'title': '$emoji $cropName: Planting Day',
          'description': 'Planted on ${plantingDate.day}/${plantingDate.month}/${plantingDate.year} • Stage 1: Sowing & Planting begins',
          'icon': Icons.eco_rounded,
          'color': AppColors.primary,
        });
      }

      // B. Stage Milestones
      final stages = cropGrowthCalendar[cropName];
      if (stages != null) {
        for (final stage in stages) {
          if (stage.startDay > 0) {
            final milestoneDate = plantingDate.add(Duration(days: stage.startDay));
            if (milestoneDate.year == day.year &&
                milestoneDate.month == day.month &&
                milestoneDate.day == day.day) {
              events.add({
                'type': 'stage',
                'title': '$emoji $cropName: ${stage.stageName}',
                'description': 'Stage Milestone (Day ${stage.startDay} of growth cycle)',
                'icon': Icons.trending_up_rounded,
                'color': AppColors.neon,
              });
            }
          }

          // Expected harvest start
          if (stage.endDay == null) {
            final harvestDate = plantingDate.add(Duration(days: stage.startDay));
            if (harvestDate.year == day.year &&
                harvestDate.month == day.month &&
                harvestDate.day == day.day) {
              events.add({
                'type': 'harvest',
                'title': '🌾 $cropName: Expected Harvest Time',
                'description': 'Target harvesting window begins',
                'icon': Icons.agriculture_rounded,
                'color': AppColors.rust,
              });
            }
          }
        }
      }

      // C. Active Care event if viewing today or the active day
      final isViewingToday = day.year == DateTime.now().year &&
          day.month == DateTime.now().month &&
          day.day == DateTime.now().day;
      if (isViewingToday) {
        final currentStage = getCurrentGrowthStage(cropName, plantingDate);
        if (currentStage != null) {
          events.add({
            'type': 'active',
            'title': '$emoji $cropName — Active Care (Day ${currentStage.daysSincePlanting})',
            'description': '${currentStage.stageName ?? 'Growing'} • Daily moisture & leaf inspection',
            'icon': Icons.spa_rounded,
            'color': AppColors.neon,
          });
        }
      }
    }

    return events;
  }

  Future<void> _showAddReminderDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final targetDate = _selectedDay ?? _focusedDay;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && titleController.text.isNotEmpty) {
      if (!mounted) return;
      final service = context.read<SupabaseService>();
      await service.addReminder(
        title: titleController.text,
        description: descController.text.isEmpty ? null : descController.text,
        date: targetDate,
      );
      _loadReminders();
    }
  }

  Future<void> _showAddCropDialog() async {
    String? selectedCrop = cropGrowthCalendar.keys.first;
    DateTime plantingDate = DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Track a Crop'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCrop,
                decoration: const InputDecoration(labelText: 'Crop'),
                items: cropGrowthCalendar.keys
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedCrop = v),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Planted: ${plantingDate.day}/${plantingDate.month}/${plantingDate.year}',
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: plantingDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => plantingDate = picked);
                      }
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Track'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedCrop != null) {
      if (!mounted) return;
      final service = context.read<SupabaseService>();
      await service.addTrackedCrop(selectedCrop!, plantingDate);

      // Auto-schedule helpful care tasks for this newly planted crop!
      await service.addReminder(
        title: '$selectedCrop: Sprout & Soil Moisture Check',
        description: 'Check germination and maintain optimal soil dampness',
        date: plantingDate.add(const Duration(days: 3)),
      );
      await service.addReminder(
        title: '$selectedCrop: Vegetative Health & Bio-Nutrient Spray',
        description: 'Inspect emerging leaves and apply preventive neem / bio-fertilizer',
        date: plantingDate.add(const Duration(days: 14)),
      );

      await _loadTrackedCrops();
      await _loadReminders();
    }
  }

  Future<void> _deleteTrackedCrop(String id) async {
    final service = context.read<SupabaseService>();
    await service.deleteTrackedCrop(id);
    _loadTrackedCrops();
  }

  @override
  Widget build(BuildContext context) {
    final dayReminders = _remindersForDay(_selectedDay ?? _focusedDay);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final borderColor = isDark ? const Color(0xFF2D3C33) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const GradientAppBar(title: 'Crop Calendar & Stages'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 4,
        onPressed: _showAddReminderDialog,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2035, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },
                      eventLoader: _remindersForDay,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle:
                            TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: AppColors.canopy.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.canopy,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: const BoxDecoration(
                          color: AppColors.rust,
                          shape: BoxShape.circle,
                        ),
                        weekendTextStyle: const TextStyle(color: AppColors.rust),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Reminders',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 12),
                  if (dayReminders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(Icons.event_available,
                              size: 40, color: AppColors.ink.withValues(alpha: 0.25)),
                          const SizedBox(height: 8),
                          Text('No reminders for this day',
                              style: TextStyle(
                                  color: AppColors.ink.withValues(alpha: 0.5))),
                        ],
                      ),
                    )
                  else
                    ...dayReminders.map((r) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.chlorotic.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_active_rounded,
                                  color: AppColors.chlorotic),
                            ),
                            title: Text(r['title'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: r['description'] != null
                                ? Text(r['description'] as String)
                                : null,
                          ),
                        )),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tracked Crops', style: Theme.of(context).textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: _showAddCropDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Track a crop'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_trackedCrops.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Icon(Icons.eco_outlined,
                              size: 40, color: isDark ? Colors.white24 : Colors.black26),
                          const SizedBox(height: 8),
                          Text('No crops tracked yet',
                              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
                        ],
                      ),
                    )
                  else
                    ..._trackedCrops.map((crop) {
                      final cropName = crop['crop_name'] as String;
                      final plantingDate = DateTime.parse(crop['planting_date'] as String);
                      final stage = getCurrentGrowthStage(cropName, plantingDate);
                      final stageIndex = stage == null
                          ? -1
                          : cropGrowthCalendar[cropName]!
                              .indexWhere((r) => r.stageName == stage.stageName);
                      final totalStages = cropGrowthCalendar[cropName]?.length ?? 5;
                      final progressInStage = stage == null || stage.stageEndDay == null
                          ? 1.0
                          : (stage.daysSincePlanting - stage.stageStartDay) /
                              (stage.stageEndDay! - stage.stageStartDay);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(cropName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700, fontSize: 16)),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      size: 20, color: AppColors.ink.withValues(alpha: 0.4)),
                                  onPressed: () => _deleteTrackedCrop(crop['id'] as String),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stage == null
                                  ? 'No growth data for this crop yet'
                                  : stage.stageName!,
                              style: const TextStyle(
                                  color: AppColors.neon, fontWeight: FontWeight.w600, fontSize: 14.5),
                            ),
                            if (stage != null) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progressInStage.clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: AppColors.darkSurfaceElevated,
                                  valueColor: const AlwaysStoppedAnimation(AppColors.neon),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Day ${stage.daysSincePlanting} • Stage ${stageIndex + 1} of $totalStages',
                                style: TextStyle(
                                    fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.5)),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
