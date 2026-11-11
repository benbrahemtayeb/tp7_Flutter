import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'classes_screen.dart';
import 'config.dart';
import 'formations_screen.dart';
import 'helpers.dart';

class Etudiant {
  final int id;
  final String nom;
  final String prenom;
  final String? dateNais;
  final Classe? classe;
  final Formation? formation;

  Etudiant(this.id, this.nom, this.prenom, this.dateNais, this.classe,
      this.formation);

  factory Etudiant.fromMap(Map<String, dynamic> m) => Etudiant(
        m['id'],
        m['nom'] ?? '',
        m['prenom'] ?? '',
        m['dateNais'],
        m['classe'] is Map<String, dynamic> ? Classe.fromMap(m['classe']) : null,
        m['formation'] is Map<String, dynamic>
            ? Formation.fromMap(m['formation'])
            : null,
      );
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class EtudiantsScreen extends StatefulWidget {
  const EtudiantsScreen({super.key});

  @override
  State<EtudiantsScreen> createState() => _EtudiantsScreenState();
}

class _EtudiantsScreenState extends State<EtudiantsScreen> {
  List<Classe> _classes = [];
  List<Formation> _formations = [];
  Classe? _selected;
  List<Etudiant> _etudiants = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final classes = await fetchClasses();
      final formations = await fetchFormations();
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _formations = formations;
        _selected = classes.isNotEmpty ? classes.first : null;
      });
      await _loadEtudiants();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errText(e);
        _loading = false;
      });
    }
  }

  Future<void> _loadEtudiants() async {
    if (_selected == null) {
      if (mounted) setState(() => _etudiants = []);
      return;
    }
    final res =
        await http.get(Uri.parse('$baseUrl/etudiants/classe/${_selected!.codClass}'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load students (HTTP ${res.statusCode})');
    }
    final List data = jsonDecode(res.body);
    final list = data.map((e) => Etudiant.fromMap(e)).toList();
    if (!mounted) return;
    setState(() => _etudiants = list);
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errText(e))));
    }
  }

  Future<void> _edit([Etudiant? e]) async {
    final body = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EtudiantDialog(
        classes: _classes,
        formations: _formations,
        classe: _selected,
        initial: e,
      ),
    );
    if (body == null || !mounted) return;
    await _guard(() async {
      final uri = Uri.parse(
          e == null ? '$baseUrl/etudiants' : '$baseUrl/etudiants/${e.id}');
      final payload = jsonEncode(body);
      final res = e == null
          ? await http.post(uri, headers: jsonHeaders, body: payload)
          : await http.put(uri, headers: jsonHeaders, body: payload);
      if (res.statusCode != 200) {
        throw Exception('Save failed (HTTP ${res.statusCode})');
      }
      // Affiche la classe choisie pour que l'étudiant soit visible
      final cod = body['classe']['codClass'];
      if (!mounted) return;
      setState(() {
        _selected = _classes.firstWhere((c) => c.codClass == cod,
            orElse: () => _selected!);
      });
      await _loadEtudiants();
    });
  }

  Future<void> _delete(Etudiant e) async {
    if (!await confirmDelete(context, '${e.nom} ${e.prenom}')) return;
    if (!mounted) return;
    await _guard(() async {
      final res = await http.delete(Uri.parse('$baseUrl/etudiants/${e.id}'));
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception('Delete failed (HTTP ${res.statusCode})');
      }
      await _loadEtudiants();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage students')),
      floatingActionButton: _classes.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _edit(),
              child: const Icon(Icons.add),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erreur : $_error'))
              : _classes.isEmpty
                  ? const Center(
                      child: Text('Create a group first (Manage groups).'))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Text('Classe : ',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              DropdownButton<Classe>(
                                value: _selected,
                                hint: const Text('Code Classe'),
                                items: _classes
                                    .map((c) => DropdownMenuItem<Classe>(
                                          value: c,
                                          child: Text(c.nomClass),
                                        ))
                                    .toList(),
                                onChanged: (c) {
                                  if (c == null) return;
                                  setState(() => _selected = c);
                                  _guard(_loadEtudiants);
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _etudiants.isEmpty
                              ? const Center(child: Text('Aucun étudiant'))
                              : ListView.builder(
                                  itemCount: _etudiants.length,
                                  itemBuilder: (context, i) {
                                    final e = _etudiants[i];
                                    final details = [
                                      if (e.formation != null) e.formation!.nom,
                                      if (e.dateNais != null) e.dateNais!,
                                    ].join('  •  ');
                                    return ListTile(
                                      leading: const Icon(Icons.school),
                                      title: Text('${e.nom} ${e.prenom}'),
                                      subtitle:
                                          details.isEmpty ? null : Text(details),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _edit(e),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => _delete(e),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
    );
  }
}

class _EtudiantDialog extends StatefulWidget {
  final List<Classe> classes;
  final List<Formation> formations;
  final Classe? classe;
  final Etudiant? initial;

  const _EtudiantDialog({
    required this.classes,
    required this.formations,
    this.classe,
    this.initial,
  });

  @override
  State<_EtudiantDialog> createState() => _EtudiantDialogState();
}

class _EtudiantDialogState extends State<_EtudiantDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nom =
      TextEditingController(text: widget.initial?.nom ?? '');
  late final TextEditingController _prenom =
      TextEditingController(text: widget.initial?.prenom ?? '');
  late DateTime? _date = DateTime.tryParse(widget.initial?.dateNais ?? '');
  late Classe? _classe = widget.initial?.classe ?? widget.classe;
  late Formation? _formation = widget.initial?.formation;

  @override
  void dispose() {
    _nom.dispose();
    _prenom.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(2002),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _classe == null) return;
    Navigator.pop(context, <String, dynamic>{
      'nom': _nom.text.trim(),
      'prenom': _prenom.text.trim(),
      'dateNais': _date == null ? null : _fmtDate(_date!),
      'classe': {'codClass': _classe!.codClass},
      'formation': _formation == null ? null : {'id': _formation!.id},
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add student' : 'Edit student'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nom,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom is empty' : null,
              ),
              TextFormField(
                controller: _prenom,
                decoration: const InputDecoration(labelText: 'Prénom'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Prénom is empty' : null,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_date == null
                      ? 'Date of birth'
                      : 'Born: ${_fmtDate(_date!)}'),
                ),
              ),
              DropdownButton<Classe>(
                isExpanded: true,
                value: _classe,
                hint: const Text('Classe'),
                items: widget.classes
                    .map((c) => DropdownMenuItem<Classe>(
                          value: c,
                          child: Text(c.nomClass),
                        ))
                    .toList(),
                onChanged: (c) => setState(() => _classe = c),
              ),
              DropdownButton<Formation?>(
                isExpanded: true,
                value: _formation,
                items: [
                  const DropdownMenuItem<Formation?>(
                    value: null,
                    child: Text('Formation: none'),
                  ),
                  ...widget.formations.map((f) => DropdownMenuItem<Formation?>(
                        value: f,
                        child: Text(f.nom),
                      )),
                ],
                onChanged: (f) => setState(() => _formation = f),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
