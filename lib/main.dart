import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(const CalculadoraApp());
}

class CalculadoraApp extends StatelessWidget {
  const CalculadoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculadora Adaptativa',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const CalculadoraHome(),
    );
  }
}

class CalculadoraHome extends StatefulWidget {
  const CalculadoraHome({super.key});

  @override
  State<CalculadoraHome> createState() => _CalculadoraHomeState();
}

class _CalculadoraHomeState extends State<CalculadoraHome> {
  String _expression = "";
  String _result = "0";

  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "C") {
        _expression = "";
        _result = "0";
      } else if (buttonText == "⌫") {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (buttonText == "=") {
        _calculateResult();
      } else if (buttonText == "+/-") {
        if (_expression.isNotEmpty) {
          if (_expression.startsWith("-")) {
            _expression = _expression.substring(1);
          } else {
            _expression = "-$_expression";
          }
        }
      } else {
        if (_expression == "0" || _result == "Error") {
          _expression = buttonText;
        } else {
          _expression += buttonText;
        }
      }
    });
  }

  void _calculateResult() {
    String finalExpression = _expression;
    // Adaptamos los símbolos visuales para que la librería los procese correctamente
    finalExpression = finalExpression.replaceAll('x', '*');
    finalExpression = finalExpression.replaceAll('÷', '/');
    finalExpression = finalExpression.replaceAll('π', '3.141592653589793');
    finalExpression = finalExpression.replaceAll('√', 'sqrt');

    try {
      Parser p = Parser();
      Expression exp = p.parse(finalExpression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      setState(() {
        _result = eval.toString();
        // Limpiamos decimales innecesarios si el resultado es entero
        if (_result.endsWith('.0')) {
          _result = _result.substring(0, _result.length - 2);
        }
      });
    } catch (e) {
      setState(() {
        _result = "Error";
      });
    }
  }

  Widget _buildButton(
    String text,
    Color color, {
    Color textColor = Colors.white,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onPressed: () => _buttonPressed(text),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Adaptativa (Práctica 1)'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          bool isLandscape = orientation == Orientation.landscape;

          return Column(
            children: <Widget>[
              // Pantalla de visualización (Expresión ingresada y Resultado)
              Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _expression,
                      style: const TextStyle(
                        fontSize: 22.0,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _result,
                      style: const TextStyle(
                        fontSize: 40.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.grey),

              // Panel adaptable: Muestra funciones científicas a la izquierda si está en horizontal
              Expanded(
                child: Row(
                  children: [
                    if (isLandscape)
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildButton("sin(", Colors.blueGrey),
                                _buildButton("cos(", Colors.blueGrey),
                              ],
                            ),
                            Row(
                              children: [
                                _buildButton("tan(", Colors.blueGrey),
                                _buildButton("√(", Colors.blueGrey),
                              ],
                            ),
                            Row(
                              children: [
                                _buildButton("^", Colors.blueGrey),
                                _buildButton("π", Colors.blueGrey),
                              ],
                            ),
                            Row(
                              children: [
                                _buildButton("log(", Colors.blueGrey),
                                _buildButton("ln(", Colors.blueGrey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    // Panel de teclado estándar
                    Expanded(
                      flex: isLandscape ? 2 : 1,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildButton("C", Colors.redAccent),
                              _buildButton("+/-", Colors.grey.shade800),
                              _buildButton("(", Colors.grey.shade800),
                              _buildButton("÷", Colors.amber.shade700),
                            ],
                          ),
                          Row(
                            children: [
                              _buildButton("7", Colors.grey.shade800),
                              _buildButton("8", Colors.grey.shade800),
                              _buildButton("9", Colors.grey.shade800),
                              _buildButton("x", Colors.amber.shade700),
                            ],
                          ),
                          Row(
                            children: [
                              _buildButton("4", Colors.grey.shade800),
                              _buildButton("5", Colors.grey.shade800),
                              _buildButton("6", Colors.grey.shade800),
                              _buildButton("-", Colors.amber.shade700),
                            ],
                          ),
                          Row(
                            children: [
                              _buildButton("1", Colors.grey.shade800),
                              _buildButton("2", Colors.grey.shade800),
                              _buildButton("3", Colors.grey.shade800),
                              _buildButton("+", Colors.amber.shade700),
                            ],
                          ),
                          Row(
                            children: [
                              _buildButton("0", Colors.grey.shade800),
                              _buildButton(".", Colors.grey.shade800),
                              _buildButton("⌫", Colors.grey.shade700),
                              _buildButton("=", Colors.green.shade700),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
