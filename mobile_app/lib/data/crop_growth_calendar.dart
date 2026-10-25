/// Crop Growth Calendar - Dart mirror of model/crop_growth_calendar.py.
/// Keep both in sync if the day ranges change.
///
/// Since our capture flow photographs a single LEAF close-up (for
/// disease diagnosis), it cannot reliably detect whole-plant growth
/// stages like flowering or fruiting from that same photo - those need
/// to observe the whole plant, not a leaf close-up. And no labeled
/// dataset exists to train a dedicated "growth stage" image classifier.
///
/// So growth stage here is computed from TIME rather than the image:
/// the crop is identified from the disease-diagnosis model (already
/// gives a crop name), and the farmer sets a planting date once per
/// crop. Days-since-planting is then looked up against this crop's
/// typical stage durations.
///
/// IMPORTANT: these day ranges are illustrative, typical-case
/// estimates based on common growing guides, NOT measured from this
/// project's data. Actual timing varies by variety, climate, and
/// region - treat this as a rough guide, not a precise schedule.
library;

class GrowthStageRange {
  final String stageName;
  final int startDay;
  final int? endDay; // null means "no upper bound" (final stage)
  const GrowthStageRange(this.stageName, this.startDay, this.endDay);
}

const Map<String, List<GrowthStageRange>> cropGrowthCalendar = {
  'Tomato': [
    GrowthStageRange('Sowing & Planting', 0, 10),
    GrowthStageRange('Crop Establishment & Vegetative Growth', 10, 35),
    GrowthStageRange('Reproductive Growth & Care Management', 35, 65),
    GrowthStageRange('Maturation & Ripening', 65, 85),
    GrowthStageRange('Harvesting', 85, null),
  ],
  'Potato': [
    GrowthStageRange('Sowing & Planting', 0, 14),
    GrowthStageRange('Crop Establishment & Vegetative Growth', 14, 40),
    GrowthStageRange('Reproductive Growth & Care Management', 40, 70),
    GrowthStageRange('Maturation & Ripening', 70, 95),
    GrowthStageRange('Harvesting', 95, null),
  ],
  'Apple': [
    // Perennial tree - models one growing SEASON (bud break to
    // harvest), not the tree's multi-year life.
    GrowthStageRange('Sowing & Planting', 0, 20),
    GrowthStageRange('Crop Establishment & Vegetative Growth', 20, 60),
    GrowthStageRange('Reproductive Growth & Care Management', 60, 120),
    GrowthStageRange('Maturation & Ripening', 120, 160),
    GrowthStageRange('Harvesting', 160, null),
  ],
  'Corn (Maize)': [
    GrowthStageRange('Sowing & Planting', 0, 10),
    GrowthStageRange('Crop Establishment & Vegetative Growth', 10, 45),
    GrowthStageRange('Reproductive Growth & Care Management', 45, 75),
    GrowthStageRange('Maturation & Ripening', 75, 100),
    GrowthStageRange('Harvesting', 100, null),
  ],
  'Grape': [
    // Also perennial - models one season from bud break to harvest.
    GrowthStageRange('Sowing & Planting', 0, 15),
    GrowthStageRange('Crop Establishment & Vegetative Growth', 15, 55),
    GrowthStageRange('Reproductive Growth & Care Management', 55, 110),
    GrowthStageRange('Maturation & Ripening', 110, 150),
    GrowthStageRange('Harvesting', 150, null),
  ],
  'Blueberry': [
    GrowthStageRange('Sowing & Planting', 0, 20),
    GrowthStageRange('Crop Establishment & Vegetative Growth', 20, 60),
    GrowthStageRange('Reproductive Growth & Care Management', 60, 100),
    GrowthStageRange('Maturation & Ripening', 100, 130),
    GrowthStageRange('Harvesting', 130, null),
  ],
  'Cherry': [
    GrowthStageRange('Sowing & Planting', 0, 15),
    GrowthStageRange('Crop Establishment & Vegetative Growth', 15, 45),
    GrowthStageRange('Reproductive Growth & Care Management', 45, 75),
    GrowthStageRange('Maturation & Ripening', 75, 95),
    GrowthStageRange('Harvesting', 95, null),
  ],
  'Orange': [
    GrowthStageRange('Sowing & Planting', 0, 30),
    GrowthStageRange('Crop Establishment & Vegetative Growth', 30, 90),
    GrowthStageRange('Reproductive Growth & Care Management', 90, 180),
    GrowthStageRange('Maturation & Ripening', 180, 270),
    GrowthStageRange('Harvesting', 270, null),
  ],
  'Peach': [
    GrowthStageRange('Sowing & Planting', 0, 15),
    GrowthStageRange('Crop Establishment & Vegetative Growth', 15, 50),
    GrowthStageRange('Reproductive Growth & Care Management', 50, 90),
    GrowthStageRange('Maturation & Ripening', 90, 120),
    GrowthStageRange('Harvesting', 120, null),
  ],
  'Pepper (Bell)': [
    GrowthStageRange('Sowing & Planting', 0, 21),
    GrowthStageRange('Crop Establishment & Vegetative Growth', 21, 50),
    GrowthStageRange('Reproductive Growth & Care Management', 50, 80),
    GrowthStageRange('Maturation & Ripening', 80, 100),
    GrowthStageRange('Harvesting', 100, null),
  ],
  'Raspberry': [
    GrowthStageRange('Sowing & Planting', 0, 20),
    GrowthStageRange('Crop Establishment & Vegetative Growth', 20, 55),
    GrowthStageRange('Reproductive Growth & Care Management', 55, 85),
    GrowthStageRange('Maturation & Ripening', 85, 100),
    GrowthStageRange('Harvesting', 100, null),
  ],
  'Soybean': [
    GrowthStageRange('Sowing & Planting', 0, 10),
    GrowthStageRange('Crop Establishment & Vegetative Growth', 10, 45),
    GrowthStageRange('Reproductive Growth & Care Management', 45, 90),
    GrowthStageRange('Maturation & Ripening', 90, 110),
    GrowthStageRange('Harvesting', 110, null),
  ],
  'Squash': [
    GrowthStageRange('Sowing & Planting', 0, 10),
    GrowthStageRange('Crop Establishment & Vegetative Growth', 10, 35),
    GrowthStageRange('Reproductive Growth & Care Management', 35, 55),
    GrowthStageRange('Maturation & Ripening', 55, 70),
    GrowthStageRange('Harvesting', 70, null),
  ],
  'Strawberry': [
    GrowthStageRange('Sowing & Planting', 0, 21),
    GrowthStageRange('Crop Establishment & Vegetative Growth', 21, 60),
    GrowthStageRange('Reproductive Growth & Care Management', 60, 90),
    GrowthStageRange('Maturation & Ripening', 90, 105),
    GrowthStageRange('Harvesting', 105, null),
  ],
};

class CurrentGrowthStage {
  final String? stageName;
  final int daysSincePlanting;
  final int stageStartDay;
  final int? stageEndDay;

  const CurrentGrowthStage({
    required this.stageName,
    required this.daysSincePlanting,
    required this.stageStartDay,
    this.stageEndDay,
  });
}

const Map<String, String> growthStageDescriptions = {
  'Sowing & Planting':
      'Sow healthy seed or transplant strong seedlings at the recommended spacing.',
  'Crop Establishment & Vegetative Growth':
      'Support strong roots and leaf growth with steady water, nutrition, and weed control.',
  'Reproductive Growth & Care Management':
      'Protect flowers and developing produce with careful watering, scouting, and pest management.',
  'Maturation & Ripening':
      'Reduce stress and monitor colour, size, and firmness as the produce approaches maturity.',
  'Harvesting':
      'Harvest when the produce reaches the expected maturity window and handle it gently.',
};

const Map<String, List<String>> growthStageRecommendations = {
  'Sowing & Planting': [
    'Prepare well-drained soil and use healthy seed or seedlings.',
    'Record the planting date so the calendar can estimate later stages.',
  ],
  'Crop Establishment & Vegetative Growth': [
    'Keep moisture consistent without waterlogging the root zone.',
    'Remove competing weeds and inspect new leaves for disease or pests.',
  ],
  'Reproductive Growth & Care Management': [
    'Avoid drought stress during flowering and fruit or pod formation.',
    'Scout regularly and follow local, label-approved treatment guidance.',
  ],
  'Maturation & Ripening': [
    'Check the crop frequently for maturity signs and disease spread.',
    'Plan labour, storage, and transport before the harvest window begins.',
  ],
  'Harvesting': [
    'Harvest during the cooler part of the day where possible.',
    'Separate damaged produce and store the healthy crop appropriately.',
  ],
};

String stageDescription(String stageName) =>
    growthStageDescriptions[stageName] ??
    'Follow the crop calendar and monitor the plant regularly.';

List<String> stageRecommendations(String stageName) =>
    growthStageRecommendations[stageName] ?? const [];

DateTime? expectedHarvestDate(String cropName, DateTime plantingDate) {
  final stages = cropGrowthCalendar[cropName];
  if (stages == null || stages.isEmpty) return null;
  final harvestStage = stages[stages.length - 1];
  return plantingDate.add(Duration(days: harvestStage.startDay));
}

/// Returns null if we have no calendar data for this crop, or if the
/// planting date is in the future.
CurrentGrowthStage? getCurrentGrowthStage(
    String cropName, DateTime plantingDate) {
  final stages = cropGrowthCalendar[cropName];
  if (stages == null) return null;

  final daysSincePlanting = DateTime.now().difference(plantingDate).inDays;
  if (daysSincePlanting < 0) return null;

  for (final range in stages) {
    final withinRange =
        range.endDay == null || daysSincePlanting < range.endDay!;
    if (withinRange && daysSincePlanting >= range.startDay) {
      return CurrentGrowthStage(
        stageName: range.stageName,
        daysSincePlanting: daysSincePlanting,
        stageStartDay: range.startDay,
        stageEndDay: range.endDay,
      );
    }
  }
  final last = stages.last;
  return CurrentGrowthStage(
    stageName: last.stageName,
    daysSincePlanting: daysSincePlanting,
    stageStartDay: last.startDay,
    stageEndDay: last.endDay,
  );
}
