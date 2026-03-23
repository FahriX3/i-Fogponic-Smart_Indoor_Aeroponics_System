import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_fogponic/main.dart';
import 'package:my_fogponic/providers/app_provider.dart';

void main() {
  testWidgets('App smoke test - renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MyFogponicApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
