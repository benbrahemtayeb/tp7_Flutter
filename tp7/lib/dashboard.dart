import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'absences_screen.dart';
import 'classes_screen.dart';
import 'etudiants_screen.dart';
import 'formations_screen.dart';
import 'login.dart';
import 'moyennes_screen.dart';
import 'top_absences_screen.dart';

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
                "Etudiant Manager",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(

              title: const Text("1- Moyennes des étudiants"),
              onTap: () => _go(context, const MoyennesScreen()),
            ),
            ListTile(

              title: const Text("2- Top 3 Modules Absents"),
              onTap: () => _go(context, const TopAbsencesScreen()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.groups, color: Colors.purple),
              title: const Text("Gérer les classes"),
              onTap: () => _go(context, const ClassesScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.school, color: Colors.purple),
              title: const Text("Gérer les étudiants"),
              onTap: () => _go(context, const EtudiantsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.event_busy, color: Colors.purple),
              title: const Text("Gérer les absences"),
              onTap: () => _go(context, const AbsencesScreen()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Déconnexion"),
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