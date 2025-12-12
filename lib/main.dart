import 'package:flutter/material.dart';
import 'package:project/LoginPage.dart';
import 'package:project/MessageModel.dart';


import 'HomePage.dart';
import 'SearchPage.dart';
import 'ProfilePage.dart';
import 'UserDatabase.dart';
import 'Notifications.dart';
import 'ChatScreen.dart';
import 'ChatsModel.dart';


void main() async{
  // initializes all databases
  WidgetsFlutterBinding.ensureInitialized();
  Notifications.init();
  final usersModel = UsersModel();
  await usersModel.initDatabase();
  final user = await usersModel.getUser();

  // For opening the app on the home page if already logged in
  runApp(MyApp(isLoggedIn: user != null, user: user));
}



// MAIN APP
class MyApp extends StatelessWidget {
  final bool isLoggedIn; // to determine if logged in
  final User? user;

  const MyApp({super.key, required this.isLoggedIn, required this.user});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messaging App',
      navigatorKey: navigator,
      routes:{
        '/chat': (context) => ChatScreen(contact: ModalRoute.of(context)!.settings.arguments as Chat),
      },
      home: isLoggedIn ? BottomNavExample(user: user!) : LoginPage(), // if the user was already logged in, then open the application logged in, otherwise open the login page
    );
  }
}


class BottomNavExample extends StatefulWidget {
  final User user;

  const BottomNavExample({super.key, required this.user});

  @override
  _BottomNavExampleState createState() => _BottomNavExampleState();
}

class _BottomNavExampleState extends State<BottomNavExample> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  // Initializes the indexes of pages for the bottom navigation
  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(),
      SearchPage(),
      ProfilePage(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;   // Allows user to navigate between pages using the bottom navigation bar
          });
        },
        items: const [
          // The different pages in the navigation bar
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

