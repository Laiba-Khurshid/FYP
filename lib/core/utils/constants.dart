/// Asset Management Module constants for AssetFlow.
class AssetConstants {
  AssetConstants._();

  // ---------------------------------------------------------------------
  // Laboratories
  // ---------------------------------------------------------------------
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
  static const Map<String, List<String>> categoryGroups = {
    'Computers & Devices': [
      'Computer System',
      'Chromebook',
      'VDI Computer',
      'HP Computer',
      'Lenovo Computer System',
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
      'Projection Screen',
    ],
    'Networking Equipment': [
      'Router',
      'Hub',
      'ONT',
      'HDMI',
      'Accessory',
      'Internet',
    ],
    'Audio & Video': [
      'Sound System',
      'Sound Speaker',
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
      'Board',
      'Acrylic Board',
    ],
    'Electrical Equipment': [
      'AC',
      'Fan',
      'Exhaust Fan',
      'Lights',
      'Light',
      'UPS',
    ],
  };

  /// Flat list of every category leaf value, in group order.
  static List<String> get allCategories =>
      categoryGroups.values.expand((categories) => categories).toList();

  // ---------------------------------------------------------------------
  // Asset Code generation (Tracked Categories)
  // SAB TRACKED CATEGORIES (HAR UNIT KA UNIQUE ID)
  // ---------------------------------------------------------------------
  static const Map<String, String> trackedCategoryPrefixes = {
    // Computers
    'Computer System': 'PC',
    'Lenovo Computer System': 'LN',
    'HP Computer': 'HP',
    'VDI Computer': 'VD',
    'Chromebook': 'CB',

    // Input Devices
    'Mouse': 'MB',
    'Keyboard': 'KB',
    'Mic': 'MC',

    // Display & Teaching
    'Projector': 'PJ',
    'Smart Board': 'SB',
    'Interactive Board': 'IB',
    'Display Screen': 'DS',
    'Teleconference Screen': 'TS',
    'LED Screen': 'LS',
    'Projection Screen': 'PS',
    'Google Board': 'GB',

    // Networking Equipment
    'Router': 'RT',
    'Internet': 'IN',
    'ONT': 'OT',
    'Hub': 'HB',

    // Audio & Video
    'Sound System': 'SS',
    'Sound Speaker': 'SP',
    'CCTV Camera': 'CC',
    'EPTZ Camera': 'EC',
    'Intercom': 'IC',

    // Electrical Equipment
    'AC': 'AC',
    'Fan': 'FN',
    'UPS': 'UPS',
  };

  static bool isTrackedCategory(String category) =>
      trackedCategoryPrefixes.containsKey(category);

  static String? prefixForCategory(String category) => trackedCategoryPrefixes[category];

  // ---------------------------------------------------------------------
  // Default values for newly created asset_item documents
  // ---------------------------------------------------------------------
  static const String defaultItemStatus = 'Available';
  static const String defaultItemRemarks = '';

  // ================================================================
  // FIRESTORE SUBCOLLECTION / META DOCUMENT NAMES (ADDED)
  // ================================================================
  static const String assetItemsSubcollection = 'asset_items';
  static const String metaCollection = 'meta';
  static const String assetCounterDoc = 'asset_counter';

  /// Prefix used for the friendly, sequential asset document ID
  static const String assetIdPrefix = 'AST';
}