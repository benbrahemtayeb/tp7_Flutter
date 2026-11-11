import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'user.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final String url = "$baseUrl/register";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<User> register(String email, String password) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      return User.fromMap(jsonDecode(res.body));
    } else {
      throw Exception('HTTP ${res.statusCode} : ${res.body}');
    }
  }

  Future<void> handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await register(_emailController.text, _passwordController.text);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Compte créé, tu peux te connecter'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Inscription impossible : $e'),
          duration: const Duration(seconds: 8),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _label(String text) => Align(
        alignment: Alignment.topLeft,
        child: Text(
          text,
          style: GoogleFonts.roboto(fontSize: 22, color: Colors.purple),
        ),
      );

  Widget _field(TextEditingController c, String emptyMsg, {bool obscure = false}) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      validator: (String? value) {
        if (value == null || value.isEmpty) return emptyMsg;
        return null;
      },
      style: TextStyle(fontSize: 20, color: Colors.blueGrey.shade700),
      decoration: const InputDecoration(
        errorStyle: TextStyle(fontSize: 14, color: Colors.black),
        border: OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                Container(
                  height: 520.0,
                  width: 340.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBDE5C5),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        Text(
                          "Register",
                          style: GoogleFonts.pacifico(fontSize: 36, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        _label("Email"),
                        _field(_emailController, 'Email is Empty'),
                        const SizedBox(height: 30),
                        _label("Password"),
                        _field(_passwordController, 'Password is Empty', obscure: true),
                        const SizedBox(height: 30),
                        Center(
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              "Already have Account ?",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90,
                  width: 90,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: handleRegister,
                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
