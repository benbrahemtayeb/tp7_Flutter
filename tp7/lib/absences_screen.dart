import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'absence_totals_screen.dart';
import 'classes_screen.dart';
import 'config.dart';
import 'departements.dart';
import 'etudiants_screen.dart';
import 'helpers.dart';
import 'matieres.dart';

class Absence {
  final int id;
  final String dateA;
  final String codMat;
  final double nha;

  Absence(this.id, this.dateA, this.codMat, this.nha);

  factory Absence.fromMap(Map<String, dynamic> m) => Absence(
        m['id'],
        m['dateA'] ?? '',
        m['matiere'] is Map ? (m['matiere']['codMat'] ?? '') : '',
        (m['nha'] as num?)?.toDouble() ?? 0,
      );
}

Future<List<Classe>> _fetchClassesByDept(int codDept) async {
  final res = await http.get(Uri.parse('$baseUrl/classes/departement/$codDept'));
  if (res.statusCode != 200) {
    throw Exception('Failed to load classes (HTTP ${res.statusCode})');
  }
  final List data = jsonDecode(res.body);
  return data.map((e) => Classe.fromMap(e)).toList();
}

Future<List<Etudiant>> _fetchEtudiants(int codClass) async {
  final res = await http.get(Uri.parse('$baseUrl/etudiants/classe/$codClass'));
  if (res.statusCode != 200) {
    throw Exception('Failed to load students (HTTP ${res.statusCode})');
  }
  final List data = jsonDecode(res.body);
  return data.map((e) => Etudiant.fromMap(e)).toList();
}

Future<List<Absence>> _fetchAbsences(int etudiantId) async {
  final res = await http.get(Uri.parse('$baseUrl/absences/etudiant/$etudiantId'));
  if (res.statusCode != 200) {
    throw Exception('Failed to load absences (HTTP ${res.statusCode})');
  }
  final List data = jsonDecode(res.body);
  final list = data.map((e) => Absence.fromMap(e)).toList();
  list.sort((a, b) => b.dateA.compareTo(a.dateA)); // plus récentes d'abord
  return list;
}

Widget _pick<T>({
  required String label,
  required T? value,
  required List<T> items,
  required String Function(T) text,
  required ValueChanged<T?> onChanged,
}) {
  return InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        isExpanded: true,
        value: value,
        items: items
            .map((e) => DropdownMenuItem<T>(value: e, child: Text(text(e))))
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

class AbsencesScreen extends StatefulWidget {
  const AbsencesScreen({super.key});

  @override
  State<AbsencesScreen> createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends State<AbsencesScreen> {
  List<Departement> _departements = [];
  List<Classe> _classes = [];
  List<Etudiant> _etudiants = [];
  List<Absence> _absences = [];
  List<Matiere> _matieres = [];
  Departement? _dept;
  Classe? _classe;
  Etudiant? _etudiant;

  final _nomC = TextEditingController();
  final _prenomC = TextEditingController();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _nomC.dispose();
    _prenomC.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _departements = await fetchDepartements();
      _matieres = await fetchMatieres();
      _dept = _departements.isNotEmpty ? _departements.first : null;
      await _loadClasses();
    } catch (e) {
      _error = errText(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  // Chaque niveau recharge le niveau suivant (département -> classes -> étudiants -> absences)
  Future<void> _loadClasses() async {
    _classes = _dept == null ? [] : await _fetchClassesByDept(_dept!.codDept);
    _classe = _classes.isNotEmpty ? _classes.first : null;
    await _loadEtudiants();
  }

  Future<void> _loadEtudiants() async {
    _etudiants =
        _classe == null ? [] : await _fetchEtudiants(_classe!.codClass);
    _etudiant = _etudiants.isNotEmpty ? _etudiants.first : null;
    await _loadAbsences();
  }

  Future<void> _loadAbsences() async {
    _absences = _etudiant == null ? [] : await _fetchAbsences(_etudiant!.id);
    _nomC.text = _etudiant?.nom ?? '';
    _prenomC.text = _etudiant?.prenom ?? '';
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errText(e))));
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _edit([Absence? a]) async {
    final e = _etudiant;
    if (e == null) return;
    if (_matieres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No subjects (matières) defined')));
      return;
    }
    final body = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) =>
          _AbsenceDialog(matieres: _matieres, etudiantId: e.id, initial: a),
    );
    if (body == null || !mounted) return;
    await _run(() async {
      final uri = Uri.parse(
          a == null ? '$baseUrl/absences' : '$baseUrl/absences/${a.id}');
      final payload = jsonEncode(body);
      final res = a == null
          ? await http.post(uri, headers: jsonHeaders, body: payload)
          : await http.put(uri, headers: jsonHeaders, body: payload);
      if (res.statusCode != 200) {
        final err = res.body.isNotEmpty ? res.body : 'Save failed (HTTP ${res.statusCode})';
        throw Exception(err);
      }
      await _loadAbsences();
    });
  }

  Future<void> _delete(Absence a) async {
    if (!await confirmDelete(
        context, 'the absence of ${dmy(a.dateA)} (${a.codMat})')) {
      return;
    }
    if (!mounted) return;
    await _run(() async {
      final res = await http.delete(Uri.parse('$baseUrl/absences/${a.id}'));
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception('Delete failed (HTTP ${res.statusCode})');
      }
      await _loadAbsences();
    });
  }

  Widget _table() {
    if (_etudiant == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('Select a student')),
      );
    }
    if (_absences.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No absences')),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('DateA')),
          DataColumn(label: Text('CodMat')),
          DataColumn(label: Text('NHA'), numeric: true),
          DataColumn(label: Text('')),
        ],
        rows: _absences
            .map((a) => DataRow(cells: [
                  DataCell(Text(dmy(a.dateA))),
                  DataCell(Text(a.codMat)),
                  DataCell(Text(fmtNum(a.nha))),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit),
                        onPressed: () => _edit(a),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _delete(a),
                      ),
                    ],
                  )),
                ]))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage absences'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Total absences',
            onPressed: _etudiant == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AbsenceTotalsScreen(
                          departement: _dept,
                          classe: _classe,
                          etudiant: _etudiant!,
                        ),
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: _etudiant == null
          ? null
          : FloatingActionButton(
              onPressed: () => _edit(),
              child: const Icon(Icons.add),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erreur : $_error'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  children: [
                    _pick<Departement>(
                      label: 'Département',
                      value: _dept,
                      items: _departements,
                      text: (d) => d.nomDept,
                      onChanged: (d) {
                        setState(() => _dept = d);
                        _run(_loadClasses);
                      },
                    ),
                    const SizedBox(height: 12),
                    _pick<Classe>(
                      label: 'Classe',
                      value: _classe,
                      items: _classes,
                      text: (c) => c.nomClass,
                      onChanged: (c) {
                        setState(() => _classe = c);
                        _run(_loadEtudiants);
                      },
                    ),
                    const SizedBox(height: 12),
                    _pick<Etudiant>(
                      label: 'Etudiant',
                      value: _etudiant,
                      items: _etudiants,
                      text: (e) => '${e.id} - ${e.nom} ${e.prenom}',
                      onChanged: (e) {
                        setState(() => _etudiant = e);
                        _run(_loadAbsences);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nomC,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Nom',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _prenomC,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Prénom',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Absences',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    _table(),
                  ],
                ),
    );
  }
}

class _AbsenceDialog extends StatefulWidget {
  final List<Matiere> matieres;
  final int etudiantId;
  final Absence? initial;

  const _AbsenceDialog({
    required this.matieres,
    required this.etudiantId,
    this.initial,
  });

  @override
  State<_AbsenceDialog> createState() => _AbsenceDialogState();
}

class _AbsenceDialogState extends State<_AbsenceDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date =
      DateTime.tryParse(widget.initial?.dateA ?? '') ?? DateTime.now();
  late Matiere _mat = widget.matieres.firstWhere(
    (m) => m.codMat == widget.initial?.codMat,
    orElse: () => widget.matieres.first,
  );
  late final TextEditingController _nha = TextEditingController(
      text: widget.initial == null
          ? fmtNum(_mat.isTp ? 3.0 : 1.5)
          : fmtNum(widget.initial!.nha));

  @override
  void dispose() {
    _nha.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null && mounted) setState(() => _date = d);
  }

  double? _parseNha(String? v) =>
      double.tryParse((v ?? '').trim().replaceAll(',', '.'));

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, <String, dynamic>{
      'dateA': isoDate(_date),
      'nha': _parseNha(_nha.text),
      'matiere': {'codMat': _mat.codMat},
      'etudiant': {'id': widget.etudiantId},
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTp = _mat.isTp;
    final maxHours = isTp ? 3.0 : 1.5;

    return AlertDialog(
      title: Text(widget.initial == null ? 'Ajouter une absence' : 'Modifier l\'absence'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text('Date: ${dmy(isoDate(_date))}'),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Matiere>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Matière',
                  border: OutlineInputBorder(),
                ),
                value: _mat,
                items: widget.matieres
                    .map((m) => DropdownMenuItem<Matiere>(
                          value: m,
                          child: Text('${m.codMat} - ${m.intMat}'),
                        ))
                    .toList(),
                onChanged: (m) {
                  if (m != null) {
                    setState(() {
                      _mat = m;
                      if (widget.initial == null) {
                        _nha.text = fmtNum(m.isTp ? 3.0 : 1.5);
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Chip(
                avatar: Icon(
                  isTp ? Icons.computer : Icons.menu_book,
                  size: 18,
                  color: isTp ? Colors.deepPurple : Colors.blue,
                ),
                label: Text(
                  isTp ? 'Séance de TP (3h max)' : 'Séance de Cours (1.5h max)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: (isTp ? Colors.deepPurple : Colors.blue).withOpacity(0.1),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nha,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Nombre d\'heures (NHA)',
                  hintText: isTp ? 'ex: 3.0' : 'ex: 1.5',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = _parseNha(v);
                  if (n == null || n <= 0) {
                    return 'Veuillez saisir un nombre d\'heures valide (> 0)';
                  }
                  if (n > maxHours) {
                    return isTp
                        ? 'Pour un TP, la durée max est de 3h'
                        : 'Pour un cours, la durée max est de 1.5h (1h30)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Enregistrer')),
      ],
    );
  }
}
