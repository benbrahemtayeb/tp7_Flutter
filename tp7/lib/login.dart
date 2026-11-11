import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'dashboard.dart';
import 'register.dart';
import 'user.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final String url = "$baseUrl/login";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<User> save(String email, String password) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email.trim(), 'password': password}),
    );
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return User.fromMap(jsonDecode(res.body));
    } else if (res.statusCode == 401) {
      throw Exception('Invalid email or password.');
    } else {
      throw Exception('Server error (${res.statusCode})');
    }
  }

  Future<void> handleSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      await save(_emailController.text, _passwordController.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    } catch (e) {
      debugPrint("Login error: $e");
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login failed: $msg',
            style: const TextStyle(fontSize: 16.0),
          ),
          duration: const Duration(seconds: 5),
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
                          "Login",
                          style: GoogleFonts.oswald(
                            fontWeight: FontWeight.w700,
                            fontSize: 50,
                            color: Colors.black45,
                          ),
                        ),
                        _label("Email"),
                        _field(_emailController, 'Email is Empty'),
                        const SizedBox(height: 30),
                        _label("Password"),
                        _field(_passwordController, 'Password is Empty', obscure: true),
                        const SizedBox(height: 30),
                        Center(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const Register()),
                              );
                            },
                            child: const Text(
                              "Dont have Account ?",
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
                      backgroundColor: const Color.fromRGBO(233, 65, 82, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: handleSignIn,
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
