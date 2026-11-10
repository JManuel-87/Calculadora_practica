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

    // 1. Auto-cerrado de paréntesis si el usuario olvidó cerrar la función
    int openBrackets = '('.allMatches(finalExpression).length;
    int closeBrackets = ')'.allMatches(finalExpression).length;
    while (openBrackets > closeBrackets) {
      finalExpression += ')';
      closeBrackets++;
    }

    // 2. Reemplazo de operadores para math_expressions
    finalExpression = finalExpression.replaceAll('x', '*');
    finalExpression = finalExpression.replaceAll('÷', '/');
    finalExpression = finalExpression.replaceAll('π', '3.141592653589793');
    finalExpression = finalExpression.replaceAll('√', 'sqrt');
    finalExpression = finalExpression.replaceAll('ln(', 'ln(');

    try {
      Parser p = Parser();
      Expression exp = p.parse(finalExpression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      setState(() {
        _result = eval.toString();
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
        padding: const EdgeInsets.all(2.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          onPressed: () => _buttonPressed(text),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
        title: const Text('Calculadora Adaptativa'),
        backgroundColor: const Color(0xFF1E1E1E),
        toolbarHeight: 40,
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          bool isLandscape = orientation == Orientation.landscape;

          return Column(
            children: <Widget>[
              // Pantalla de resultados expandida proporcionalmente
              Expanded(
                flex: isLandscape ? 2 : 3,
                child: Container(
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _expression,
                          style: TextStyle(
                            fontSize: isLandscape ? 18.0 : 24.0,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _result,
                        style: TextStyle(
                          fontSize: isLandscape ? 28.0 : 40.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: Colors.grey, height: 1),

              // Teclado adaptativo
              Expanded(
                flex: isLandscape ? 5 : 7,
                child: Row(
                  children: [
                    // Panel científico (solo en modo landscape)
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
                            Row(
                              children: [
                                _buildButton(
                                  ")",
                                  Colors.blueGrey.shade700,
                                ), // Botón de paréntesis de cierre
                                _buildButton("(", Colors.blueGrey.shade700),
                              ],
                            ),
                          ],
                        ),
                      ),
                    // Panel estándar
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
