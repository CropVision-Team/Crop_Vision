enum SeverityStage { g0, g1, g2, g3 }

extension SeverityStageX on SeverityStage {
  String get code => ['G0', 'G1', 'G2', 'G3'][index];

  String get label => [
        'Healthy',
        'Mild Infection',
        'Moderate Infection',
        'Critical Infection',
      ][index];

  static SeverityStage fromCode(String code) {
    switch (code) {
      case 'G0':
        return SeverityStage.g0;
      case 'G1':
        return SeverityStage.g1;
      case 'G2':
        return SeverityStage.g2;
      case 'G3':
        return SeverityStage.g3;
      default:
        throw ArgumentError('Unknown severity code: $code');
    }
  }
}

class Diagnosis {
  final String? id;
  final String imageUrl;
  final bool isValidLeaf;
  final String? rejectionReason;
  final bool isUnknownCrop;
  final String? predictedDisease;
  final double? confidence;
  final SeverityStage? severityStage;
  final double? severityPercent;
  final String? treatmentRecommendation;
  final String? preventionTips;
  final DateTime? createdAt;

  Diagnosis({
    this.id,
    required this.imageUrl,
    required this.isValidLeaf,
    this.rejectionReason,
    this.isUnknownCrop = false,
    this.predictedDisease,
    this.confidence,
    this.severityStage,
    this.severityPercent,
    this.treatmentRecommendation,
    this.preventionTips,
    this.createdAt,
  });

  Map<String, dynamic> toInsertMap(String userId) => {
        'user_id': userId,
        'image_url': imageUrl,
        'is_valid_leaf': isValidLeaf,
        'rejection_reason': rejectionReason,
        'predicted_disease': predictedDisease,
        'confidence': confidence,
        'severity_stage': severityStage?.code,
        'severity_percent': severityPercent,
        'treatment_recommendation': treatmentRecommendation,
        'prevention_tips': preventionTips,
      };

  factory Diagnosis.fromMap(Map<String, dynamic> map) => Diagnosis(
        id: map['id'] as String?,
        imageUrl: map['image_url'] as String,
        isValidLeaf: map['is_valid_leaf'] as bool,
        rejectionReason: map['rejection_reason'] as String?,
        predictedDisease: map['predicted_disease'] as String?,
        confidence: (map['confidence'] as num?)?.toDouble(),
        severityStage: map['severity_stage'] != null
            ? SeverityStageX.fromCode(map['severity_stage'] as String)
            : null,
        severityPercent: (map['severity_percent'] as num?)?.toDouble(),
        treatmentRecommendation: map['treatment_recommendation'] as String?,
        preventionTips: map['prevention_tips'] as String?,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : null,
      );
}
