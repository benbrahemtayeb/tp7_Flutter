import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class Departement {
  final int codDept;
  final String nomDept;

  Departement(this.codDept, this.nomDept);

  factory Departement.fromMap(Map<String, dynamic> m) =>
      Departement(m['codDept'], m['nomDept'] ?? '');

  @override
  bool operator ==(Object other) =>
      other is Departement && other.codDept == codDept;

  @override
  int get hashCode => codDept.hashCode;
}

Future<List<Departement>> fetchDepartements() async {
  final res = await http.get(Uri.parse('$baseUrl/departements'));
  if (res.statusCode != 200) {
    throw Exception('Failed to load departments (HTTP ${res.statusCode})');
  }
  final List data = jsonDecode(res.body);
  return data.map((e) => Departement.fromMap(e)).toList();
}
