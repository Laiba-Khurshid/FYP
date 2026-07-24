/// Asset Management Module constants for AssetFlow.
///
/// Kept in a dedicated file (separate from [AppConstants] in
/// `app_constants.dart`) specifically for the department's real lab
/// names, asset category taxonomy, and the automatic Asset Code
/// generation rules, as requested for the Asset Management module.
class AssetConstants {
  AssetConstants._();

  // ---------------------------------------------------------------------
  // Laboratories
  // ---------------------------------------------------------------------
  // This application is built exclusively for the BS Computer Science
  // Department, so there is intentionally no department dropdown or
  // department field anywhere in the Asset Management module — every
  // asset implicitly belongs to this single department.
  static const List<String> labs = [
    'Project Lab',
    'Smart Lab 1',
    'Smart Lab 2',
    'Coding Lab 1',
    'Coding Lab 2',
    'Google Lab',
    'High Impact Lab',
    '912 Lab',
  ];

  // ---------------------------------------------------------------------
  // Asset categories, grouped for a readable dropdown UI.
  // ---------------------------------------------------------------------
  // Firestore only ever stores the leaf category string (e.g.
  // "Chromebook"), never the group name — the grouping below exists
  // purely to organize the category picker.
  static const Map<String, List<String>> categoryGroups = {
    'Computers & Devices': [
      'Computer System',
      'Chromebook',
      'VDI Computer',
      'HP Computer',
    ],
    'Input Devices': [
      'Keyboard',
      'Mouse',
      'Mic',
    ],
    'Display & Teaching Equipment': [
      'Interactive Board',
      'Smart Board',
      'Google Board',
      'White Board',
      'Green Board',
      'Projector',
      'Display Screen',
      'Teleconference Screen',
      'LED Screen',
    ],
    'Networking Equipment': [
      'Router',
      'Hub',
      'ONT',
      'HDMI',
    ],
    'Audio & Video': [
      'Sound System',
      'Speaker',
      'CCTV Camera',
      'EPTZ Camera',
      'Intercom',
    ],
    'Furniture': [
      'Chair',
      'Table',
      'Teacher Table',
      'Teacher Chair',
      'Branch Table',
      'Branch Chair',
      'Iron Bench',
      'Rack',
      'Cupboard',
      'Rostrum',
      'Notice Board',
    ],
    'Electrical Equipment': [
      'AC',
      'Fan',
      'Exhaust Fan',
      'Lights',
      'UPS',
    ],
  };

  /// Flat list of every category leaf value, in group order — used
  /// wherever a plain list (rather than a grouped dropdown) is needed,
  /// e.g. the filter dialog.
  static List<String> get allCategories =>
      categoryGroups.values.expand((categories) => categories).toList();

  // ---------------------------------------------------------------------
  // Asset Code generation
  // ---------------------------------------------------------------------
  // Only the categories below are individually tracked with a unique,
  // auto-generated Asset Code per unit (e.g. "CB001", "CB002", ...),
  // stored as documents in each asset's `asset_items` subcollection.
  // Every other category is a "bulk" asset — only its total [quantity]
  // is stored, with no per-unit codes or subcollection.
  static const Map<String, String> trackedCategoryPrefixes = {
    'Computer System': 'PC',
    'Chromebook': 'CB',
    'Projector': 'PJ',
    'Router': 'RT',
    'UPS': 'UPS',
    'Interactive Board': 'IB',
    'Smart Board': 'SB',
    'Display Screen': 'DS',
    'Teleconference Screen': 'TS',
    'EPTZ Camera': 'EC',
  };

  /// Returns `true` if [category] is individually tracked (i.e. gets
  /// auto-generated Asset Codes and an `asset_items` subcollection).
  static bool isTrackedCategory(String category) =>
      trackedCategoryPrefixes.containsKey(category);

  /// Returns the Asset Code prefix for a tracked [category], or `null`
  /// if the category is a bulk (untracked) category.
  static String? prefixForCategory(String category) => trackedCategoryPrefixes[category];

  // ---------------------------------------------------------------------
  // Default values for newly created asset_item documents
  // ---------------------------------------------------------------------
  static const String defaultItemStatus = 'Available';
  static const String defaultItemRemarks = '';

  // ---------------------------------------------------------------------
  // Firestore subcollection / meta document names
  // ---------------------------------------------------------------------
  static const String assetItemsSubcollection = 'asset_items';
  static const String metaCollection = 'meta';
  static const String assetCounterDoc = 'asset_counter';

  /// Prefix used for the friendly, sequential asset document ID
  /// (e.g. "AST001", "AST002", ...).
  static const String assetIdPrefix = 'AST';
}
