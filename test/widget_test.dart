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

    // Attendre que le build soit terminé
    await tester.pumpAndSettle();

    // Verify that the RegisterPage is displayed
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Prénom'), findsOneWidget);
    expect(find.text('Nom'), findsOneWidget);
    expect(find.text('Téléphone'), findsOneWidget);
    expect(find.textContaining('Adresse e-mail'), findsOneWidget);
    expect(find.text('S\'inscrire'), findsOneWidget);
  });
}
