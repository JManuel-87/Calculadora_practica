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
  double _lastNumericResult = 0.0;
  bool _showFraction = false;

  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "C") {
        _expression = "";
        _result = "0";
        _lastNumericResult = 0.0;
        _showFraction = false;
      } else if (buttonText == "⌫") {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (buttonText == "=") {
        _calculateResult();
      } else if (buttonText == "S⇔D") {
        _showFraction = !_showFraction;
        _updateResultDisplay();
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

    // 1. Auto-cerrado de paréntesis faltantes
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

    try {
      Parser p = Parser();
      Expression exp = p.parse(finalExpression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      _lastNumericResult = eval;
      _showFraction = false;
      _updateResultDisplay();
    } catch (e) {
      setState(() {
        _result = "Error";
      });
    }
  }

  void _updateResultDisplay() {
    setState(() {
      if (_showFraction) {
        _result = _toFraction(_lastNumericResult);
      } else {
        _result = _lastNumericResult.toString();
        if (_result.endsWith('.0')) {
          _result = _result.substring(0, _result.length - 2);
        }
      }
    });
  }

  String _toFraction(double value) {
    if (value.isNaN || value.isInfinite) return "Error";
    if ((value - 3.141592653589793).abs() < 0.001) return "π";
    if ((value - 0.7071067811865476).abs() < 0.001) return "√2 / 2";
    if ((value - 0.5).abs() < 0.0001) return "1/2";
    if ((value - 0.8660254037844386).abs() < 0.0001) return "√3 / 2";

    int sign = value < 0 ? -1 : 1;
    value = value.abs();
    int whole = value.floor();
    double frac = value - whole;
    if (frac < 1e-4) return "${sign * whole}";

    int bestNum = 1;
    int bestDen = 1;
    double bestErr = 1.0;
    for (int d = 1; d <= 100; d++) {
      int n = (frac * d).round();
      double err = (frac - n / d).abs();
      if (err < bestErr) {
        bestErr = err;
        bestNum = n;
        bestDen = d;
      }
    }
    if (bestErr < 0.001 && bestDen > 1) {
      int totalNum = whole * bestDen + bestNum;
      return "${sign * totalNum}/$bestDen";
    }
    return value.toStringAsFixed(6);
  }

  Widget _buildButton(
    String text,
    Color color, {
    Color textColor = Colors.white,
    double fontSize = 15.0,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.0),
            ),
          ),
          onPressed: () => _buttonPressed(text),
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
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
        title: const Text('Calculadora Adaptativa'),
        backgroundColor: const Color(0xFF1E1E1E),
        toolbarHeight: 35,
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          bool isLandscape = orientation == Orientation.landscape;

          Widget calculatorBody = Column(
            children: <Widget>[
              // Pantalla de resultados
              Container(
                height: isLandscape ? 70 : 120,
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
                          fontSize: isLandscape ? 16.0 : 22.0,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _result,
                      style: TextStyle(
                        fontSize: isLandscape ? 24.0 : 36.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.grey, height: 1),

              // Panel de Teclado envuelto en Expanded flexible y SingleChildScrollView para cero desbordamiento
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              // Panel científico (solo en landscape)
                              if (isLandscape)
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          _buildButton(
                                            "sin(",
                                            Colors.blueGrey,
                                            fontSize: 13,
                                          ),
                                          _buildButton(
                                            "cos(",
                                            Colors.blueGrey,
                                            fontSize: 13,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _buildButton(
                                            "tan(",
                                            Colors.blueGrey,
                                            fontSize: 13,
                                          ),
                                          _buildButton(
                                            "√(",
                                            Colors.blueGrey,
                                            fontSize: 13,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _buildButton(
                                            "^",
                                            Colors.blueGrey,
                                            fontSize: 13,
                                          ),
                                          _buildButton(
                                            "π",
                                            Colors.blueGrey,
                                            fontSize: 13,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _buildButton(
                                            "log(",
                                            Colors.blueGrey,
                                            fontSize: 13,
                                          ),
                                          _buildButton(
                                            "ln(",
                                            Colors.blueGrey,
                                            fontSize: 13,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _buildButton(
                                            "(",
                                            Colors.blueGrey.shade700,
                                            fontSize: 13,
                                          ),
                                          _buildButton(
                                            ")",
                                            Colors.blueGrey.shade700,
                                            fontSize: 13,
                                          ),
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
                                        _buildButton("(", Colors.grey.shade800),
                                        _buildButton(")", Colors.grey.shade800),
                                        _buildButton(
                                          "÷",
                                          Colors.amber.shade700,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        _buildButton("7", Colors.grey.shade800),
                                        _buildButton("8", Colors.grey.shade800),
                                        _buildButton("9", Colors.grey.shade800),
                                        _buildButton(
                                          "x",
                                          Colors.amber.shade700,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        _buildButton("4", Colors.grey.shade800),
                                        _buildButton("5", Colors.grey.shade800),
                                        _buildButton("6", Colors.grey.shade800),
                                        _buildButton(
                                          "-",
                                          Colors.amber.shade700,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        _buildButton("1", Colors.grey.shade800),
                                        _buildButton("2", Colors.grey.shade800),
                                        _buildButton("3", Colors.grey.shade800),
                                        _buildButton(
                                          "+",
                                          Colors.amber.shade700,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        _buildButton("0", Colors.grey.shade800),
                                        _buildButton(".", Colors.grey.shade800),
                                        _buildButton(
                                          "S⇔D",
                                          Colors.teal.shade700,
                                          fontSize: 13,
                                        ),
                                        _buildButton("⌫", Colors.grey.shade700),
                                        _buildButton(
                                          "=",
                                          Colors.green.shade700,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );

          return calculatorBody;
        },
      ),
    );
  }
}
