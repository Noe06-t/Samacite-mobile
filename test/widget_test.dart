import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/features/auth/pages/register_page.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('RegisterPage displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame with ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RegisterPage(),
        ),
      ),
    );

    // Verify that the RegisterPage is displayed
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Nom complet'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('S\'inscrire'), findsOneWidget);
  });
}
