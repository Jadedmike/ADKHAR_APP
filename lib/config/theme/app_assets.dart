/// Centralized asset path registry for the visual identity decorations,
/// including Islamic geometric ornaments and olive branch decorations.
class AppAssets {
  AppAssets._();

  // Root paths
  static const String iconsPath = 'assets/icons/';
  static const String logosPath = 'assets/logos/';
  static const String imagesPath = 'assets/images/';
  static const String decorationsPath = 'assets/decorations/';

  // Brands & Logos
  static const String appLogo = '${logosPath}app_logo.png';

  // Decorations & Ornaments
  static const String oliveBranchLeft = '${decorationsPath}olive_branch_left.svg';
  static const String oliveBranchRight = '${decorationsPath}olive_branch_right.svg';
  static const String geometricOrnament = '${decorationsPath}islamic_ornament.svg';
  static const String geometricFrame = '${decorationsPath}islamic_frame.svg';
  static const String dividerPattern = '${decorationsPath}divider_pattern.svg';
}
