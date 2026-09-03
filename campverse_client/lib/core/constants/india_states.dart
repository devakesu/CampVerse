/// Administrative entity representing an Indian State or Union Territory.
class IndianStateOrUT {
  /// Default constructor for [IndianStateOrUT].
  const IndianStateOrUT({
    required this.name,
    required this.code,
    required this.isUnionTerritory,
  });

  /// Official name of the state or union territory.
  final String name;

  /// Official two-letter ISO 3166-2:IN administrative code.
  final String code;

  /// Whether this region is a Union Territory (`true`) or a State (`false`).
  final bool isUnionTerritory;

  /// Human-readable category label.
  String get categoryLabel => isUnionTerritory ? 'Union Territory' : 'State';
}

/// Complete prefilled list of all 28 States and 8 Union Territories of India.
const List<IndianStateOrUT> kIndiaStatesAndUTs = [
  // 28 States (alphabetical)
  IndianStateOrUT(name: 'Andhra Pradesh', code: 'AP', isUnionTerritory: false),
  IndianStateOrUT(
    name: 'Arunachal Pradesh',
    code: 'AR',
    isUnionTerritory: false,
  ),
  IndianStateOrUT(name: 'Assam', code: 'AS', isUnionTerritory: false),
  IndianStateOrUT(name: 'Bihar', code: 'BR', isUnionTerritory: false),
  IndianStateOrUT(name: 'Chhattisgarh', code: 'CG', isUnionTerritory: false),
  IndianStateOrUT(name: 'Goa', code: 'GA', isUnionTerritory: false),
  IndianStateOrUT(name: 'Gujarat', code: 'GJ', isUnionTerritory: false),
  IndianStateOrUT(name: 'Haryana', code: 'HR', isUnionTerritory: false),
  IndianStateOrUT(
    name: 'Himachal Pradesh',
    code: 'HP',
    isUnionTerritory: false,
  ),
  IndianStateOrUT(name: 'Jharkhand', code: 'JH', isUnionTerritory: false),
  IndianStateOrUT(name: 'Karnataka', code: 'KA', isUnionTerritory: false),
  IndianStateOrUT(name: 'Kerala', code: 'KL', isUnionTerritory: false),
  IndianStateOrUT(name: 'Madhya Pradesh', code: 'MP', isUnionTerritory: false),
  IndianStateOrUT(name: 'Maharashtra', code: 'MH', isUnionTerritory: false),
  IndianStateOrUT(name: 'Manipur', code: 'MN', isUnionTerritory: false),
  IndianStateOrUT(name: 'Meghalaya', code: 'ML', isUnionTerritory: false),
  IndianStateOrUT(name: 'Mizoram', code: 'MZ', isUnionTerritory: false),
  IndianStateOrUT(name: 'Nagaland', code: 'NL', isUnionTerritory: false),
  IndianStateOrUT(name: 'Odisha', code: 'OD', isUnionTerritory: false),
  IndianStateOrUT(name: 'Punjab', code: 'PB', isUnionTerritory: false),
  IndianStateOrUT(name: 'Rajasthan', code: 'RJ', isUnionTerritory: false),
  IndianStateOrUT(name: 'Sikkim', code: 'SK', isUnionTerritory: false),
  IndianStateOrUT(name: 'Tamil Nadu', code: 'TN', isUnionTerritory: false),
  IndianStateOrUT(name: 'Telangana', code: 'TS', isUnionTerritory: false),
  IndianStateOrUT(name: 'Tripura', code: 'TR', isUnionTerritory: false),
  IndianStateOrUT(name: 'Uttar Pradesh', code: 'UP', isUnionTerritory: false),
  IndianStateOrUT(name: 'Uttarakhand', code: 'UK', isUnionTerritory: false),
  IndianStateOrUT(name: 'West Bengal', code: 'WB', isUnionTerritory: false),

  // 8 Union Territories (alphabetical)
  IndianStateOrUT(
    name: 'Andaman and Nicobar Islands',
    code: 'AN',
    isUnionTerritory: true,
  ),
  IndianStateOrUT(name: 'Chandigarh', code: 'CH', isUnionTerritory: true),
  IndianStateOrUT(
    name: 'Dadra and Nagar Haveli and Daman and Diu',
    code: 'DH',
    isUnionTerritory: true,
  ),
  IndianStateOrUT(name: 'Delhi', code: 'DL', isUnionTerritory: true),
  IndianStateOrUT(
    name: 'Jammu and Kashmir',
    code: 'JK',
    isUnionTerritory: true,
  ),
  IndianStateOrUT(name: 'Ladakh', code: 'LA', isUnionTerritory: true),
  IndianStateOrUT(name: 'Lakshadweep', code: 'LD', isUnionTerritory: true),
  IndianStateOrUT(name: 'Puducherry', code: 'PY', isUnionTerritory: true),
];

/// List containing only the 28 Indian States.
final List<IndianStateOrUT> kIndiaStates =
    kIndiaStatesAndUTs.where((item) => !item.isUnionTerritory).toList();

/// List containing only the 8 Indian Union Territories.
final List<IndianStateOrUT> kIndiaUnionTerritories =
    kIndiaStatesAndUTs.where((item) => item.isUnionTerritory).toList();

/// List of all 36 Indian State and Union Territory names.
final List<String> kIndiaStateNames =
    kIndiaStatesAndUTs.map((item) => item.name).toList();

/// Filter category for Indian States & UTs.
enum IndiaStateCategory {
  /// All 36 entities (States + UTs).
  all,

  /// Only 28 States.
  states,

  /// Only 8 Union Territories.
  unionTerritories,
}

/// Helper function to filter Indian states and union territories by search
/// query and category.
List<IndianStateOrUT> filterIndiaStates({
  String query = '',
  IndiaStateCategory category = IndiaStateCategory.all,
}) {
  final cleanQuery = query.trim().toLowerCase();

  return kIndiaStatesAndUTs.where((item) {
    // Category match
    if (category == IndiaStateCategory.states && item.isUnionTerritory) {
      return false;
    }
    if (category == IndiaStateCategory.unionTerritories &&
        !item.isUnionTerritory) {
      return false;
    }

    if (cleanQuery.isEmpty) {
      return true;
    }

    final nameMatches = item.name.toLowerCase().contains(cleanQuery);
    final codeMatches = item.code.toLowerCase() == cleanQuery ||
        item.code.toLowerCase().startsWith(cleanQuery);

    return nameMatches || codeMatches;
  }).toList();
}
