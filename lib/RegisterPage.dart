import 'package:flutter/material.dart';
import 'package:project/UserDatabase.dart';
import 'main.dart';
import 'ApiUsersHelper.dart';
import 'ApiUsers.dart';
import 'LoginPage.dart';

// REGISTER PAGE
class RegisterPage extends StatefulWidget {

  const RegisterPage({super.key});
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>{
  final _formKey = GlobalKey<FormState>();

  // Controllers to capture the users credentials
  final TextEditingController _emailController = TextEditingController();     // Captures the email input
  final TextEditingController _usernameController = TextEditingController();  // Captures the username input
  final TextEditingController _passwordController = TextEditingController();     // Captures the password input

  final UsersModel usersModel = UsersModel();

  Future<void> _register() async{
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text;
      String username = _usernameController.text;
      String password = _passwordController.text;

      await usersModel.initDatabase();

      final List<Map<String, dynamic>> userExists = await usersModel.database.query('users', where: 'email = ?', whereArgs: [email.toLowerCase()]);
      List<ApiUser> apiUser = await ApiUsersHelper.fetchUsersFromApi();
      final apiUserFound = apiUser.where((user) => user.email.toLowerCase() == email.toLowerCase()).toList();

      // Checks if the user already exists in local storage for now
      if(userExists.isNotEmpty || apiUserFound.isNotEmpty){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An account already exists with this email!')),
        );
      }

      // Creates a new user and save it locally if it doesn't already exist
      else {
        User newUser = User(
          email: email.toLowerCase(),
          username: username,
          password: password,
          isLoggedIn: 1,
        );
        await usersModel.insertUser(newUser);

        User? user = await usersModel.login(email, password);

        //ApiUsersHelper.addUserToApi(username, email, password); // Adds user to API but it's a dummy api

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => BottomNavExample(user: user!)), (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text('Encrypted Messaging Register', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 15),
              Icon(
                Icons.mail_lock,
                size: 140,
                color: Colors.lightBlueAccent,
              ),
              Text(
                "Register To Begin Chatting!",
                style: TextStyle(
                    fontWeight:FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueGrey
                ),
              ),
              SizedBox(height: 15),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'example@domain.com',
                      ),
                      validator: (value) {
                        // Email validation
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        } else if (!RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null; // valid input
                      },
                    ),
                    // Username validation
                    TextFormField(
                      controller: _usernameController,  // Links this field to the username controller
                      decoration: InputDecoration(
                        labelText: 'Username',  // Adds a label inside the input field
                      ),
                      validator: (value) {
                        // Field validation logic
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null; // valid input
                      },
                    ),
                    // Password validation
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true, // hides password
                      validator: (value) {
                        // Password validation logic
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        } else if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null; // valid input
                      },
                    ),

                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _register,
                      child: Text('Register'),  // Registers the account
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ', style: TextStyle(fontStyle: FontStyle.italic)),
                        // ElevatedButton used to redirect users to Register for an account
                        TextButton(
                          onPressed: (){
                            Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (context) => LoginPage()),
                            );
                          },
                          child: Text('Login', style: TextStyle(fontStyle: FontStyle.italic)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade50,
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}