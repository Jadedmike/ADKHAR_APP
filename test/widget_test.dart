import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/main.dart';

/// A mock asset bundle that returns a valid 1x1 transparent PNG for image requests,
/// but delegates other file requests (like manifests) to the default rootBundle.
class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('.png') || key.endsWith('.jpg') || key.endsWith('.jpeg') || key.endsWith('.gif')) {
      return ByteData.sublistView(Uint8List.fromList([
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0,
        1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 108, 137, 0, 0, 0, 10, 73, 68, 65,
        84, 120, 156, 99, 96, 0, 0, 0, 2, 0, 1, 226, 33, 188, 51, 0, 0, 0, 0,
        73, 69, 78, 68, 174, 66, 96, 130
      ]));
    }
    return rootBundle.load(key);
  }
}

void main() {
  testWidgets('App loads and shows main title', (WidgetTester tester) async {
    // Build our app wrapping it in DefaultAssetBundle to handle mock assets
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: const AdhkarApp(),
      ),
    );

    // Verify that the serenity subtitle text exists
    expect(find.text('أذكار وأدعية تصنع السكينة'), findsOneWidget);
    // Verify that the "ابدأ" action button exists
    expect(find.text('ابدأ'), findsOneWidget);
  });
}

