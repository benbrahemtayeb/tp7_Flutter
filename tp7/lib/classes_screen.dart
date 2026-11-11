import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'departements.dart';
import 'helpers.dart';

class Classe {
  final int codClass;
  final String nomClass;
  final int nbreEtud;
  final Departement? departement;

  Classe(this.codClass, this.nomClass, [this.nbreEtud = 0, this.departement]);

  factory Classe.fromMap(Map<String, dynamic> m) => Classe(
        m['codClass'],
        m['nomClass'] ?? '',
        m['nbreEtud'] ?? 0,
        m['departement'] is Map<String, dynamic>
            ? Departement.fromMap(m['departement'])
            : null,
      );

  // Nécessaire pour que le DropdownButton retrouve la classe sélectionnée
  @override
  bool operator ==(Object other) =>
      other is Classe && other.codClass == codClass;

  @override
  int get hashCode => codClass.hashCode;
}

Future<List<Classe>> fetchClasses() async {
  final res = await http.get(Uri.parse('$baseUrl/classes'));
  if (res.statusCode != 200) {
    throw Exception('Failed to load classes (HTTP ${res.statusCode})');
  }
  final List data = jsonDecode(res.body);
  return data.map((e) => Classe.fromMap(e)).toList();
}

Future<void> _saveClasse(
    int? id, String nom, int nbreEtud, Departement? dept) async {
  final body = jsonEncode({
    'nomClass': nom,
    'nbreEtud': nbreEtud,
    'departement': dept == null ? null : {'codDept': dept.codDept},
  });
  final res = id == null
      ? await http.post(Uri.parse('$baseUrl/classes'),
          headers: jsonHeaders, body: body)
      : await http.put(Uri.parse('$baseUrl/classes/$id'),
          headers: jsonHeaders, body: body);
  if (res.statusCode != 200) {
    throw Exception('Save failed (HTTP ${res.statusCode})');
  }
}

Future<void> _deleteClasse(int id) async {
  final res = await http.delete(Uri.parse('$baseUrl/classes/$id'));
  if (res.statusCode != 200 && res.statusCode != 204) {
    throw Exception(res.statusCode == 500
        ? 'Cannot delete: this group still has students'
        : 'Delete failed (HTTP ${res.statusCode})');
  }
}

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  late Future<List<Classe>> _future;
  List<Departement> _departements = [];

  @override
  void initState() {
    super.initState();
    _future = fetchClasses();
    fetchDepartements().then((d) {
      if (mounted) setState(() => _departements = d);
    }).catchError((_) {});
  }

  void _reload() {
    setState(() {
      _future = fetchClasses();
    });
  }

  void _msg(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _edit([Classe? c]) async {
    final r = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ClasseDialog(initial: c, departements: _departements),
    );
    if (r == null || !mounted) return;
    try {
      await _saveClasse(c?.codClass, r['nom'], c?.nbreEtud ?? 0, r['dept']);
      _reload();
    } catch (e) {
      if (mounted) _msg(errText(e));
    }
  }

  Future<void> _delete(Classe c) async {
    if (!await confirmDelete(context, 'group ${c.nomClass}')) return;
    try {
      await _deleteClasse(c.codClass);
      _reload();
    } catch (e) {
      if (mounted) _msg(errText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage groups')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Classe>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Erreur : ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final classes = snap.data!;
          if (classes.isEmpty) {
            return const Center(child: Text('No groups yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, i) {
              final c = classes[i];
              final dept = c.departement == null ? '' : '  •  ${c.departement!.nomDept}';
              return ListTile(
                leading: const Icon(Icons.groups),
                title: Text(c.nomClass),
                subtitle: Text('Code : ${c.codClass}$dept'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _edit(c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _delete(c),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ClasseDialog extends StatefulWidget {
  final Classe? initial;
  final List<Departement> departements;
  const _ClasseDialog({this.initial, required this.departements});

  @override
  State<_ClasseDialog> createState() => _ClasseDialogState();
}

class _ClasseDialogState extends State<_ClasseDialog> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial?.nomClass ?? '');
  late Departement? _dept =
      widget.departements.contains(widget.initial?.departement)
          ? widget.initial?.departement
          : null;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add group' : 'Edit group'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _c,
            autofocus: true,
            decoration:
                const InputDecoration(labelText: 'Group name (e.g. DSI24)'),
          ),
          const SizedBox(height: 12),
          DropdownButton<Departement?>(
            isExpanded: true,
            value: _dept,
            items: [
              const DropdownMenuItem<Departement?>(
                value: null,
                child: Text('Département: none'),
              ),
              ...widget.departements.map((d) => DropdownMenuItem<Departement?>(
                    value: d,
                    child: Text(d.nomDept),
                  )),
            ],
            onChanged: (d) => setState(() => _dept = d),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final v = _c.text.trim();
            if (v.isNotEmpty) {
              Navigator.pop(context, <String, dynamic>{'nom': v, 'dept': _dept});
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
