// AUTO-GENERATED from model/treatment_recommendations.py - regenerate
// this file whenever that one changes, rather than hand-editing,
// to keep the Flutter app and the Python ML pipeline in sync.

class TreatmentEntry {
  final String recommendation;
  final String prevention;
  const TreatmentEntry(this.recommendation, this.prevention);
}

const Map<String, Map<String, TreatmentEntry>> treatmentMap = {
  'Tomato___healthy': {
    'G0': TreatmentEntry(
      'No treatment needed. Plant is healthy.',
      'Continue regular monitoring, proper spacing, and balanced fertilization.',
    ),
  },
  'Tomato___Early_blight': {
    'G1': TreatmentEntry(
      'Remove affected lower leaves. Apply a preventive copper-based fungicide.',
      'Mulch soil to prevent spore splash-back onto leaves.',
    ),
    'G2': TreatmentEntry(
      'Apply copper-based or chlorothalonil fungicide every 7-10 days. Remove and destroy affected leaves.',
      'Rotate crops annually; avoid planting tomatoes/potatoes in the same soil consecutively.',
    ),
    'G3': TreatmentEntry(
      'Apply systemic fungicide immediately. Remove severely affected plants to prevent spread. Consult local agricultural extension officer.',
      'Consider resistant tomato varieties for the next planting cycle.',
    ),
  },
  'Tomato___Late_blight': {
    'G1': TreatmentEntry(
      'Apply preventive fungicide (mancozeb or copper-based).',
      'Improve field drainage and airflow between plants.',
    ),
    'G2': TreatmentEntry(
      'Apply systemic fungicide (metalaxyl-based). Remove infected foliage immediately.',
      'Avoid working in fields when foliage is wet to reduce spread.',
    ),
    'G3': TreatmentEntry(
      'Urgent: remove and destroy infected plants entirely. Apply fungicide to remaining healthy plants as a barrier.',
      'Late blight can destroy a field within days - report to local agri-extension for regional alerts.',
    ),
  },
  'Tomato___Bacterial_spot': {
    'G1': TreatmentEntry(
      'Apply copper-based bactericide. Avoid handling wet plants.',
      'Use certified disease-free seeds/transplants.',
    ),
    'G2': TreatmentEntry(
      'Increase copper spray frequency to every 5-7 days. Remove severely spotted leaves.',
      'Avoid overhead irrigation; water at the base of plants.',
    ),
    'G3': TreatmentEntry(
      'Remove and destroy heavily infected plants. Apply bactericide to remaining crop.',
      'Rotate with non-solanaceous crops for at least 2 years.',
    ),
  },
  'Tomato___Leaf_Mold': {
    'G1': TreatmentEntry(
      'Improve greenhouse/field ventilation. Apply fungicide if humidity remains high.',
      'Reduce humidity around plants; increase plant spacing.',
    ),
    'G2': TreatmentEntry(
      'Apply fungicide (chlorothalonil or copper-based). Remove affected leaves.',
      'Avoid leaf wetness overnight - water early in the day.',
    ),
    'G3': TreatmentEntry(
      'Apply systemic fungicide immediately; heavy leaf mold can severely reduce yield.',
      'Use resistant tomato varieties in humid climates.',
    ),
  },
  'Tomato___Septoria_leaf_spot': {
    'G1': TreatmentEntry(
      'Remove lower affected leaves. Apply preventive fungicide.',
      'Mulch to prevent soil splash onto lower leaves.',
    ),
    'G2': TreatmentEntry(
      'Apply fungicide every 7-10 days. Remove and destroy infected debris.',
      'Avoid working among wet plants to prevent spread.',
    ),
    'G3': TreatmentEntry(
      'Apply fungicide immediately; consider removing severely defoliated plants.',
      'Practice 2-3 year crop rotation away from tomato/potato.',
    ),
  },
  'Tomato___Spider_mites Two-spotted_spider_mite': {
    'G1': TreatmentEntry(
      'Spray with insecticidal soap or neem oil.',
      'Keep plants well-watered - mites thrive in drought-stressed plants.',
    ),
    'G2': TreatmentEntry(
      'Apply miticide. Introduce predatory mites if using biological control.',
      'Avoid excessive nitrogen fertilization, which favors mite reproduction.',
    ),
    'G3': TreatmentEntry(
      'Apply targeted miticide immediately; heavy infestation can defoliate plants rapidly.',
      'Regularly inspect undersides of leaves for early detection.',
    ),
  },
  'Tomato___Target_Spot': {
    'G1': TreatmentEntry(
      'Apply preventive fungicide; remove affected leaves.',
      'Ensure good air circulation between plants.',
    ),
    'G2': TreatmentEntry(
      'Apply fungicide (azoxystrobin or chlorothalonil-based) every 7-10 days.',
      'Avoid overhead watering; remove crop debris after harvest.',
    ),
    'G3': TreatmentEntry(
      'Apply fungicide immediately and remove severely infected plant material.',
      'Rotate crops and avoid dense planting in future seasons.',
    ),
  },
  'Tomato___Tomato_Yellow_Leaf_Curl_Virus': {
    'G1': TreatmentEntry(
      'Control whitefly vectors with insecticidal soap; remove affected leaves.',
      'Use whitefly-proof netting/screens in nursery stage.',
    ),
    'G2': TreatmentEntry(
      'Apply systemic insecticide to control whitefly population. Remove heavily symptomatic plants.',
      'Use reflective mulches to repel whiteflies.',
    ),
    'G3': TreatmentEntry(
      'Remove and destroy severely infected plants immediately - no cure exists once systemic. Focus on protecting remaining crop from whiteflies.',
      'Plant virus-resistant tomato varieties in future seasons.',
    ),
  },
  'Tomato___Tomato_mosaic_virus': {
    'G1': TreatmentEntry(
      'Remove affected leaves; disinfect tools between plants (virus spreads via contact).',
      'Wash hands and tools with soap before handling plants.',
    ),
    'G2': TreatmentEntry(
      'Remove moderately affected plants if spread is increasing. No chemical cure exists.',
      'Avoid tobacco product use near plants (a known transmission source).',
    ),
    'G3': TreatmentEntry(
      'Remove and destroy severely infected plants to protect the rest of the field.',
      'Use certified virus-free seed for future planting.',
    ),
  },
  'Potato___healthy': {
    'G0': TreatmentEntry(
      'No treatment needed. Plant is healthy.',
      'Continue regular monitoring and good field hygiene.',
    ),
  },
  'Potato___Early_blight': {
    'G1': TreatmentEntry(
      'Apply preventive fungicide. Remove lower affected leaves.',
      'Ensure balanced fertilization - avoid nitrogen deficiency, which increases susceptibility.',
    ),
    'G2': TreatmentEntry(
      'Apply fungicide (chlorothalonil or mancozeb) every 7-10 days.',
      'Rotate with non-host crops for at least 2 years.',
    ),
    'G3': TreatmentEntry(
      'Apply fungicide immediately; consider early harvest if tuber bulking is complete.',
      'Use certified disease-free seed potatoes.',
    ),
  },
  'Potato___Late_blight': {
    'G1': TreatmentEntry(
      'Apply preventive fungicide immediately - late blight spreads extremely fast.',
      'Monitor weather forecasts; blight thrives in cool, wet conditions.',
    ),
    'G2': TreatmentEntry(
      'Apply systemic fungicide. Remove and destroy infected foliage.',
      'Improve field drainage and plant spacing for airflow.',
    ),
    'G3': TreatmentEntry(
      'Urgent: destroy infected plants to prevent field-wide loss. This disease caused historic famines - treat as emergency.',
      'Report outbreaks to local agricultural extension for regional monitoring.',
    ),
  },
  'Apple___healthy': {
    'G0': TreatmentEntry(
      'No treatment needed.',
      'Prune trees to improve air circulation.',
    ),
  },
  'Apple___Black_rot': {
    'G1': TreatmentEntry(
      'Remove mummified fruit and cankers from tree.',
      'Sanitize pruning tools between cuts.',
    ),
    'G2': TreatmentEntry(
      'Apply fungicide spray program (captan or myclobutanil-based) during growing season.',
      'Remove nearby wild/abandoned apple trees that can host the fungus.',
    ),
    'G3': TreatmentEntry(
      'Aggressive pruning of infected branches. Apply fungicide immediately.',
      'Consider resistant apple cultivars for future plantings.',
    ),
  },
  'Apple___Apple_scab': {
    'G1': TreatmentEntry(
      'Apply preventive fungicide at green-tip stage.',
      'Rake and destroy fallen leaves in autumn (fungus overwinters there).',
    ),
    'G2': TreatmentEntry(
      'Apply fungicide (myclobutanil or captan) every 7-14 days through the season.',
      'Prune for better air circulation and sunlight penetration.',
    ),
    'G3': TreatmentEntry(
      'Apply fungicide immediately; heavy defoliation risk affects fruit yield next season too.',
      'Plant scab-resistant apple varieties.',
    ),
  },
  'Apple___Cedar_apple_rust': {
    'G1': TreatmentEntry(
      'Apply preventive fungicide in spring when orange gall spores are active nearby.',
      'Remove nearby juniper/cedar trees within 2 miles if feasible (alternate host).',
    ),
    'G2': TreatmentEntry(
      'Apply fungicide (myclobutanil-based) every 10-14 days during spring.',
      'Choose rust-resistant apple varieties for new plantings.',
    ),
    'G3': TreatmentEntry(
      'Apply fungicide immediately and remove heavily infected leaves.',
      'Coordinate with neighbors to remove alternate juniper hosts in the area.',
    ),
  },
  'Corn_(maize)___healthy': {
    'G0': TreatmentEntry(
      'No treatment needed.',
      'Practice crop rotation with non-host crops.',
    ),
  },
  'Corn_(maize)___Northern_Leaf_Blight': {
    'G1': TreatmentEntry(
      'Monitor closely; apply fungicide if weather remains humid.',
      'Use resistant hybrid seed varieties where available.',
    ),
    'G2': TreatmentEntry(
      'Apply foliar fungicide (strobilurin or triazole-based).',
      'Till under crop residue after harvest to reduce fungal spores.',
    ),
    'G3': TreatmentEntry(
      'Apply fungicide immediately; yield loss risk is high at this stage.',
      'Rotate to soybean or other non-host crop next season.',
    ),
  },
  'Corn_(maize)___Common_rust_': {
    'G1': TreatmentEntry(
      'Monitor; fungicide rarely needed at this stage for resistant hybrids.',
      'Plant rust-resistant hybrids where common rust pressure is high.',
    ),
    'G2': TreatmentEntry(
      'Apply fungicide if susceptible hybrid and conditions favor spread.',
      'Avoid late planting that exposes young plants to peak rust season.',
    ),
    'G3': TreatmentEntry(
      'Apply fungicide immediately to protect remaining green leaf area for grain fill.',
      'Select resistant hybrids for future seasons in high-pressure areas.',
    ),
  },
  'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot': {
    'G1': TreatmentEntry(
      'Monitor; consider fungicide if continuous corn planting history.',
      'Rotate crops; avoid continuous corn-on-corn planting.',
    ),
    'G2': TreatmentEntry(
      'Apply foliar fungicide, especially before tasseling.',
      'Till crop residue to reduce overwintering fungal spores.',
    ),
    'G3': TreatmentEntry(
      'Apply fungicide immediately; significant yield loss risk from leaf area loss.',
      'Select resistant hybrids and rotate away from corn for a season.',
    ),
  },
  'Grape___healthy': {
    'G0': TreatmentEntry(
      'No treatment needed.',
      'Maintain good canopy management for airflow.',
    ),
  },
  'Grape___Black_rot': {
    'G1': TreatmentEntry(
      'Remove mummified berries and infected leaves.',
      'Prune for open canopy to reduce humidity around clusters.',
    ),
    'G2': TreatmentEntry(
      'Apply fungicide (myclobutanil or captan) starting at bloom.',
      'Remove wild grape vines nearby that can harbor the fungus.',
    ),
    'G3': TreatmentEntry(
      'Apply fungicide immediately and remove severely infected clusters.',
      'Consider resistant grape varieties for new plantings.',
    ),
  },
  'Grape___Esca_(Black_Measles)': {
    'G1': TreatmentEntry(
      'Prune out affected wood during dry weather; disinfect tools.',
      'Avoid pruning wounds during wet weather when fungal spores are active.',
    ),
    'G2': TreatmentEntry(
      'Remove and destroy affected canes/spurs. No effective fungicide cure exists.',
      'Protect large pruning wounds with wound sealant.',
    ),
    'G3': TreatmentEntry(
      'Remove severely affected vines to prevent spread to healthy vines.',
      'Replant with certified disease-free nursery stock.',
    ),
  },
  'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)': {
    'G1': TreatmentEntry(
      'Apply preventive fungicide; remove affected leaves.',
      'Improve canopy airflow through leaf pulling.',
    ),
    'G2': TreatmentEntry(
      'Apply fungicide (copper-based) every 10-14 days.',
      'Avoid overhead irrigation.',
    ),
    'G3': TreatmentEntry(
      'Apply fungicide immediately; heavy defoliation affects fruit ripening.',
      'Rotate fungicide classes to avoid resistance buildup.',
    ),
  },
};

const genericFallbackRecommendation =
    'Specific guidance for this disease/severity combination is not yet '
    'in the knowledge base. Consult your local agricultural extension '
    'officer for a field-verified treatment plan.';

const genericFallbackPrevention =
    'General good practice: rotate crops, avoid overhead irrigation, '
    'remove infected plant debris, and monitor regularly.';

/// Steps 14-17: given the model's predicted class + the on-device
/// severity estimate, return treatment + prevention text.
TreatmentEntry getRecommendation(String diseaseClass, String severityStage) {
  final diseaseEntry = treatmentMap[diseaseClass];
  if (diseaseEntry == null) {
    return const TreatmentEntry(genericFallbackRecommendation, genericFallbackPrevention);
  }
  final stageEntry = diseaseEntry[severityStage];
  if (stageEntry == null) {
    if (diseaseClass.endsWith('healthy') && severityStage != 'G0') {
      return const TreatmentEntry(
        'Inconsistent result: classifier predicted a healthy leaf but the '
        'image shows visible discoloration. Please retake the photo or run a manual check.',
        'N/A',
      );
    }
    // Reverse case: a diagnosed DISEASE (not "healthy") combined with
    // G0 severity is equally a contradiction - a real disease should
    // never register as 0% affected. Handling both directions gives a
    // clearer message than the generic fallback in this specific case.
    if (!diseaseClass.endsWith('healthy') && severityStage == 'G0') {
      return const TreatmentEntry(
        'Inconsistent result: classifier predicted a disease but the '
        'image shows minimal discoloration. This can happen with the '
        'placeholder classifier, or with disease types (e.g. bacterial '
        'spot) whose lesion coloring differs from what the severity '
        'estimator was tuned for. Consider a manual check.',
        'N/A',
      );
    }
    return const TreatmentEntry(genericFallbackRecommendation, genericFallbackPrevention);
  }
  return stageEntry;
}
