import 'package:flutter/material.dart';
import 'package:project/ApiUsersHelper.dart';
import 'UserDatabase.dart';
import 'LoginPage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'SearchHistory.dart';

// PROFILE PAGE
class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UsersModel usersModel = UsersModel();
  File? _profilePicture;
  bool _isPublic = false;

  @override
  void initState(){
    super.initState();
    _loadUser();
  }

  // Used to logout
  Future<void> _logout() async{
    // Clear search history on logout for convenience
    if(widget.user.id != null){
      SearchHistory.clearHistory(widget.user.id.toString());
    }
    await usersModel.logout();
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (context) => LoginPage()), (route) => false,
    );
  }

  Future<void> _editProfilePicture() async{
    final imgPicker = ImagePicker();
    final pic = await imgPicker.pickImage(source: ImageSource.gallery);

    if(pic != null){
      setState(() {
        _profilePicture = File(pic.path);
        widget.user.picture = pic.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully Updated Profile Picture')), // Informs user that the username change was successful
      );
    }
    await usersModel.profilePicture(widget.user.id!, _profilePicture!.path);
    widget.user.picture = _profilePicture!.path;

  }

  Future<void> _loadUser() async{
    await usersModel.initDatabase();
    final currentUser = await usersModel.getUser();

    if(currentUser != null){
      setState(() {
        widget.user.username = currentUser.username;
        widget.user.email = currentUser.email;
        widget.user.picture = currentUser.picture;
        _isPublic = currentUser.isPublic == 1;

        if(currentUser.picture != null && !currentUser.picture!.startsWith('https')){
          setState(() {
            _profilePicture = File(currentUser.picture!);
          });
        }else{
          _profilePicture = null;
        }
      });
    }
  }



  Future<void> _togglePublic() async{
    final update = !_isPublic;
    setState(() {
      _isPublic = update;
    });
    await usersModel.togglePublic(widget.user.id!, _isPublic ? 1 : 0);

    widget.user.isPublic = update ? 1 : 0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(update ? 'Your profile is public!' : 'Your profile is private!')),
    );
  }

  ImageProvider? _getProfilePicture(String? imagePath){
    if(imagePath == null){
      return null;
    }
    if(imagePath.startsWith('https')){
      return NetworkImage(imagePath);
    }else{
      return FileImage(File(imagePath));
    }
  }

  @override
  Widget build(BuildContext context) {
    //********************************************* Page [3]
    //*********************************************
    // PROFILE
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.white,
      ),
      endDrawer: Drawer(
        child: ListView(
          children: [
            ListTile( // Logout button in app drawer
              leading: Icon(_isPublic ? Icons.public : Icons.public_off),
              title: Text("Profile Privacy"),
              trailing: Switch(value: _isPublic, onChanged: (value) => _togglePublic()),
            ),
            ListTile( // Logout button in app drawer
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              onTap: (){
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) {
                    // AlertDialog confirms if the user wishes to logout
                    return AlertDialog(
                      title: Text('Logout'),
                      content: Text('Are you sure you want to logout.'),
                      actions: <Widget>[
                        SimpleDialogOption(
                          child: Text('Yes'),
                          onPressed: () {
                            _logout(); // Logout if user chooses
                          },
                        ),
                        SimpleDialogOption(
                          child: Text('No'),
                          onPressed: () {
                            Navigator.pop(context);// Closes dialog
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    body: Container(
      color: Colors.blue.shade50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar( // Displays user profile picture
            radius: 50,
            backgroundColor: Colors.lightBlueAccent,
            backgroundImage: _getProfilePicture(widget.user.picture),
            child: widget.user.picture == null ? Icon(Icons.person, size: 60, color: Colors.white) : null,
          ),

          const SizedBox(height: 20),
          Text(
            widget.user.username, // Displays the user's username
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          Text(widget.user.email, style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      label: const Text('Edit Username', style: TextStyle(color: Colors.blue)),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute( // Brings user to a page to edit their username
                            builder: (context) =>
                                EditFormPage(username: widget.user.username,),
                          ),
                        );
                        if (result != null && result is Map) {
                          setState(() {
                            widget.user.username = result['username']; // Displays the updated username
                          });

                          await usersModel.editUsername(widget.user.id!, widget.user.username); // edits username and saves it on local storage
                          await ApiUsersHelper.editApiUsername(widget.user.id!, widget.user.username);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Successfully Updated Username')), // Informs user that the username change was successful
                          );
                        }
                      },
                    ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _editProfilePicture,
                icon: Icon(Icons.image, color: Colors.blue),
                label: Text('Edit Profile Picture', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

// Page to let user edit their username
class EditFormPage extends StatelessWidget {
  final String username;

  final TextEditingController _usernameController = TextEditingController();   // Controller to capture the input for the new username


  EditFormPage({required this.username}) {
    _usernameController.text = username;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),

        child: Column(
          children: <Widget>[
            TextField(
              controller: _usernameController, // user can enter their desired username
              decoration: InputDecoration(
                labelText: 'Username',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              // User confirms their new username and saves it
              onPressed: () {
                final newUsername = _usernameController.text;

                // Ensures new username isn't empty and sends it back to display it
                if (newUsername.isNotEmpty) {
                  Navigator.pop(context, {
                    'username': newUsername,
                  });
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

