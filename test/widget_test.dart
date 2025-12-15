import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tika_app/app/app.dart';
import 'package:tika_app/features/splash/SplashScreen.dart';


void main() {
  testWidgets('App starts with SplashScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TikaApp());

    // Verify that the SplashScreen is displayed.
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
