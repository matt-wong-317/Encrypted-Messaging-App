import 'package:flutter/material.dart';
import 'package:project/ApiUsers.dart';
import 'package:timezone/timezone.dart';
import 'UserDatabase.dart';
import 'ContactsModel.dart';
import 'ChatsModel.dart';
import 'MessageModel.dart';
import 'Encryption.dart';
import 'dart:io';
import 'RequestedChatScreen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Displays public accounts
class PublicAccountsPage extends StatefulWidget{

  const PublicAccountsPage({super.key});

  @override
  _PublicAccountsPageState createState() => _PublicAccountsPageState();
}

class _PublicAccountsPageState extends State<PublicAccountsPage> {
  final usersModel = UsersModel();
  final contactsModel = ContactsModel();
  final chatsModel = ChatsModel();
  final messageModel = MessageModel();
  final encryption = Encryption();


  List<dynamic> _users = [];
  bool _isLoading = true;
  User? currentUser;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeDatabases();
    loadApiUsers();
  }

  Future<void> _initializeDatabases() async {
    await usersModel.initDatabase();
    await contactsModel.initDatabase();
    await chatsModel.initDatabase();
    currentUser = await usersModel.getUser();
  }


  Future<void> loadApiUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final uri= Uri.parse(
        'https://dummyjson.com/users'
    );

    try {
      final response = await http.get(uri);
      List<ApiUser> apiUsers = [];
      // If the response is successful
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List users = data['users'] ?? [];
        setState(() { // Converts each map of users
          apiUsers = users.map((e) => ApiUser.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        });
      }

      // Gets public local users
      final allLocalUsers = await usersModel.getAllUsers();
      // Don't include current user
      final publicLocalUsers = allLocalUsers.where((user) => user.isPublic == 1 && user.id != currentUser?.id).toList();

      // Don't include duplicate API users if API user has been logged in locally
      final publicApiUsers = apiUsers.where((apiUser){
        final matchingLocalUser = allLocalUsers.firstWhere(
            (localUser) => localUser.email == apiUser.email,
            orElse: () => User(username: '', email: '', password: '', isLoggedIn: 0),
        );
        return matchingLocalUser.email.isEmpty;
      }).toList();

      setState(() {
        _users = [...publicApiUsers, ...publicLocalUsers];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Network/parse error: $e';
      });
    }
  }


  // Handles adding contacts from the search page
  Future<void> _addContact(dynamic user) async {
    if (currentUser == null) {
      return;
    }
    await contactsModel.initDatabase();
    await chatsModel.initDatabase();

    int contactId;
    String contactEmail;
    String contactName;
    String? contactPicture;
    bool localUser = user is User;

    if(localUser){
      contactId = user.id!;
      contactEmail = user.email;
      contactName = user.username;
      contactPicture = user.picture;
    }else{
      contactId = user!.id;
      contactEmail = user.email;
      contactName = user.username;
      contactPicture = null;
    }

    // To determine if the contact is already added
    final isAdded = await contactsModel.database.query(
      'contacts',
      where: 'user = ? AND contact = ?',
      whereArgs: [currentUser!.id, contactId],
    );

    if (isAdded.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("You already have ${contactName} added")));
      return;
    }

    // Adds contact  if not already added
    Contact newContact = Contact(
      user: currentUser!.id!,
      contact: contactId,
      email: contactEmail,
      name: contactName,
      picture: contactPicture,
    );

    await contactsModel.insertContact(newContact);


    // Adds a chat for the new contact
    Chat newChat = Chat(
      user: currentUser!.id!,
      contact: contactId,
      email: contactEmail,
      name: contactName,
      picture: contactPicture,
    );

    await chatsModel.insertChat(newChat);

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You added ${contactName}")));
  }

  ImageProvider? _getProfilePicture(dynamic user){
    if(user is User){
      if(user.picture == null){
        return null;
      }
      if(user.picture!.startsWith('https')){
        return NetworkImage(user.picture!);
      }else if(user.picture!.startsWith('/')){
        return FileImage(File(user.picture!));
      }
      return null;
    }else if(user is ApiUser){
      if(user.image == null){
        return null;
      }
      return NetworkImage(user.image!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Public Users", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.blue.shade50,
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Public Users',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              // Highlights the messages section
              Expanded(
                child: _isLoading ?
                Center(
                  child: CircularProgressIndicator(),
                ) : _users.isEmpty ? Center(
                    child: Text("No Public Users Found")) :
                Scrollbar(
                  interactive: true,
                  thumbVisibility: true,
                  radius: Radius.circular(10),
                  thickness: 5,
                  child: Padding(
                    padding: const EdgeInsetsGeometry.only(right: 10),
                    child: ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar( // Displays user profile picture
                                backgroundColor: Colors.lightBlueAccent,
                                backgroundImage: _getProfilePicture(user),
                                child: _getProfilePicture(user) == null ? Icon(Icons.person, color: Colors.white) : null,
                              ),
                              title: Text(user.username),
                              subtitle: Text(user.email),
                              trailing: IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () => _addContact(user),
                              ),
                            ),
                          );
                        }
                    ),
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