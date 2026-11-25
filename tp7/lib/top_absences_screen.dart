import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class TopAbsencesScreen extends StatefulWidget {
  const TopAbsencesScreen({super.key});

  @override
  State<TopAbsencesScreen> createState() => _TopAbsencesScreenState();
}

class _TopAbsencesScreenState extends State<TopAbsencesScreen> {
  List<dynamic> _top3 = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final formattedUrl = baseUrl.startsWith('http') ? baseUrl : 'http://$baseUrl';
    try {
      final res = await http.get(Uri.parse('$formattedUrl/absences/top3-matieres'));
      if (res.statusCode == 200) {
        setState(() {
          _top3 = jsonDecode(res.body);
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top 3 Modules Absents')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _top3.length,
        itemBuilder: (context, i) {
          final item = _top3[i];
          return ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(item['intMat'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Code : ${item['codMat']}'),
            trailing: Text(
              '${item['totalNha']} h',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
            ),
          );
        },
      ),
    );
  }
}