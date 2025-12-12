// CSCI 4100 Project Login Page
// Rough Copy

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp()); // Entry point → runs MyApp widget
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';
  bool formSubmitted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Login")),
      // The body of the app
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header Box
              Container(
                width: 375,
                height: 150,
                color: Colors.green, // a green box
                alignment: Alignment.center,
                child: const Text(
                  "Welcome to Encrypted Messenger",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Username and Password fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Username
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Username'),
                        onChanged: (value) => setState(() => username = value),
                        enabled: !formSubmitted,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        onChanged: (value) => setState(() => password = value),
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      ElevatedButton(
                        onPressed: () {
                          setState(() => formSubmitted = true);
                          _formKey.currentState?.save();
                          // TODO: Add login logic here
                        },
                        child: const Text('Submit'),
                      ),

                      const SizedBox(height: 12),

                      // "Forgot Password" button
                      TextButton(
                        onPressed: () {
                          // Go to Forgot Password page
                        },
                        child: const Text("Forgot Password"),
                      ),

                      // "Create New Account" button
                      TextButton(
                        onPressed: () {
                          // Go to New Account page
                        },
                        child: const Text("Create New Account"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}