import 'package:flutter/material.dart';
import '../models/diagnosis.dart';
import '../widgets/leaf_severity_indicator.dart';
import '../widgets/gradient_app_bar.dart';
import '../data/crop_growth_calendar.dart';
import '../services/supabase_service.dart';
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
          title: const Text('Track this crop in your calendar'),
          subtitle: const Text(
              'Add its planting date to see growth stages and harvest timing.'),
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
                child: Text('Crop calendar • $cropName',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 12),
          Text(current.stageName!,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
              'Day ${current.daysSincePlanting} since planting • planted ${_formatDate(plantingDate)}'),
          if (harvest != null)
            Text('Expected first harvest: ${_formatDate(harvest)}'),
          const SizedBox(height: 8),
          Text(stageDescription(current.stageName!)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, '/calendar', arguments: cropName),
            icon: const Icon(Icons.open_in_new, size: 17),
            label: const Text('Open full crop calendar'),
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
        appBar: const GradientAppBar(title: 'Verification Failed'),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                diagnosis.rejectionReason ?? 'Image could not be verified.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retake Photo'),
              ),
            ],
          ),
        ),
      );
    }

    if (diagnosis.isUnknownCrop) {
      return Scaffold(
        appBar: const GradientAppBar(title: 'Crop Not Recognized'),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.help_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'This crop or disease could not be confidently identified. '
                'It may not be one of the crops this model was trained on.',
                textAlign: TextAlign.center,
              ),
              if (diagnosis.confidence != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Confidence: ${(diagnosis.confidence! * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Try Another Photo'),
              ),
            ],
          ),
        ),
      );
    }

    final stage = diagnosis.severityStage!;
    final cropName = _cropName(diagnosis.predictedDisease);

    return Scaffold(
      appBar: const GradientAppBar(title: 'Diagnosis Result'),
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
                  'Confidence: ${(diagnosis.confidence! * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Center(
              child: LeafSeverityIndicator(
                severityPercent: diagnosis.severityPercent ?? 0,
                stageCode: stage.code,
                stageLabel: stage.label,
                size: 120,
              ),
            ),
            const SizedBox(height: 24),
            Text('Recommended Treatment',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(diagnosis.treatmentRecommendation ??
                'No recommendation available.'),
            const SizedBox(height: 20),
            Text('Prevention Guidance',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(diagnosis.preventionTips ??
                'No prevention guidance available.'),
            if (cropName != null) ...[
              const SizedBox(height: 20),
              _calendarCard(context, cropName),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.smart_toy),
              label: const Text('Ask AI Assistant about this'),
              onPressed: () => Navigator.pushNamed(context, '/assistant'),
            ),
          ],
        ),
      ),
    );
  }
}
