import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/features/reports/pages/take_photo_page.dart';

void main() {
  group('TakePhotoPage - Tests basiques', () {
    testWidgets('TakePhotoPage affiche les boutons de capture photo',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TakePhotoPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier la présence des boutons
      expect(find.text('Appareil photo'), findsOneWidget);
      expect(find.text('Galerie'), findsOneWidget);
    });

    testWidgets('TakePhotoPage peut lire l\'état du reportNotifier',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TakePhotoPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Si la page se construit sans erreur, elle a accès aux providers
      expect(find.byType(TakePhotoPage), findsOneWidget);
      expect(find.text('📸 Prenez une photo'), findsOneWidget);
    });
  });
}
