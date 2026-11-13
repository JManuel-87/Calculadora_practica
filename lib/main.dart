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
      theme: ThemeData(
        brightness: Brightness.dark,
        // 🎨 [DISEÑO] Color de fondo general de la app
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

  /// Convierte trigonométricas (grados a radianes)
  String _convertTrigDegreesToRadians(String expr) {
    final funcs = ['sin', 'sen', 'cos', 'tan'];
    for (final func in funcs) {
      int index = 0;
      while ((index = expr.indexOf('$func(', index)) != -1) {
        int start = index + func.length;
        int depth = 1;
        int i = start + 1;

        while (i < expr.length && depth > 0) {
          if (expr[i] == '(') depth++;
          if (expr[i] == ')') depth--;
          i++;
        }

        if (depth == 0) {
          String inner = expr.substring(start + 1, i - 1);
          inner = _convertTrigDegreesToRadians(inner);
          String standardFunc = (func == 'sen') ? 'sin' : func;
          String replacement = '$standardFunc(($inner) * 0.017453292519943295)';

          expr = expr.substring(0, index) + replacement + expr.substring(i);
          index += replacement.length;
        } else {
          break;
        }
      }
    }
    return expr;
  }

  /// Convierte log(X) a log(10, X) para que math_expressions no falle
  String _convertLogBase10(String expr) {
    int index = 0;
    while ((index = expr.indexOf('log(', index)) != -1) {
      int start = index + 3; // En '('
      int depth = 1;
      int i = start + 1;
      bool hasComma = false;

      while (i < expr.length && depth > 0) {
        if (expr[i] == '(') depth++;
        if (expr[i] == ')') depth--;
        if (expr[i] == ',' && depth == 1) hasComma = true;
        i++;
      }

      if (depth == 0) {
        if (!hasComma) {
          String inner = expr.substring(start + 1, i - 1);
          inner = _convertLogBase10(inner);
          String replacement = 'log(10, $inner)';
          expr = expr.substring(0, index) + replacement + expr.substring(i);
          index += replacement.length;
        } else {
          index = i;
        }
      } else {
        break;
      }
    }
    return expr;
  }

  void _calculateResult() {
    if (_expression.isEmpty) return;
    String finalExpression = _expression;

    // 1. Auto-cerrado de paréntesis
    int openBrackets = '('.allMatches(finalExpression).length;
    int closeBrackets = ')'.allMatches(finalExpression).length;
    while (openBrackets > closeBrackets) {
      finalExpression += ')';
      closeBrackets++;
    }

    // 2. Operadores y constantes
    finalExpression = finalExpression.replaceAll('x', '*');
    finalExpression = finalExpression.replaceAll('÷', '/');
    finalExpression = finalExpression.replaceAll('π', '3.141592653589793');
    finalExpression = finalExpression.replaceAll('√', 'sqrt');

    // 3. Conversión de logaritmos y trigonométricas
    finalExpression = _convertLogBase10(finalExpression);
    finalExpression = _convertTrigDegreesToRadians(finalExpression);

    try {
      Parser p = Parser();
      Expression exp = p.parse(finalExpression);
      ContextModel cm = ContextModel();

      // Constante de Euler 'e' para cálculos con ln
      cm.bindVariable(Variable('e'), Number(2.718281828459045));

      double eval = exp.evaluate(EvaluationType.REAL, cm);

      // Redondeo de residuos de punto flotante
      if (!eval.isNaN && !eval.isInfinite) {
        double rounded = double.parse(eval.toStringAsFixed(10));
        if ((eval - rounded).abs() < 1e-9) {
          eval = rounded;
        }
      }

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
    if ((value - 1.0).abs() < 0.0001) return "1";

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

  // 🎨 [DISEÑO] Función creadora de botones: cambia formas, bordes y sombras aquí
  Widget _buildButton(
    String text,
    Color color, {
    Color textColor = Colors.white,
    double fontSize = 16.0,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(3.0), // 👈 Margen entre botones
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            elevation: 1, // 👈 Sombra/relieve (0 para botones planos, 3 para más sombra)
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                12.0,
              ), // 👈 Curvatura de bordes
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
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            bool isLandscape = orientation == Orientation.landscape;

            return Column(
              children: <Widget>[
                // 🎨 [DISEÑO] Pantalla de resultados (Display)
                Container(
                  height: isLandscape ? 65 : 100, // Altura de la pantalla
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
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
                          _expression.isEmpty ? ' ' : _expression,
                          style: TextStyle(
                            fontSize: isLandscape ? 14.0 : 20.0,
                            color: Colors
                                .grey
                                .shade400, // Color de la expresión escrita
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          _result,
                          style: TextStyle(
                            fontSize: isLandscape ? 22.0 : 36.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Color del resultado
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Línea divisoria
                Divider(color: Colors.grey.shade800, height: 1),

                // 🎨 [DISEÑO] Panel del teclado
                Expanded(
                  child: isLandscape
                      ? Row(
                          children: [
                            // Panel científico (Horizontal)
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _buildButton(
                                          "sen(",
                                          Colors.blueGrey.shade800,
                                          fontSize: 13,
                                        ),
                                        _buildButton(
                                          "cos(",
                                          Colors.blueGrey.shade800,
                                          fontSize: 13,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _buildButton(
                                          "tan(",
                                          Colors.blueGrey.shade800,
                                          fontSize: 13,
                                        ),
                                        _buildButton(
                                          "√(",
                                          Colors.blueGrey.shade800,
                                          fontSize: 13,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _buildButton(
                                          "^",
                                          Colors.blueGrey.shade800,
                                          fontSize: 13,
                                        ),
                                        _buildButton(
                                          "π",
                                          Colors.blueGrey.shade800,
                                          fontSize: 13,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _buildButton(
                                          "log(",
                                          Colors.blueGrey.shade800,
                                          fontSize: 13,
                                        ),
                                        _buildButton(
                                          "ln(",
                                          Colors.blueGrey.shade800,
                                          fontSize: 13,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _buildButton(
                                          "(",
                                          Colors.blueGrey.shade900,
                                          fontSize: 13,
                                        ),
                                        _buildButton(
                                          ")",
                                          Colors.blueGrey.shade900,
                                          fontSize: 13,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Panel estándar (Horizontal)
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _buildButton(
                                          "C",
                                          Colors.redAccent.shade700,
                                        ),
                                        _buildButton("(", Colors.grey.shade900),
                                        _buildButton(")", Colors.grey.shade900),
                                        _buildButton(
                                          "÷",
                                          Colors.amber.shade800,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _buildButton("7", Colors.grey.shade800),
                                        _buildButton("8", Colors.grey.shade800),
                                        _buildButton("9", Colors.grey.shade800),
                                        _buildButton(
                                          "x",
                                          Colors.amber.shade800,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _buildButton("4", Colors.grey.shade800),
                                        _buildButton("5", Colors.grey.shade800),
                                        _buildButton("6", Colors.grey.shade800),
                                        _buildButton(
                                          "-",
                                          Colors.amber.shade800,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _buildButton("1", Colors.grey.shade800),
                                        _buildButton("2", Colors.grey.shade800),
                                        _buildButton("3", Colors.grey.shade800),
                                        _buildButton(
                                          "+",
                                          Colors.amber.shade800,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _buildButton("0", Colors.grey.shade800),
                                        _buildButton(".", Colors.grey.shade800),
                                        _buildButton(
                                          "S⇔D",
                                          Colors.teal.shade700,
                                          fontSize: 12,
                                        ),
                                        _buildButton("⌫", Colors.grey.shade700),
                                        _buildButton(
                                          "=",
                                          Colors.green.shade700,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          // Teclado Vertical
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  _buildButton("C", Colors.redAccent.shade700),
                                  _buildButton("(", Colors.grey.shade900),
                                  _buildButton(")", Colors.grey.shade900),
                                  _buildButton("÷", Colors.amber.shade800),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  _buildButton("7", Colors.grey.shade800),
                                  _buildButton("8", Colors.grey.shade800),
                                  _buildButton("9", Colors.grey.shade800),
                                  _buildButton("x", Colors.amber.shade800),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  _buildButton("4", Colors.grey.shade800),
                                  _buildButton("5", Colors.grey.shade800),
                                  _buildButton("6", Colors.grey.shade800),
                                  _buildButton("-", Colors.amber.shade800),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  _buildButton("1", Colors.grey.shade800),
                                  _buildButton("2", Colors.grey.shade800),
                                  _buildButton("3", Colors.grey.shade800),
                                  _buildButton("+", Colors.amber.shade800),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  _buildButton("0", Colors.grey.shade800),
                                  _buildButton(".", Colors.grey.shade800),
                                  _buildButton(
                                    "S⇔D",
                                    Colors.teal.shade700,
                                    fontSize: 13,
                                  ),
                                  _buildButton("⌫", Colors.grey.shade700),
                                  _buildButton("=", Colors.green.shade700),
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
      ),
    );
  }
}
