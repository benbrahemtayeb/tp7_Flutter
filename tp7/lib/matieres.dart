import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class Matiere {
  final String codMat;
  final String intMat;
  final String type;

  Matiere(this.codMat, this.intMat, {this.type = ''});

  bool get isTp {
    final t = type.trim().toUpperCase();
    if (t == 'TP') return true;
    if (t == 'COURS') return false;
    final name = '$codMat $intMat'.toUpperCase();
    return name.contains('TP') || name.contains('ATELIER');
  }

  factory Matiere.fromMap(Map<String, dynamic> m) =>
      Matiere(m['codMat'] ?? '', m['intMat'] ?? '', type: m['type'] ?? '');

  @override
  bool operator ==(Object other) => other is Matiere && other.codMat == codMat;

  @override
  int get hashCode => codMat.hashCode;
}

Future<List<Matiere>> fetchMatieres() async {
  final res = await http.get(Uri.parse('$baseUrl/matieres'));
  if (res.statusCode != 200) {
    throw Exception('Failed to load subjects (HTTP ${res.statusCode})');
  }
  final List data = jsonDecode(res.body);
  return data.map((e) => Matiere.fromMap(e)).toList();
}
