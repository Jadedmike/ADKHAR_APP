/// Centralized asset path registry for the visual identity decorations,
/// including Islamic geometric ornaments and olive branch decorations.
class AppAssets {
  AppAssets._();

  // Root paths
  static const String iconsPath = 'assets/icons/';
  static const String logosPath = 'assets/logos/';
  static const String imagesPath = 'assets/images/';
  static const String decorationsPath = 'assets/decorations/';
  static const String jsonPath = 'assets/json/';

  // Brands & Logos
  static const String appLogo = '${logosPath}app_logo.png';
  static const String logo2 = '${imagesPath}logo2.png';

  // Images & Backgrounds
  static const String gold = '${imagesPath}gold.png';
  static const String oliveBranches = '${imagesPath}olivebranches.png';

  // Decorations & Ornaments
  static const String oliveBranchLeft =
      '${decorationsPath}olive_branch_left.svg';
  static const String oliveBranchRight =
      '${decorationsPath}olive_branch_right.svg';
  static const String geometricOrnament =
      '${decorationsPath}islamic_ornament.svg';
  static const String geometricFrame = '${decorationsPath}islamic_frame.svg';
  static const String dividerPattern = '${decorationsPath}divider_pattern.svg';

  // JSON Data Files
  static const String jsonMorning = '${jsonPath}morning.json';
  static const String jsonAdhkarMorning = '${jsonPath}adhkar_morning.json';
  static const String jsonEvening = '${jsonPath}evening.json';
  static const String jsonAdhkarEvening = '${jsonPath}adhkar_evening.json';
  static const String jsonAfterPrayer = '${jsonPath}after_prayer.json';
  static const String jsonSleep = '${jsonPath}sleep.json';
  static const String jsonTravel = '${jsonPath}travel.json';
  static const String jsonQuranDuas = '${jsonPath}quran_duas.json';
  static const String jsonPropheticDuas = '${jsonPath}prophetic_duas.json';
  static const String jsonForgivenessDuas = '${jsonPath}forgiveness_duas.json';
  static const String jsonHome = '${jsonPath}home.json';
  static const String jsonFood = '${jsonPath}food.json';
  static const String jsonClothing = '${jsonPath}clothing.json';
  static const String jsonMosque = '${jsonPath}mosque.json';
}
