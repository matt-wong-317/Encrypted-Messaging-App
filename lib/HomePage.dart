import 'package:flutter/material.dart';
import 'package:project/MessageModel.dart';
import 'ContactsModel.dart';
import 'UserDatabase.dart';
import 'ChatScreen.dart';
import 'Notifications.dart';
import 'ChatsModel.dart';
import 'Encryption.dart';
import 'dart:io';
import 'MessageRequestsPage.dart';
import 'MessageModel.dart';


class HomePage extends StatefulWidget {

  HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

// HOME PAGE
class _HomePageState extends State<HomePage> {
  final ContactsModel contactsModel = ContactsModel();
  final ChatsModel chatsModel = ChatsModel();
  List<Chat> chats = []; // used to store the chats that will be displayed on this page

  late int user;

  @override
  void initState() {
    super.initState();
    _initChats();
  }

  // Initializes the chats so they can load and appear on the screen
  Future<void> _initChats() async {
    // initializing databases
    await chatsModel.initDatabase();
    final usersModel = UsersModel();
    await usersModel.initDatabase();
    final currentUser = await usersModel.getUser();

    // ensures the current user is valid and sets it accordingly (for extra precaution during later changes)
    if (currentUser != null) {
      user = currentUser.id!;
    }

    // gets all the chats for the current user, so that chats are locally saved and unique for each user
    final initializedChats = await chatsModel.getAllChats(user);

    List<Chat> sortedChats = await _sortNewChats(initializedChats);

    if(!mounted){
      return;
    }

    setState(() {
      chats = sortedChats; // used to display the chats
    });
    await _unreadMessags();
  }

  Future<List<Chat>> _sortNewChats(List<Chat> chats) async{
    final messageModel = MessageModel();
    await messageModel.initDatabase();

    List<Map<String, dynamic>> recentChats = [];

    for(var chat in chats){
      final msgs = await messageModel.database.query(
        'messages',
        where: '(sender = ? AND recipient = ?) OR (sender = ? AND recipient = ?)',
        whereArgs: [user, chat.contact, chat.contact, user],
        orderBy: 'time DESC',
        limit: 1
      );

      int recency;
      if(msgs.isNotEmpty){
        recency = msgs.first['time'] as int;
      }else{
        recency = chat.id ?? 0;
      }
      recentChats.add({
        'chat': chat,
        'recency': recency,
      });
    }
    recentChats.sort((msg, msg2) => (msg2['recency'] as int).compareTo(msg['recency'] as int));
    return recentChats.map((item) => item['chat'] as Chat).toList();

  }





  Future<void> _unreadMessags() async{
    final messageModel = MessageModel();
    await messageModel.initDatabase();
    final encryption = Encryption();
    bool newestMsg = true;

    final database = messageModel.database;
    final unreadMsgs = await database.query(
      'messages',
      where: 'recipient = ? AND read = 0 AND notified = 0',
      whereArgs: [user],
      orderBy: 'time DESC',
    );
    if(unreadMsgs.isNotEmpty){
      for(var map in unreadMsgs){
        final msg = Message.fromMap(map);

        final chat = await chatsModel.database.query(
          'chats',
          where: 'contact = ? AND user = ?',
          whereArgs: [msg.sender, user],
        );
        String sender = chat.isNotEmpty ? chat.first['name'] as String : 'New Message';
        final chatId = chat.first['id'] as int;

        final decryptedMsg = await encryption.decryptText(msg.msg);

        if(newestMsg){
          newestMsg = false;
          await Notifications.scheduleNotification(
            context,
            chat: chatId,
            sender: sender,
            message: decryptedMsg,
          );
        }else{
          await Notifications.backgroundNotification(
            context,
            chat: chatId,
            sender: sender,
            message: decryptedMsg,
          );
        }
        if(msg.id != null){
          await messageModel.markAsNotified(msg.id!);
        }
      }
    }

  }

  // Used to add chats with other contacts
  Future<void> _addChat() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ContactPage()),
    );

    // Don't display the chat's of deleted contacts
    if(result == 'deleted'){
      await _initChats();
      return;
    }


    if (result != null && result is Map) {
      // Determines if a chat with another contact already exists on a user's account
      final alreadyExists = await chatsModel.database.query(
        'chats',
        where: 'user = ? AND contact = ?',
        whereArgs: [user, result['id']],
      );

      // Ensures there is no duplicate chat's
      if (alreadyExists.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You already have a chat with this user")), // Snackbar informs user to prevent duplicate chats
        );
        return;
      }

      final usersModel = UsersModel();
      await usersModel.initDatabase();
      String? contactPicture;
      final contact = await usersModel.getUserById(result['id']);
      if(contact != null && contact.picture != null){
        contactPicture = result['picture'];
      }

      // Inserts chat if valid
      Chat newChat = Chat(user: user, contact: result['id'], email: result['email'], name: result['name'], picture: contactPicture);
      await chatsModel.insertChat(newChat);
      final addedChats = await chatsModel.getAllChats(user);

      setState(() {
        chats = addedChats;
      });
    }
  }

  Future<String?> _getNewestMsg(int contactId, String contactName) async{
    if(user == null){
      return '';
    }
    final messageModel = MessageModel();
    await messageModel.initDatabase();

    final encryption = Encryption();
    await encryption.initKey();

    final db = messageModel.database;

    // get the most recent sent or received message
    final msg = await db.query(
      'messages',
      where: '(sender = ? AND recipient = ?) OR (sender = ? AND recipient = ?)',
      whereArgs: [user, contactId, contactId, user],
      orderBy: 'time DESC',
      limit: 1,
    );

    if(msg.isEmpty){
      return 'No Messages Sent';
    }

    final newestMsg = Message.fromMap(msg.first);

    String start;
    if(newestMsg.sender == user){
      start = 'You: ';
    }else{
      start = '$contactName: ';
    }
    try{
      final decrypted = await encryption.decryptText(newestMsg.msg);
      return '$start$decrypted';
    } catch(e){
      return 'Decryption Error';
    }

  }

  Future<bool> _newMessageExists(int contactId) async{
    final messageModel = MessageModel();
    await messageModel.initDatabase();

    final newMsgs = await messageModel.database.query(
      'messages',
      where: 'recipient = ? AND sender = ? AND read = 0',
      whereArgs: [user, contactId],
    );
    return newMsgs.isNotEmpty;
  }

  ImageProvider? _getProfilePicture(String? imagePath){
    if(imagePath == null || imagePath.isEmpty){
      return null;
    }
    if(imagePath.startsWith('https')){
      return NetworkImage(imagePath);
    }
    if(imagePath.startsWith('/') || imagePath.contains('/')){
      try {
        return FileImage(File(imagePath));
      }catch(e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messaging App', style: TextStyle(fontWeight: FontWeight.bold)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)), // Highlights the messages section
                  TextButton(
                      child: Text(
                          'Requests',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)
                      ),
                      onPressed: () async{
                        final update = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MessageRequestsPage(currentUserId: user)),
                        );
                        if(update == true){
                          _initChats();
                        }
                      }
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return ListTile(
                      // Displays a profile picture
                      leading: CircleAvatar( // Displays user profile picture
                        backgroundColor: Colors.lightBlueAccent,
                        backgroundImage: _getProfilePicture(chat.picture),
                        child: chat.picture == null ? Icon(Icons.person, color: Colors.white) : null,
                      ),
                      title: Text(chat.name),
                      // Displays the most recent message in the chat
                      subtitle: FutureBuilder(
                          future: Future.wait([
                            _getNewestMsg(chat.contact, chat.name),
                            _newMessageExists(chat.contact),
                          ]),
                          builder: (context, snapshot){
                            if(!snapshot.hasData){
                              return Text('');
                            }
                            final text = snapshot.data as List;
                            final msg = text[0] as String;
                            final newMsgReceived = text[1] as bool;
                            if(text.isEmpty){
                              return Text('');
                            }
                            return Text(msg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: newMsgReceived ? Colors.black : null,
                                    fontWeight: newMsgReceived ? FontWeight.bold : FontWeight.normal,
                                    fontStyle: msg == 'No Messages Sent' ? FontStyle.italic : FontStyle.normal
                                )
                            );
                          }
                      ),
                      onTap: () async {
                        final update = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(contact: chat),
                          ),
                        );
                        if(update == 'deleted'){
                          _initChats();
                        }
                        _initChats();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Stack(
          children: [
            // Floating button to open the contacts list for users to add or remove chats
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: _addChat,
                backgroundColor: Colors.lightBlueAccent,
                child: Icon(Icons.add_comment, color: Colors.white),
              ),
            ),
          ]
      ),
    );
  }
}





class ContactPage extends StatefulWidget {
  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final ContactsModel contactsModel = ContactsModel();
  final UsersModel usersModel = UsersModel();
  List<Contact> contacts = []; // Used to store the user's contacts
  int? currentUser;

  @override
  void initState() {
    super.initState();
    _contacts();
  }

  // Initializes and displays the user's contacts so each user has unique contacts saved through local storage
  Future<void> _contacts() async {
    await contactsModel.initDatabase();
    await usersModel.initDatabase();
    final user = await usersModel.getUser();
    if (user != null) {
      currentUser = user.id;
      final people = await contactsModel.getAllContacts(currentUser!);
      setState(() {
        contacts = people;
      });
    }
  }


  // Used to remove contacts
  Future<void> _deleteContact(Contact contact) async{
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog( //Dialog that prompts user to confirm their decision in removing a contact
            title: Text('Remove Contact'),
            content: Text('Are you sure you want to remove this contact?'),
            actions: <Widget>[
              SimpleDialogOption(
                child: Text('Yes'),
                onPressed: () async{
                  // Deletes contact for user by removing it from the locally stored database
                  await contactsModel.database.delete(
                    'contacts',
                    where: 'id = ?',
                    whereArgs: [contact.id],
                  );

                  final chatsModel = ChatsModel();
                  await chatsModel.initDatabase();
                  await chatsModel.database.delete(
                    'chats',
                    where: 'user = ? AND contact = ?',
                    whereArgs: [currentUser, contact.contact],
                  );

                  setState(() {
                    contacts.removeWhere((c) => c.id == contact.id); // Update the screen to not include the deleted contacts
                  });
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact Deleted')),
                  );

                  Navigator.pop(context, 'deleted'); // Update the home page to not include the deleted contacts
                },
              ),
              SimpleDialogOption(
                child: Text('No'),
                onPressed: () { // Closes the dialog
                  Navigator.pop(
                      context);
                },
              ),
            ],
          );
        }
    );
  }

  // Used to get either user or api profile picture
  ImageProvider? _getProfilePicture(String? imagePath){
    if(imagePath == null || imagePath.isEmpty){
      return null;
    }
    if(imagePath.startsWith('https')){
      return NetworkImage(imagePath);
    }
    if(imagePath.startsWith('/') || imagePath.contains('/')){
      try {
        return FileImage(File(imagePath));
      }catch(e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contacts'), foregroundColor: Colors.blue,
      ),
      body: contacts.isEmpty // Either displays contact or informs the user that they have no contacts added
          ? Center(child: Text('You have no contacts'))
          : ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return ListTile(
            leading: CircleAvatar( // Displays user profile picture
              backgroundColor: Colors.lightBlueAccent,
              backgroundImage: _getProfilePicture(contact.picture),
              child: contact.picture == null ? Icon(Icons.person, color: Colors.white) : null,
            ),
            title: Text(contact.name),
            subtitle: Text(contact.email),
            onTap: () {
              Navigator.pop(context, {'id': contact.contact, 'email': contact.email, 'name': contact.name, 'picture': contact.picture}); // Pops information on tap to determine if chat is added
            },
            trailing: IconButton(
                onPressed: () => _deleteContact(contact),
                icon: Icon(Icons.delete)),
          );
        },
      ),
    );
  }
}
