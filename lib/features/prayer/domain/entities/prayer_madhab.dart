import 'package:adhan/adhan.dart' as adhan;

/// Juristic madhab used to calculate Asr prayer time.
enum PrayerMadhab {
  shafi(
    storageKey: 'shafi',
    arabicName: 'الشافعي (الجمهور)',
    adhanMadhab: adhan.Madhab.shafi,
  ),
  hanafi(
    storageKey: 'hanafi',
    arabicName: 'الحنفي',
    adhanMadhab: adhan.Madhab.hanafi,
  );

  final String storageKey;
  final String arabicName;
  final adhan.Madhab adhanMadhab;

  const PrayerMadhab({
    required this.storageKey,
    required this.arabicName,
    required this.adhanMadhab,
  });

  /// Parses a persisted storage key into [PrayerMadhab], or returns null if unknown.
  static PrayerMadhab? tryFromStorageKey(Object? key) {
    if (key is! String) return null;
    for (final madhab in values) {
      if (madhab.storageKey == key) return madhab;
    }
    return null;
  }
}

