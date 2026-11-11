import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'classes_screen.dart';
import 'config.dart';
import 'departements.dart';
import 'etudiants_screen.dart';
import 'helpers.dart';

class _Total {
  final String codMat;
  final double total;
  _Total(this.codMat, this.total);
}

Future<List<_Total>> _fetchTotals(int etudiantId) async {
  final res =
      await http.get(Uri.parse('$baseUrl/absences/etudiant/$etudiantId/totals'));
  if (res.statusCode != 200) {
    throw Exception('Failed to load totals (HTTP ${res.statusCode})');
  }
  final List data = jsonDecode(res.body);
  return data
      .map((e) => _Total(e['codMat'] ?? '', (e['total'] as num).toDouble()))
      .toList();
}

class AbsenceTotalsScreen extends StatefulWidget {
  final Departement? departement;
  final Classe? classe;
  final Etudiant etudiant;

  const AbsenceTotalsScreen({
    super.key,
    required this.departement,
    required this.classe,
    required this.etudiant,
  });

  @override
  State<AbsenceTotalsScreen> createState() => _AbsenceTotalsScreenState();
}

class _AbsenceTotalsScreenState extends State<AbsenceTotalsScreen> {
  late final Future<List<_Total>> _future = _fetchTotals(widget.etudiant.id);

  Widget _label(String k, String v) => Text.rich(TextSpan(children: [
        TextSpan(
          text: '$k : ',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 16),
        ),
        TextSpan(text: v, style: const TextStyle(fontSize: 16)),
      ]));

  @override
  Widget build(BuildContext context) {
    final e = widget.etudiant;
    return Scaffold(
      appBar: AppBar(title: const Text('Total absences')),
      body: FutureBuilder<List<_Total>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Erreur : ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final totals = snap.data!;
          final overallTotal =
              totals.fold<double>(0.0, (sum, item) => sum + item.total);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 24,
                runSpacing: 6,
                children: [
                  _label('Classe', widget.classe?.nomClass ?? '-'),
                  _label('Département', widget.departement?.nomDept ?? '-'),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 24,
                runSpacing: 6,
                children: [
                  _label('Etudiant', '${e.id}'),
                  _label('Nom', e.nom),
                  _label('Prénom', e.prenom),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Total général d\'absences :',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${fmtNum(overallTotal)} h',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (totals.isEmpty)
                const Center(child: Text('No absences for this student'))
              else ...[
                Center(
                  child: DataTable(
                    border: TableBorder.all(),
                    columns: const [
                      DataColumn(label: Text('CodMat')),
                      DataColumn(label: Text('Total NHA'), numeric: true),
                    ],
                    rows: totals
                        .map((t) => DataRow(cells: [
                              DataCell(Text(t.codMat)),
                              DataCell(Text(fmtNum(t.total))),
                            ]))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Absences per subject',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 260,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _LinePainter(
                      totals.map((t) => t.codMat).toList(),
                      totals.map((t) => t.total).toList(),
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

void _drawText(
  Canvas canvas,
  String s,
  double x,
  double y, {
  bool centerX = false,
  bool alignRight = false,
  bool centerY = false,
  TextStyle? style,
}) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  var dx = x;
  var dy = y;
  if (centerX) dx -= tp.width / 2;
  if (alignRight) dx -= tp.width;
  if (centerY) dy -= tp.height / 2;
  tp.paint(canvas, Offset(dx, dy));
}

// Courbe : une valeur (total NHA) par matière
class _LinePainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final Color color;

  _LinePainter(this.labels, this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 40.0, right = 16.0, top = 24.0, bottom = 32.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    final n = values.length;
    if (n == 0 || w <= 0 || h <= 0) return;

    var maxY = values.reduce((a, b) => a > b ? a : b);
    if (maxY <= 0) maxY = 1;
    maxY *= 1.15;

    const axisStyle = TextStyle(fontSize: 11, color: Colors.black54);
    final gridPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;

    // Lignes horizontales + valeurs de l'axe Y
    for (var i = 0; i <= 4; i++) {
      final y = top + h - h * i / 4;
      canvas.drawLine(Offset(left, y), Offset(left + w, y), gridPaint);
      final v = double.parse((maxY * i / 4).toStringAsFixed(1));
      _drawText(canvas, fmtNum(v), left - 6, y,
          alignRight: true, centerY: true, style: axisStyle);
    }

    double px(int i) => left + w * (i + 0.5) / n;
    double py(double v) => top + h - h * v / maxY;

    // Courbe
    final path = Path()..moveTo(px(0), py(values[0]));
    for (var i = 1; i < n; i++) {
      path.lineTo(px(i), py(values[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );

    // Points, valeurs et noms des matières
    final dotPaint = Paint()..color = color;
    for (var i = 0; i < n; i++) {
      final x = px(i);
      final y = py(values[i]);
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      _drawText(canvas, fmtNum(values[i]), x, y - 20,
          centerX: true,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87));
      _drawText(canvas, labels[i], x, top + h + 8,
          centerX: true, style: axisStyle);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}
