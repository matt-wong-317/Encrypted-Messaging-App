import 'package:flutter/material.dart';
import 'UserDatabase.dart';
import 'ContactsModel.dart';
import 'MessageModel.dart';
import 'ChatsModel.dart';
import 'Encryption.dart';


// Displays the chat from requested senders
class RequestedChatScreen extends StatefulWidget{
  final Chat contact;
  final int currentUser;

  const RequestedChatScreen({super.key, required this.contact, required this.currentUser});

  @override
  _RequestedChatScreenState createState() => _RequestedChatScreenState();
}

// CHAT SCREEN

class _RequestedChatScreenState extends State<RequestedChatScreen>{
  final TextEditingController _controller = TextEditingController(); // controller to contain the text messages being types
  final MessageModel messageModel = MessageModel();
  final ContactsModel contactsModel = ContactsModel();
  final ChatsModel chatsModel = ChatsModel();
  final Encryption encryption = Encryption();

  List<Message> msgs = []; // stores the messages

  int? currentUser;
  User? sender;

  @override
  void initState(){
    super.initState();
    _initializeChat();
  }

  // Initializes the chat
  Future<void> _initializeChat() async{
    await messageModel.initDatabase();
    await chatsModel.initDatabase();
    await contactsModel.initDatabase();
    final usersModel = UsersModel();
    await usersModel.initDatabase();
    final user = await usersModel.getUser();

    await encryption.initKey();

    sender = await usersModel.getUserById(widget.contact.contact);

    if(user != null) {
      currentUser = user.id; // safely set the current user
    }
    await _loadMsgs(); // loads messages
  }

  // Used to load messages
  Future<void> _loadMsgs() async{
    if(currentUser == null) {
      return; // safety precaution to ensure user is valid
    }
    final loadedMsgs = await messageModel.getAllMessages(currentUser!, widget.contact.contact); // loads the locally stored messages for each user

    // // Decrypts the messages
    for (var message in loadedMsgs){
      try{
        message.msg = await encryption.decryptText(message.msg);
        print("After decryption: ${message.msg}");
      } catch(e){
        message.msg = "Decryption error";
      }

      // Marks message as read ADDED
      if(message.recipient == currentUser && message.read == 0){
        await messageModel.markAsRead(message.id!);
      }
    }


    setState(() {
      msgs = loadedMsgs; // displays the loaded messages
    });
  }

  Future<void> _addContact() async{
    await contactsModel.initDatabase();

    // Adds the user to contacts
    Contact contact = Contact(
      user: widget.currentUser,
      contact: sender!.id!,
      email: sender!.email,
      name: sender!.username,
      picture: sender!.picture,
    );

    await contactsModel.insertContact(contact);

    await chatsModel.initDatabase();

    Chat chat = Chat(
      user: widget.currentUser,
      contact: sender!.id!,
      email: sender!.email,
      name: sender!.username,
      picture: sender!.picture,
    );

    await chatsModel.insertChat(chat);

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You added ${sender!.username}")
        )
    );

    _loadMsgs();
    Navigator.pop(context, true);
    Navigator.pop(context, true);

  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.contact.name),
              Text(widget.contact.email,
                style: TextStyle(color: Colors.grey.shade200, fontSize: 14),
              ),
            ],
          ),
          backgroundColor: Colors.lightBlueAccent,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
                onPressed: _addContact, icon: Icon(Icons.person_add_alt_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: msgs.length,
                itemBuilder: (context, index){
                  final msg = msgs[index];
                  final myMsg = msg.sender == currentUser; // Determines who's the current sender
                  return Align(
                    alignment: myMsg ? Alignment.centerRight : Alignment.centerLeft, // Aligns the chat bubbles accordingly to the sender and recipient are
                    child: Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                      decoration: BoxDecoration(
                        color: myMsg ? Colors.blue[100] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(msg.msg),
                    ),
                  );
                },
              ),
            ),
          ],
        )
    );
  }
}
