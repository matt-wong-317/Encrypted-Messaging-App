import 'package:flutter/material.dart';
import 'UserDatabase.dart';
import 'ContactsModel.dart';
import 'MessageModel.dart';
import 'ChatsModel.dart';
import 'Encryption.dart';
import'dart:io';
import 'package:image_picker/image_picker.dart';
import 'Notifications.dart';

class ChatScreen extends StatefulWidget{
  final Chat contact;

  ChatScreen({required this.contact});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

// CHAT SCREEN

class _ChatScreenState extends State<ChatScreen>{
  final TextEditingController _controller = TextEditingController(); // controller to contain the text messages being types
  final MessageModel messageModel = MessageModel();
  final ContactsModel contactsModel = ContactsModel();
  final ChatsModel chatsModel = ChatsModel();
  final Encryption encryption = Encryption();

  List<Message> msgs = []; // stores the messages

  int? currentUser;


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

  // Used to send messages
  Future<void> _sendMessages(String msg) async{
    if(currentUser == null || msg.isEmpty){
      return; // Ensures valid user, and ensures that blank messages don't get sent
    }

    // Encrypts Message
    final encrypted = await encryption.encryptText(msg);

    // Verifies encryption
    print("Before encryption: $msg");
    print("After encryption: $encrypted");



    // Sends encrypted message
    final text  = Message(
      sender: currentUser!,
      recipient: widget.contact.contact,
      msg: encrypted,
      time: DateTime.now().millisecondsSinceEpoch,
      read: 0,
    );
    await messageModel.insertChat(text);
    _controller.clear();
    await _loadMsgs();
  }

  // Used to remove Chats
  Future<void> _deleteChat(Chat chat) async{
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog( //Dialog that prompts user to confirm their decision in removing a contact
            title: Text('Delete Chat'),
            content: Text('Are you sure you want to delete this chat?'),
            actions: <Widget>[
              SimpleDialogOption(
                child: Text('Yes'),
                onPressed: () async{

                  // Deletes chat for user by removing it from the locally stored database
                  await chatsModel.initDatabase();
                  await chatsModel.database.delete(
                    'chats',
                    where: 'user = ? AND contact = ?',
                    whereArgs: [currentUser, chat.contact],
                  );

                  Navigator.pop(context);
                  Navigator.pop(context, 'deleted'); // Update the home page to not include the deleted contacts

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat Deleted')),
                  );

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


  // Sends a Scheduled Reminder Notification of a sent message
  Future<void> _scheduleReminder() async{
    if(_controller.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type message first')),
      );
      return;
    }


    final scheduledDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if(scheduledDate == null){
      return;
    }

    final scheduledTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if(scheduledTime == null){
      return;
    }


    final scheduledDateAndTime = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    if(scheduledDateAndTime.isBefore(DateTime.now())){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a time in the future')),
      );
      return;
    }


    final encrypted = await encryption.encryptText(_controller.text);
    final message = Message(
        sender: currentUser!,
        recipient: widget.contact.contact,
        msg: encrypted,
        time: scheduledDateAndTime.millisecondsSinceEpoch,
        read: 0,
    );
    await messageModel.insertChat(message);
    _controller.clear();
    await _loadMsgs();

    await Notifications.scheduleReminder(
        scheduledDateAndTime,
        widget.contact.id ?? widget.contact.contact,
        widget.contact.name,
        _controller.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message Notification Scheduled')),
    );


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
            IconButton(onPressed: () =>
                _deleteChat(widget.contact),
                icon: Icon(Icons.delete)
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 12),
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
            ),
            SafeArea(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(50, 8, 15, 18),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.notification_add, color: Colors.blue),
                        onPressed: _scheduleReminder,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: Colors.blue),
                        onPressed: () => _sendMessages(_controller.text), // Sends the message
                      ),
                    ],
                  ),
              ),
            ),
          ],
        )
    );
  }
}

class ChatScreenFromNoti extends StatelessWidget{
  final int chatId;

  ChatScreenFromNoti({required this.chatId});

  Future<Chat> _loadChat() async{
    final chatsModel = ChatsModel();
    await chatsModel.initDatabase();
    final chat = await chatsModel.database.query(
      'chats',
      where: 'id = ?',
      whereArgs: [chatId],
    );
    return Chat.fromMap(chat.first);
  }

  @override
  Widget build(BuildContext context){
    return FutureBuilder(
        future: _loadChat(),
        builder: (context, snapshot){
          if(!snapshot.hasData){
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return ChatScreen(contact: snapshot.data as Chat);
        }
    );
  }

}

