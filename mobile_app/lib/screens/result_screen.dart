import 'package:flutter/material.dart';
import '../models/diagnosis.dart';
import '../widgets/leaf_severity_indicator.dart';
import '../widgets/gradient_app_bar.dart';
import '../data/crop_growth_calendar.dart';
import '../services/supabase_service.dart';
import '../l10n/locale_provider.dart';
import 'package:provider/provider.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Map<String, dynamic>? _trackedCrop;
  bool _loadingCalendar = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadingCalendar) {
      final diagnosis = ModalRoute.of(context)!.settings.arguments as Diagnosis;
      final cropName = _cropName(diagnosis.predictedDisease);
      if (cropName != null) {
        _loadTrackedCrop(cropName);
      } else {
        _loadingCalendar = false;
      }
    }
  }

  String? _cropName(String? predictedDisease) {
    if (predictedDisease == null || !predictedDisease.contains('___')) {
      return null;
    }
    return predictedDisease.split('___').first;
  }

  Future<void> _loadTrackedCrop(String cropName) async {
    final tracked =
        await context.read<SupabaseService>().fetchTrackedCrop(cropName);
    if (mounted) {
      setState(() {
        _trackedCrop = tracked;
        _loadingCalendar = false;
      });
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  Widget _calendarCard(BuildContext context, String cropName) {
    if (_loadingCalendar) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_trackedCrop == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.calendar_month),
          title: Text(context.tr('track_this_crop')),
          subtitle: Text(context.tr('track_crop_subtitle')),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () =>
              Navigator.pushNamed(context, '/calendar', arguments: cropName),
        ),
      );
    }

    final plantingDate =
        DateTime.parse(_trackedCrop!['planting_date'] as String);
    final current = getCurrentGrowthStage(cropName, plantingDate);
    final harvest = expectedHarvestDate(cropName, plantingDate);
    if (current == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.eco_outlined),
            const SizedBox(width: 8),
            Expanded(
                child: Text('${context.tr('crop_calendar_bullet')} $cropName',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 12),
          Text(current.stageName!,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
              '${context.tr('day_prefix')} ${current.daysSincePlanting} ${context.tr('day_since_planting')} ${_formatDate(plantingDate)}'),
          if (harvest != null)
            Text('${context.tr('expected_harvest')} ${_formatDate(harvest)}'),
          const SizedBox(height: 8),
          Text(stageDescription(current.stageName!)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, '/calendar', arguments: cropName),
            icon: const Icon(Icons.open_in_new, size: 17),
            label: Text(context.tr('open_full_calendar')),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diagnosis = ModalRoute.of(context)!.settings.arguments as Diagnosis;

    if (!diagnosis.isValidLeaf) {
      return Scaffold(
        appBar: GradientAppBar(title: context.tr('verification_failed')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                diagnosis.rejectionReason != null
                    ? context.tr(diagnosis.rejectionReason!)
                    : context.tr('err_file_not_image'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('retake_photo')),
              ),
            ],
          ),
        ),
      );
    }

    if (diagnosis.isUnknownCrop) {
      return Scaffold(
        appBar: GradientAppBar(title: context.tr('crop_not_recognized')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.help_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                context.tr('crop_not_recognized_desc'),
                textAlign: TextAlign.center,
              ),
              if (diagnosis.confidence != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${context.tr('confidence')}: ${(diagnosis.confidence! * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('try_another_photo')),
              ),
            ],
          ),
        ),
      );
    }

    final stage = diagnosis.severityStage!;
    final cropName = _cropName(diagnosis.predictedDisease);

    return Scaffold(
      appBar: GradientAppBar(title: context.tr('diagnosis_result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(diagnosis.imageUrl,
                  height: 220, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            Text(diagnosis.predictedDisease ?? 'Unknown',
                style: Theme.of(context).textTheme.titleLarge),
            if (diagnosis.confidence != null)
              Text(
                  '${context.tr('confidence')}: ${(diagnosis.confidence! * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Center(
              child: LeafSeverityIndicator(
                severityPercent: diagnosis.severityPercent ?? 0,
                stageCode: stage.code,
                stageLabel: stage.localizedLabel(context),
                size: 120,
              ),
            ),
            const SizedBox(height: 24),
            Text(context.tr('recommended_treatment'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(diagnosis.treatmentRecommendation ??
                context.tr('no_recommendation')),
            const SizedBox(height: 20),
            Text(context.tr('prevention_guidance'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(diagnosis.preventionTips ??
                context.tr('no_prevention')),
            if (cropName != null) ...[
              const SizedBox(height: 20),
              _calendarCard(context, cropName),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.smart_toy),
              label: Text(context.tr('ask_ai_about_this')),
              onPressed: () => Navigator.pushNamed(context, '/assistant'),
            ),
          ],
        ),
      ),
    );
  }
}
