import 'package:intl/intl.dart';

/// Data model representing a daily content item (Dhikr, Dua, Ayah, or Quote).
class DailyContentItem {
  final String text;
  final String source;
  final String categoryTitle;

  const DailyContentItem({
    required this.text,
    required this.source,
    required this.categoryTitle,
  });

  Map<String, dynamic> toFavoriteItem() {
    return {
      'categoryTitle': categoryTitle,
      'text': text,
      'source': source,
    };
  }
}

/// Helper utility for deterministically selecting daily Dhikr, Dua, Ayah, and Quote
/// based on the calendar date (year and day-of-year).
class DailyContentHelper {
  DailyContentHelper._();

  /// Calculate the day of the year (1-366) for a given date.
  static int getDayOfYear([DateTime? date]) {
    final d = date ?? DateTime.now();
    return int.parse(DateFormat('D').format(d));
  }

  /// Calculate a deterministic daily seed integer combining year and day-of-year.
  static int getDailySeed([DateTime? date]) {
    final d = date ?? DateTime.now();
    final dayOfYear = getDayOfYear(d);
    return d.year * 1000 + dayOfYear;
  }

  // --- Dhikr of the Day Collection ---
  static const List<DailyContentItem> _dhikrs = [
    DailyContentItem(
      categoryTitle: 'أذكار اليوم',
      text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ.',
      source: 'رواه البخاري ومسلم',
    ),
    DailyContentItem(
      categoryTitle: 'أذكار اليوم',
      text:
          'لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
      source: 'رواه البخاري ومسلم',
    ),
    DailyContentItem(
      categoryTitle: 'أذكار اليوم',
      text: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ.',
      source: 'رواه البخاري',
    ),
    DailyContentItem(
      categoryTitle: 'أذكار اليوم',
      text:
          'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلاَ إِلَهَ إِلاَّ اللَّهُ، وَاللَّهُ أَكْبَرُ.',
      source: 'رواه مسلم',
    ),
    DailyContentItem(
      categoryTitle: 'أذكار اليوم',
      text: 'لاَ حَوْلَ وَلاَ قُوَّةَ إِلاَّ بِاللَّهِ.',
      source: 'رواه البخاري ومسلم',
    ),
    DailyContentItem(
      categoryTitle: 'أذكار اليوم',
      text: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ.',
      source: 'رواه الطبراني',
    ),
    DailyContentItem(
      categoryTitle: 'أذكار اليوم',
      text:
          'يَا حَيُّ يَا قَيُومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلاَ تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ.',
      source: 'رواه الحاكم وصححه الألباني',
    ),
    DailyContentItem(
      categoryTitle: 'أذكار اليوم',
      text:
          'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالإِسْلاَمِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا.',
      source: 'رواه أبو داود والترمذي',
    ),
    DailyContentItem(
      categoryTitle: 'أذكار اليوم',
      text:
          'حَسْبِيَ اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ.',
      source: 'رواه أبو داود',
    ),
    DailyContentItem(
      categoryTitle: 'أذكار اليوم',
      text:
          'بِسْمِ اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الأَرْضِ وَلاَ فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ.',
      source: 'رواه أبو داود والترمذي',
    ),
    DailyContentItem(
      categoryTitle: 'أذكار اليوم',
      text:
          'اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ.',
      source: 'رواه البخاري',
    ),
    DailyContentItem(
      categoryTitle: 'أذكار اليوم',
      text:
          'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ.',
      source: 'رواه مسلم',
    ),
    DailyContentItem(
      categoryTitle: 'أذكار اليوم',
      text:
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلاً مُتَقَبَّلاً.',
      source: 'رواه ابن ماجه',
    ),
    DailyContentItem(
      categoryTitle: 'أذكار اليوم',
      text: 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ.',
      source: 'رواه أبو داود',
    ),
    DailyContentItem(
      categoryTitle: 'أذكار اليوم',
      text: 'الْحَمْدُ لِلَّهِ الَّذِي بِنِعْمَتِهِ تَتِمُّ الصَّالِحَاتُ.',
      source: 'رواه ابن ماجه وصححه الألباني',
    ),
  ];

  // --- Dua of the Day Collection ---
  static const List<DailyContentItem> _duas = [
    DailyContentItem(
      categoryTitle: 'أدعية اليوم',
      text:
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي.',
      source: 'رواه أبو داود',
    ),
    DailyContentItem(
      categoryTitle: 'أدعية اليوم',
      text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى.',
      source: 'رواه مسلم',
    ),
    DailyContentItem(
      categoryTitle: 'أدعية اليوم',
      text: 'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ.',
      source: 'رواه الترمذي',
    ),
    DailyContentItem(
      categoryTitle: 'أدعية اليوم',
      text:
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.',
      source: 'سورة البقرة - الآية 201',
    ),
    DailyContentItem(
      categoryTitle: 'أدعية اليوم',
      text:
          'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي وَاحْلُلْ عُقْدَةً مِنْ لِسَانِي يَفْقَهُوا قَوْلِي.',
      source: 'سورة طه - الآية 25-28',
    ),
    DailyContentItem(
      categoryTitle: 'أدعية اليوم',
      text: 'لاَّ إِلَهَ إِلاَّ أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ.',
      source: 'سورة الأنبياء - الآية 87',
    ),
    DailyContentItem(
      categoryTitle: 'أدعية اليوم',
      text:
          'رَبَّنَا لاَ تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً إِنَّكَ أَنْتَ الْوَهَّابُ.',
      source: 'سورة آل عمران - الآية 8',
    ),
    DailyContentItem(
      categoryTitle: 'أدعية اليوم',
      text:
          'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ.',
      source: 'رواه البخاري',
    ),
    DailyContentItem(
      categoryTitle: 'أدعية اليوم',
      text:
          'اللَّهُمَّ اهْدِنِي فِيمَنْ هَدَيْتَ، وَعَافِنِي فِيمَنْ عَافَيْتَ، وَتَوَلَّنِي فِيمَنْ تَوَلَّيْتَ.',
      source: 'رواه أبو داود والترمذي',
    ),
    DailyContentItem(
      categoryTitle: 'أدعية اليوم',
      text:
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنَ الْخَيْرِ كُلِّهِ عَاجِلِهِ وَآجِلِهِ مَا عَلِمْتُ مِنْهُ وَمَا لَمْ أَعْلَمْ.',
      source: 'رواه ابن ماجه',
    ),
    DailyContentItem(
      categoryTitle: 'أدعية اليوم',
      text:
          'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا.',
      source: 'سورة الفرقان - الآية 74',
    ),
    DailyContentItem(
      categoryTitle: 'أدعية اليوم',
      text:
          'رَبِّ اغْفِرْ لِي وَلِوَالِدَيَّ وَلِمَنْ دَخَلَ بَيْتِيَ مُؤْمِنًا وَلِلْمُؤْمِنِينَ وَالْمُؤْمِنَاتِ.',
      source: 'سورة نوح - الآية 28',
    ),
    DailyContentItem(
      categoryTitle: 'أدعية اليوم',
      text: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي.',
      source: 'رواه الترمذي',
    ),
    DailyContentItem(
      categoryTitle: 'أدعية اليوم',
      text: 'رَبِّ زِدْنِي عِلْمًا.',
      source: 'سورة طه - الآية 114',
    ),
    DailyContentItem(
      categoryTitle: 'أدعية اليوم',
      text: 'اللَّهُمَّ أَعِنِّي عَلَى شُكْرِكَ وَذِكْرِكَ وَحُسْنِ عِبَادَتِكَ.',
      source: 'رواه النسائي',
    ),
  ];

  // --- Random Ayah Collection ---
  static const List<DailyContentItem> _ayahs = [
    DailyContentItem(
      categoryTitle: 'آية عشوائية',
      text: '﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
      source: 'سورة الرعد - الآية 28',
    ),
    DailyContentItem(
      categoryTitle: 'آية عشوائية',
      text: '﴿ فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ ﴾',
      source: 'سورة البقرة - الآية 152',
    ),
    DailyContentItem(
      categoryTitle: 'آية عشوائية',
      text:
          '﴿ وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ ﴾',
      source: 'سورة البقرة - الآية 186',
    ),
    DailyContentItem(
      categoryTitle: 'آية عشوائية',
      text: '﴿ إِنَّ مَعَ الْعُسْرِ يُسْرًا ﴾',
      source: 'سورة الشرح - الآية 6',
    ),
    DailyContentItem(
      categoryTitle: 'آية عشوائية',
      text:
          '﴿ وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ ﴾',
      source: 'سورة الطلاق - الآية 2-3',
    ),
    DailyContentItem(
      categoryTitle: 'آية عشوائية',
      text: '﴿ وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ ﴾',
      source: 'سورة الطلاق - الآية 3',
    ),
    DailyContentItem(
      categoryTitle: 'آية عشوائية',
      text: '﴿ وَمَا كَانَ اللَّهُ مُعَذِّبَهُمْ وَهُمْ يَسْتَغْفِرُونَ ﴾',
      source: 'سورة الأنفال - الآية 33',
    ),
    DailyContentItem(
      categoryTitle: 'آية عشوائية',
      text: '﴿ وَقُل رَّبِّ زِدْنِي عِلْمًا ﴾',
      source: 'سورة طه - الآية 114',
    ),
    DailyContentItem(
      categoryTitle: 'آية عشوائية',
      text: '﴿ وَبَشِّرِ الصَّابِرِينَ ﴾',
      source: 'سورة البقرة - الآية 155',
    ),
    DailyContentItem(
      categoryTitle: 'آية عشوائية',
      text: '﴿ إِنَّ اللَّهَ مَعَ الصَّابِرِينَ ﴾',
      source: 'سورة البقرة - الآية 153',
    ),
    DailyContentItem(
      categoryTitle: 'آية عشوائية',
      text: '﴿ وَرَحْمَتِي وَسِعَتْ كُلَّ شَيْءٍ ﴾',
      source: 'سورة الأعراف - الآية 156',
    ),
    DailyContentItem(
      categoryTitle: 'آية عشوائية',
      text: '﴿ لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ ﴾',
      source: 'سورة إبراهيم - الآية 7',
    ),
    DailyContentItem(
      categoryTitle: 'آية عشوائية',
      text: '﴿ ادْعُونِي أَسْتَجِبْ لَكُمْ ﴾',
      source: 'سورة غافر - الآية 60',
    ),
    DailyContentItem(
      categoryTitle: 'آية عشوائية',
      text: '﴿ وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ ﴾',
      source: 'سورة الحديد - الآية 4',
    ),
    DailyContentItem(
      categoryTitle: 'آية عشوائية',
      text: '﴿ سَيَجْعَلُ اللَّهُ بَعْدَ عُسْرٍ يُسْرًا ﴾',
      source: 'سورة الطلاق - الآية 7',
    ),
  ];

  // --- Islamic Quote Collection ---
  static const List<DailyContentItem> _quotes = [
    DailyContentItem(
      categoryTitle: 'اقتباس إسلامي',
      text: 'وما كان الله معذبهم وهم يستغفرون.',
      source: 'سورة الأنفال - الآية 33',
    ),
    DailyContentItem(
      categoryTitle: 'اقتباس إسلامي',
      text:
          'مَنْ عَمِلَ صَالِحًا مِّن ذَكَرٍ أَوْ أُنثَىٰ وَهُوَ مُؤْمِنٌ فَلَنُحْيِيَنَّهُ حَيَاةً طَيِّبَةً.',
      source: 'سورة النحل - الآية 97',
    ),
    DailyContentItem(
      categoryTitle: 'اقتباس إسلامي',
      text: 'وَاسْتَغْفِرُوا اللَّهَ إِنَّ اللَّهَ غَفُورٌ رَّحِيمٌ.',
      source: 'سورة المزمل - الآية 20',
    ),
    DailyContentItem(
      categoryTitle: 'اقتباس إسلامي',
      text: 'إِنَّ رَبِّي قَرِيبٌ مُّجِيبٌ.',
      source: 'سورة هود - الآية 61',
    ),
    DailyContentItem(
      categoryTitle: 'اقتباس إسلامي',
      text: 'وَتَوَكَّلْ عَلَى الْحَيِّ الَّذِي لا يَمُوتُ.',
      source: 'سورة الفرقان - الآية 58',
    ),
    DailyContentItem(
      categoryTitle: 'اقتباس إسلامي',
      text: 'أَلَيْسَ اللَّهُ بِكَافٍ عَبْدَهُ.',
      source: 'سورة الزمر - الآية 36',
    ),
    DailyContentItem(
      categoryTitle: 'اقتباس إسلامي',
      text: 'وَإِن يَمْسَسْكَ اللَّهُ بِضُرٍّ فَلا كَاشِفَ لَهُ إِلاَّ هُوَ.',
      source: 'سورة الأنعام - الآية 17',
    ),
    DailyContentItem(
      categoryTitle: 'اقتباس إسلامي',
      text: 'وَاصْبِرْ فإِنَّ اللَّهَ لا يُضِيعُ أَجْرَ الْمُحْسِنِينَ.',
      source: 'سورة هود - الآية 115',
    ),
    DailyContentItem(
      categoryTitle: 'اقتباس إسلامي',
      text: 'إِنَّمَا يُوَفَّى الصَّابِرُونَ أَجْرَهُم بِغَيْرِ حِسَابٍ.',
      source: 'سورة الزمر - الآية 10',
    ),
    DailyContentItem(
      categoryTitle: 'اقتباس إسلامي',
      text: 'وَلا تَيْأَسُوا مِن رَّوْحِ اللَّهِ.',
      source: 'سورة يوسف - الآية 87',
    ),
    DailyContentItem(
      categoryTitle: 'اقتباس إسلامي',
      text: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا.',
      source: 'سورة الشرح - الآية 5',
    ),
    DailyContentItem(
      categoryTitle: 'اقتباس إسلامي',
      text: 'إِنَّ رَبِّي لَطِيفٌ لِّمَا يَشَاءُ.',
      source: 'سورة يوسف - الآية 100',
    ),
    DailyContentItem(
      categoryTitle: 'اقتباس إسلامي',
      text: 'وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ.',
      source: 'سورة غافر - الآية 60',
    ),
    DailyContentItem(
      categoryTitle: 'اقتباس إسلامي',
      text: 'وَاللَّهُ يَعْلَمُ وَأَنتُمْ لا تَعْلَمُونَ.',
      source: 'سورة البقرة - الآية 216',
    ),
    DailyContentItem(
      categoryTitle: 'اقتباس إسلامي',
      text: 'وَكَفَى بِاللَّهِ وَكِيلاً.',
      source: 'سورة النساء - الآية 81',
    ),
  ];

  /// Get calculated index for Dhikr of the Day.
  static int getDhikrIndex([DateTime? date]) {
    final seed = getDailySeed(date);
    return seed % _dhikrs.length;
  }

  /// Get Dhikr of the Day for a given date (defaults to today).
  static DailyContentItem getDhikrOfTheDay([DateTime? date]) {
    return _dhikrs[getDhikrIndex(date)];
  }

  /// Get calculated index for Dua of the Day.
  static int getDuaIndex([DateTime? date]) {
    final seed = getDailySeed(date);
    return (seed * 7 + 3) % _duas.length;
  }

  /// Get Dua of the Day for a given date (defaults to today).
  static DailyContentItem getDuaOfTheDay([DateTime? date]) {
    return _duas[getDuaIndex(date)];
  }

  /// Get calculated index for Random Ayah.
  static int getAyahIndex([DateTime? date]) {
    final seed = getDailySeed(date);
    return (seed * 13 + 5) % _ayahs.length;
  }

  /// Get Random Ayah (Ayah of the Day) for a given date (defaults to today).
  static DailyContentItem getAyahOfTheDay([DateTime? date]) {
    return _ayahs[getAyahIndex(date)];
  }

  /// Get calculated index for Islamic Quote.
  static int getQuoteIndex([DateTime? date]) {
    final seed = getDailySeed(date);
    return (seed * 19 + 7) % _quotes.length;
  }

  /// Get Islamic Quote of the Day for a given date (defaults to today).
  static DailyContentItem getQuoteOfTheDay([DateTime? date]) {
    return _quotes[getQuoteIndex(date)];
  }
}
