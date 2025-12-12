import 'package:flutter/material.dart';
import 'package:project/ApiUsers.dart';
import 'package:project/HomePage.dart';
import 'package:project/UserDatabase.dart';
import 'main.dart';
import 'RegisterPage.dart';
import 'ApiUsersHelper.dart';

// FormPage is a StatelessWidget that contains input fields to capture user information (username and email).
class LoginPage extends StatefulWidget {

  LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}



// LOGIN PAGE

class _LoginPageState extends State<LoginPage>{
  final _formKey = GlobalKey<FormState>(); // Global Key used to access the forms states and validate input

  // Controllers to get the user input from the text fields
  final TextEditingController _emailController = TextEditingController();     // Captures the email input
  final TextEditingController _usernameController = TextEditingController();  // Captures the username input
  final TextEditingController _passwordController = TextEditingController();     // Captures the password input


  final UsersModel usersModel = UsersModel();

  Future<void> _login() async{
    if (_formKey.currentState!.validate()) {
      // Users login using email and password
      String email = _emailController.text;
      String password = _passwordController.text;

      await usersModel.initDatabase();

      List<ApiUser> apiUsers = await ApiUsersHelper.fetchUsersFromApi();
      final apiUserFound = apiUsers.where((user) => user.email.toLowerCase() == email.toLowerCase() && user.password == password);
      ApiUser? apiUser = apiUserFound.isNotEmpty ? apiUserFound.first : null;

      User? existingUser = await usersModel.getUserByEmail(email);

      if(apiUser == null && existingUser == null){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email or Password is Incorrect!')),
        );
      } else if(apiUser != null){

        User user;
        if(existingUser == null) {
          user = User(
            id: apiUser.id,
            username: apiUser.username,
            email: apiUser.email,
            password: apiUser.password,
            isLoggedIn: 1,
            picture: apiUser.image,
            isPublic: 1,
          );
        }else{
          user = existingUser;
          if(user.picture == null && apiUser.image != null){
            user.picture = apiUser.image;
            await usersModel.profilePicture(user.id!, user.picture!);
          }
          user.isLoggedIn = 1;
        }
         await usersModel.insertUser(user);
         await usersModel.LoggedIn(user.id!, 1);

         final updatedUser = await usersModel.getUserById(user.id!);

         Navigator.pushReplacement(
           context,
           MaterialPageRoute(
               builder: (context) => BottomNavExample(user: updatedUser ?? user)),
        );
      }
      // if the inputted credentials belong to a user, then proceed to the application
      else if(existingUser != null && existingUser.password == password){
        await usersModel.LoggedIn(existingUser.id!, 1);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavExample(user: existingUser)),
        );
      } else{
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email or Password is Incorrect!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text('Encrypted Messaging', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  "Login To Begin Chatting!",
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
                          // Validating that the user inputted an email
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          } else if (!RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null; // valid input
                        },
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(labelText: 'Password'),
                        obscureText: true, // Makes the password hidden
                        validator: (value) {
                          // Validating that the user inputted a password
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          } else if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null; // valid input
                        },
                      ),

                      SizedBox(height: 20),
                      // ElevatedButton used to submit the form and login
                      ElevatedButton(
                        onPressed: _login,
                        child: Text('Login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlueAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Don\'t have an account? ', style: TextStyle(fontStyle: FontStyle.italic)),
                          // ElevatedButton used to redirect users to Register for an account
                          TextButton(
                            onPressed: (){
                              Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (context) => RegisterPage()),
                              );
                            },
                            child: Text('Register', style: TextStyle(fontStyle: FontStyle.italic)),
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