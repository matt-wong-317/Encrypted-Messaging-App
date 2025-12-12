import 'package:flutter/material.dart';
import 'package:project/ChatsModel.dart';
import 'UserDatabase.dart';
import 'ContactsModel.dart';
import 'ApiUsers.dart';
import 'ApiUsersHelper.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'PublicAccountsPage.dart';
import 'SearchHistory.dart';

// SEARCH PAGE
class SearchPage extends StatefulWidget {

  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<String> _history = []; // Stores search history
  final SearchController _searchController = SearchController(); // controller to contain what the user types in the search bear

  final ContactsModel contactsModel = ContactsModel(); // For adding other contacts
  final ChatsModel chatsModel = ChatsModel(); // For adding chats

  final UsersModel usersModel = UsersModel(); // To add contacts only for a specific user
  User? searched;
  ApiUser? apiSearched;

  bool submittedSearch = false;
  bool _isLoading = false;
  User? currentUser;

  @override
  void initState(){
    super.initState();
    _initializeDatabases();
  }

  Future<void> _initializeDatabases() async{
    await usersModel.initDatabase();
    await contactsModel.initDatabase();
    await chatsModel.initDatabase();
    currentUser = await usersModel.getUser();

    if(currentUser != null){
      setState(() {
        _history = SearchHistory.getHistory(currentUser!.id.toString());
      });
    }


  }



  // Handles searching
  Future<void> _search(String search, String apiSearch) async{
    if(search.isEmpty){
      setState((){
        searched = null;
        apiSearched = null;
        submittedSearch = false;
        _isLoading = false;
      });
      return;
    }

    submittedSearch = true;
    _isLoading = true;
    setState(() {});

    search = search.toLowerCase();
    apiSearch = apiSearch.toLowerCase();




    // Searching for Users
    try{
      // Searches for local accounts
      final List<Map<String, dynamic>> maps = await usersModel.database.query('users', where: 'email = ?', whereArgs: [search]);
      final apiUser = await ApiUsersHelper.fetchUsersByEmail(search); // Searching for api users
      setState(() {
        searched = maps.isNotEmpty ? User.fromMap(maps.first) : null;
        apiSearched = apiUser;
        _isLoading = false;
      });
    }catch(_){
      setState(() {
        searched = null;
        apiSearched = null;
        _isLoading = false;
      });
    }

  }


  // Handles adding contacts from the search page
  Future<void> _addContact() async{
    if(currentUser == null){
      return;
    }
    await contactsModel.initDatabase();


    User? localUser = searched;
    ApiUser? apiUser = apiSearched;

    int contactId;
    String contactEmail;
    String contactName;
    String? contactPicture;

    if(localUser != null){
      contactId = localUser.id!;
      contactEmail = localUser.email;
      contactName = localUser.username;
      contactPicture = localUser.picture;
    }else{
      contactId = apiUser!.id;
      contactEmail = apiUser.email;
      contactName = apiUser.username;
      contactPicture = apiUser.image;
    }


    // To determine if the contact is already added
    final isAdded = await contactsModel.database.query(
      'contacts',
      where: 'user = ? AND contact = ?',
      whereArgs: [currentUser!.id, contactId],
    );

    if(isAdded.isNotEmpty){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You already have ${contactName} added")));
      return;
    }



    // Adds contact  if not already added
    Contact newContact = Contact(user: currentUser!.id!, contact: contactId, email: contactEmail, name: contactName, picture: contactPicture);
    await contactsModel.insertContact(newContact);

    // Adds a chat for the new contact
    Chat newChat = Chat(user: currentUser!.id!, contact: contactId, email: contactEmail, name: contactName, picture: contactPicture);
    await chatsModel.insertChat(newChat);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You added ${contactName}")));
  }


  ImageProvider? _getProfilePicture(User? localUser, ApiUser? apiUser){
    if(localUser != null && localUser.picture != null){
      if(localUser.picture!.startsWith('https')){
        return NetworkImage(localUser.picture!);
      }else if(localUser.picture!.startsWith('/') || localUser.picture!.contains('/')){
        return FileImage(File(localUser.picture!));
      }
    } else if(apiUser != null && apiUser.image != null){
      return NetworkImage(apiUser.image!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.blue.shade50,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            SearchAnchor(
              builder: (BuildContext context, SearchController controller) {
                return SearchBar(
                  controller: _searchController,
                  hintText: 'Search for Email', // search users by email
                  padding: const WidgetStatePropertyAll<EdgeInsets>(
                    EdgeInsets.symmetric(horizontal: 20),
                  ),
                  leading: const Icon(Icons.search),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        SearchHistory.addHistory(currentUser!.id.toString(), value);
                        _history = SearchHistory.getHistory(currentUser!.id.toString());
                        // _history.remove(value); // prevents duplicate searches in history
                        // _history.insert(0, value); // displays search history
                      });
                      _search(value, value);
                    }
                  },
                );
              },
              suggestionsBuilder:
                  (BuildContext context, SearchController controller) {
                return <Widget>[];
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Search Results", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.left),
                TextButton(
                    child: Text(
                        'Public Users',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PublicAccountsPage()),
                      );
                    }
                ),
              ],
            ),

            // Informs the user if there are no users with the email they searched, or displays the other user if there is
            submittedSearch ?
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if(_isLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if(searched != null && apiSearched != null)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.lightBlueAccent,
                            backgroundImage: _getProfilePicture(searched, null), // Contact profile picture
                            child: _getProfilePicture(searched, null) == null ? Icon(Icons.person, color: Colors.white) : null,
                          ),
                          title: Text(searched!.username),
                          subtitle: Text(searched!.email),
                          trailing: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: _addContact,
                          ),
                        ),
                      )
                    else if(searched != null && apiSearched == null)
                        Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.lightBlueAccent,
                              backgroundImage: _getProfilePicture(searched, null), // Contact profile picture
                              child: _getProfilePicture(searched, null) == null ? Icon(Icons.person, color: Colors.white) : null,
                            ),
                            title: Text(searched!.username),
                            subtitle: Text(searched!.email),
                            trailing: IconButton(
                              icon: Icon(Icons.add),
                              onPressed: _addContact,
                            ),
                          ),
                        )
                      else if(apiSearched != null && searched == null)
                          Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.lightBlueAccent,
                                backgroundImage: _getProfilePicture(null, apiSearched), // Contact profile picture
                                child: _getProfilePicture(null, apiSearched) == null ? Icon(Icons.person, color: Colors.white) : null,
                              ),
                              title: Text(apiSearched!.username),
                              subtitle: Text(apiSearched!.email),
                              trailing: IconButton(
                                icon: Icon(Icons.add),
                                onPressed: _addContact,
                              ),
                            ),
                          )
                        else if(searched == null && apiSearched == null)
                            Center(child: Text("No users with this email")),
                  ],
                ),
              ),

            ) : Container(),

            const Text("Recently Searched", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.left),
            const SizedBox(height: 15),

            Expanded(
              flex: 2,
              // Allows user to click on search history and have it put back in the search bar
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final searchInput = _history[index];
                  return ListTile(
                    leading: Icon(Icons.history),
                    title: Text(searchInput),
                    onTap: () {
                      _searchController.text = searchInput;
                    },
                    // To delete items in the search history
                    trailing: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          SearchHistory.removeSearchResult(currentUser!.id.toString(), index);
                          _history = SearchHistory.getHistory(currentUser!.id.toString());
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
