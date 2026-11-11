import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'absences_screen.dart';
import 'classes_screen.dart';
import 'etudiants_screen.dart';
import 'formations_screen.dart';
import 'login.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  void _go(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8A5DD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8A5DD),
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.purple,
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
              child: const Text(
                "Exercise for groups :\nDSI33 and DSI31",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.groups, color: Colors.deepOrange),
              title: const Text("Manage groups"),
              onTap: () => _go(context, const ClassesScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.school, color: Colors.deepOrange),
              title: const Text("Manage students"),
              onTap: () => _go(context, const EtudiantsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.deepOrange),
              title: const Text("Manage formations"),
              onTap: () => _go(context, const FormationsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.event_busy, color: Colors.deepOrange),
              title: const Text("Manage absences"),
              onTap: () => _go(context, const AbsencesScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.deepOrange),
              title: const Text("Manage teachers"),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not implemented yet')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.deepOrange),
              title: const Text("Logout"),
              onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
                (route) => false,
              ),
            ),
          ],
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            "Dashboard",
            style: GoogleFonts.pacifico(fontSize: 40, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
