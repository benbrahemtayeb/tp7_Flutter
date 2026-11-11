import 'package:flutter/material.dart';

const jsonHeaders = {'Content-Type': 'application/json'};

String errText(Object e) => e.toString().replaceFirst('Exception: ', '');

// 1.5 -> "1.5", 3.0 -> "3"
String fmtNum(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

// "2025-11-11" -> "11-11-2025"
String dmy(String iso) {
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}-${p[1]}-${p[0]}' : iso;
}

// DateTime -> "2025-11-11"
String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<bool> confirmDelete(BuildContext context, String what) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete'),
      content: Text('Delete $what?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
