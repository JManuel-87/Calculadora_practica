import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora/main.dart';

void main() {
  testWidgets('Calculadora smoke test', (WidgetTester tester) async {
    // Carga nuestra aplicación en la prueba
    await tester.pumpWidget(const CalculadoraApp());

    // Verifica que el título principal de la calculadora aparezca en pantalla
    expect(find.text('Calculadora Científica'), findsOneWidget);
  });
}
