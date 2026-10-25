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
  String? _suggestedCrop;
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _trackedCrops = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final argument = ModalRoute.of(context)?.settings.arguments;
      if (argument is String && cropGrowthCalendar.containsKey(argument)) {
        setState(() => _suggestedCrop = argument);
      }
    });
    _loadReminders();
    _loadTrackedCrops();
  }

  Future<void> _loadReminders() async {
    final service = context.read<SupabaseService>();
    final data = await service.fetchReminders();
    setState(() {
      _reminders = data;
      _loading = false;
    });
  }

  Future<void> _loadTrackedCrops() async {
    final service = context.read<SupabaseService>();
    final data = await service.fetchTrackedCrops();
    setState(() => _trackedCrops = data);
  }

  List<Map<String, dynamic>> _remindersForDay(DateTime day) {
    return _reminders.where((r) {
      final date = DateTime.parse(r['reminder_date'] as String);
      return date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).toList();
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
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
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
    String? selectedCrop = _suggestedCrop ?? cropGrowthCalendar.keys.first;
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
      _loadTrackedCrops();
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

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: const GradientAppBar(title: 'Crop Calendar'),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.canopy, Color(0xFF3D6B42)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.canopy.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: _showAddReminderDialog,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2035, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
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
                        titleTextStyle: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 17),
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
                        weekendTextStyle:
                            const TextStyle(color: AppColors.rust),
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
                              size: 40,
                              color: AppColors.ink.withValues(alpha: 0.25)),
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
                            color: AppColors.darkSurface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.chlorotic.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_active,
                                  color: AppColors.chlorotic),
                            ),
                            title: Text(r['title'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: r['description'] != null
                                ? Text(r['description'] as String)
                                : null,
                          ),
                        )),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tracked Crops',
                          style: Theme.of(context).textTheme.titleMedium),
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
                              size: 40,
                              color: AppColors.ink.withValues(alpha: 0.25)),
                          const SizedBox(height: 8),
                          Text('No crops tracked yet',
                              style: TextStyle(
                                  color: AppColors.ink.withValues(alpha: 0.5))),
                        ],
                      ),
                    )
                  else
                    ..._trackedCrops.map((crop) {
                      final cropName = crop['crop_name'] as String;
                      final plantingDate =
                          DateTime.parse(crop['planting_date'] as String);
                      final stage =
                          getCurrentGrowthStage(cropName, plantingDate);
                      final stageIndex = stage == null
                          ? -1
                          : cropGrowthCalendar[cropName]!.indexWhere(
                              (r) => r.stageName == stage.stageName);
                      final totalStages =
                          cropGrowthCalendar[cropName]?.length ?? 5;
                      final progressInStage = stage == null ||
                              stage.stageEndDay == null
                          ? 1.0
                          : (stage.daysSincePlanting - stage.stageStartDay) /
                              (stage.stageEndDay! - stage.stageStartDay);
                      final harvestDate =
                          expectedHarvestDate(cropName, plantingDate);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
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
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      size: 20,
                                      color:
                                          AppColors.ink.withValues(alpha: 0.4)),
                                  onPressed: () =>
                                      _deleteTrackedCrop(crop['id'] as String),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stage == null
                                  ? 'No growth data for this crop yet'
                                  : stage.stageName!,
                              style: const TextStyle(
                                  color: AppColors.neon,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.5),
                            ),
                            if (stage != null) ...[
                              const SizedBox(height: 6),
                              Text(stageDescription(stage.stageName!),
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.ink
                                          .withValues(alpha: 0.65))),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progressInStage.clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor:
                                      AppColors.darkSurfaceElevated,
                                  valueColor: const AlwaysStoppedAnimation(
                                      AppColors.neon),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Day ${stage.daysSincePlanting} • Stage ${stageIndex + 1} of $totalStages'
                                '${harvestDate == null ? '' : ' • Harvest from ${harvestDate.day}/${harvestDate.month}/${harvestDate.year}'}',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color:
                                        AppColors.ink.withValues(alpha: 0.5)),
                              ),
                              const SizedBox(height: 12),
                              ...stageRecommendations(stage.stageName!).map(
                                (tip) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ',
                                          style:
                                              TextStyle(color: AppColors.neon)),
                                      Expanded(
                                          child: Text(tip,
                                              style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: AppColors.ink
                                                      .withValues(
                                                          alpha: 0.7)))),
                                    ],
                                  ),
                                ),
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
