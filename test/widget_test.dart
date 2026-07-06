import 'package:flutter_test/flutter_test.dart';
import 'package:gabpharma_livreur/src/app.dart';

void main() {
  testWidgets('affiche la marque Livreur au démarrage', (tester) async {
    await tester.pumpWidget(const GabPharmaLivreurApp());
    expect(find.text('Espace Livreur'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Prêt pour la tournée ?'), findsOneWidget);
  });
}
