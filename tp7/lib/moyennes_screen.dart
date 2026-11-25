import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class MoyennesScreen extends StatefulWidget {
  const MoyennesScreen({super.key});

  @override
  State<MoyennesScreen> createState() => _MoyennesScreenState();
}

class _MoyennesScreenState extends State<MoyennesScreen> {
  List<dynamic> _classes = [];
  Map<String, dynamic>? _selectedClasse;
  List<dynamic> _etudiants = [];
  bool _loadingClasses = true;
  bool _loadingMoyennes = false;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }
  Future<void> _fetchClasses() async {
    final formattedUrl = baseUrl.startsWith('http') ? baseUrl : 'http://$baseUrl';
    try {
      final res = await http.get(Uri.parse('$formattedUrl/classes'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _classes = data;
          _loadingClasses = false;
          if (_classes.isNotEmpty) {
            _selectedClasse = _classes.first;
            _fetchMoyennes(_selectedClasse!['codClass']);
          }
        });
      }
    } catch (e) {
      setState(() => _loadingClasses = false);
    }
  }

  Future<void> _fetchMoyennes(int codClass) async {
    setState(() => _loadingMoyennes = true);
    final formattedUrl = baseUrl.startsWith('http') ? baseUrl : 'http://$baseUrl';
    try {
      final res = await http.get(Uri.parse('$formattedUrl/notes/classe/$codClass/moyennes'));
      if (res.statusCode == 200) {
        setState(() {
          _etudiants = jsonDecode(res.body);
          _loadingMoyennes = false;
        });
      }
    } catch (e) {
      setState(() => _loadingMoyennes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deptName = _selectedClasse?['departement']?['nomDept'] ?? 'TI';

    return Scaffold(
      appBar: AppBar(title: const Text('Moyennes des étudiants')),
      body: _loadingClasses
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Classe : ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                DropdownButton<Map<String, dynamic>>(
                  value: _selectedClasse,
                  items: _classes.map((c) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: c as Map<String, dynamic>,
                      child: Text(
                        c['nomClass'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedClasse = val);
                      _fetchMoyennes(val['codClass']);
                    }
                  },
                ),
                const Spacer(),
                Text('Département : $deptName',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Date : 25-11-2026', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),

            Expanded(
              child: _loadingMoyennes
                  ? const Center(child: CircularProgressIndicator())
                  : _etudiants.isEmpty
                  ? const Center(child: Text('Aucun étudiant dans cette classe'))
                  : SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Prenom', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Moyenne', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _etudiants.map((e) {
                      return DataRow(cells: [
                        DataCell(Text(e['nom'] ?? '')),
                        DataCell(Text(e['prenom'] ?? '')),
                        DataCell(
                          Text(
                            e['moyenne'] != null ? e['moyenne'].toString() : '...',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}