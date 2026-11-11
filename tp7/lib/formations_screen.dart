import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'helpers.dart';

class Formation {
  final int id;
  final String nom;
  final int duree;

  Formation(this.id, this.nom, this.duree);

  factory Formation.fromMap(Map<String, dynamic> m) =>
      Formation(m['id'], m['nom'] ?? '', m['duree'] ?? 0);

  @override
  bool operator ==(Object other) => other is Formation && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

Future<List<Formation>> fetchFormations() async {
  final res = await http.get(Uri.parse('$baseUrl/formations'));
  if (res.statusCode != 200) {
    throw Exception('Failed to load formations (HTTP ${res.statusCode})');
  }
  final List data = jsonDecode(res.body);
  return data.map((e) => Formation.fromMap(e)).toList();
}

Future<void> _saveFormation(int? id, String nom, int duree) async {
  final body = jsonEncode({'nom': nom, 'duree': duree});
  final res = id == null
      ? await http.post(Uri.parse('$baseUrl/formations'),
      headers: jsonHeaders, body: body)
      : await http.put(Uri.parse('$baseUrl/formations/$id'),
      headers: jsonHeaders, body: body);
  if (res.statusCode != 200) {
    throw Exception('Save failed (HTTP ${res.statusCode})');
  }
}

Future<void> _deleteFormation(int id) async {
  final res = await http.delete(Uri.parse('$baseUrl/formations/$id'));
  if (res.statusCode != 200 && res.statusCode != 204) {
    throw Exception(res.statusCode == 500
        ? 'Cannot delete: this formation is used by students'
        : 'Delete failed (HTTP ${res.statusCode})');
  }
}

class FormationsScreen extends StatefulWidget {
  const FormationsScreen({super.key});

  @override
  State<FormationsScreen> createState() => _FormationsScreenState();
}

class _FormationsScreenState extends State<FormationsScreen> {
  late Future<List<Formation>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchFormations();
  }

  void _reload() {
    setState(() {
      _future = fetchFormations();
    });
  }

  void _msg(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _edit([Formation? f]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FormationDialog(initial: f),
    );
    if (result == null || !mounted) return;
    try {
      await _saveFormation(f?.id, result['nom'], result['duree']);
      _reload();
    } catch (e) {
      if (mounted) _msg(errText(e));
    }
  }

  Future<void> _delete(Formation f) async {
    if (!await confirmDelete(context, 'formation ${f.nom}')) return;
    try {
      await _deleteFormation(f.id);
      _reload();
    } catch (e) {
      if (mounted) _msg(errText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage formations')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Formation>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Erreur : ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(
                child: Text('No formations yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.menu_book),
              title: Text(items[i].nom),
              subtitle: Text('Duration : ${items[i].duree} h'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _edit(items[i]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _delete(items[i]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FormationDialog extends StatefulWidget {
  final Formation? initial;
  const _FormationDialog({this.initial});

  @override
  State<_FormationDialog> createState() => _FormationDialogState();
}

class _FormationDialogState extends State<_FormationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nom =
  TextEditingController(text: widget.initial?.nom ?? '');
  late final TextEditingController _duree =
  TextEditingController(text: widget.initial?.duree.toString() ?? '');

  @override
  void dispose() {
    _nom.dispose();
    _duree.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'nom': _nom.text.trim(),
      'duree': int.parse(_duree.text.trim()),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add formation' : 'Edit formation'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nom,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Name is empty' : null,
            ),
            TextFormField(
              controller: _duree,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duration (hours)'),
              validator: (v) =>
              int.tryParse((v ?? '').trim()) == null ? 'Enter a number' : null,
            ),
          ],
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