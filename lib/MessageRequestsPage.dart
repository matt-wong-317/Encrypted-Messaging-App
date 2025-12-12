import 'package:flutter/material.dart';
import 'UserDatabase.dart';
import 'ContactsModel.dart';
import 'ChatsModel.dart';
import 'MessageModel.dart';
import 'Encryption.dart';
import 'dart:io';
import 'RequestedChatScreen.dart';

// Pge to display message requests
class MessageRequestsPage extends StatefulWidget{
  final int currentUserId;

  const MessageRequestsPage({super.key, required this.currentUserId});

  @override
  _MessageRequestsPageState createState() => _MessageRequestsPageState();
}

class _MessageRequestsPageState extends State<MessageRequestsPage>{
  final usersModel = UsersModel();
  final contactsModel = ContactsModel();
  final messageModel = MessageModel();
  final encryption = Encryption();


  List<Map<String, dynamic>> chats = [];

  @override
  void initState(){
    super.initState();
    _loadRequestedMessages();
    encryption.initKey();
  }

  Future<void> _loadRequestedMessages() async{
    await usersModel.initDatabase();
    await contactsModel.initDatabase();
    await messageModel.initDatabase();

    // Gets all the messages that have been sent to the current user
    final messages = await messageModel.database.query(
      'messages',
      where: 'recipient = ?',
      whereArgs: [widget.currentUserId],
      orderBy: 'time DESC',
    );

    //List<Map<String, dynamic>> requestedChats = [];
    Map<int, Map<String, dynamic>> requestedChats = {};


    for(var message in messages){
      final msg = Message.fromMap(message);
      final contactAdded = await contactsModel.database.query(
        'contacts',
        where: 'user = ? AND contact = ?',
        whereArgs: [widget.currentUserId, msg.sender],
      );

      if(contactAdded.isNotEmpty){
        continue;
      }

      if(!requestedChats.containsKey(msg.sender)){
        final sender = await usersModel.getUserById(msg.sender);

        String decrypted = '';
        try{
          decrypted = await encryption.decryptText(msg.msg);
        } catch(e){
          msg.msg = "Decryption error";
        }



        requestedChats[msg.sender] = {
          'sender': sender,
          'message': decrypted,
        };
      }
    }
    setState(() {
      chats = requestedChats.values.toList();
    });
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
    return Scaffold(
      appBar: AppBar(title: Text("Message Requests"), foregroundColor: Colors.blue),
      body: chats.isEmpty ? Center(child: Text("No Message Requests")) :
      Container(
        color: Colors.blue.shade50,
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
              // Highlights the messages section
              Expanded(
                child: ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final sender = chat['sender'];
                    final message = chat['message'];

                    return ListTile(
                      // Displays a profile picture
                      leading: CircleAvatar( // Displays user profile picture
                        backgroundColor: Colors.lightBlueAccent,
                        backgroundImage: _getProfilePicture(sender.picture),
                        child: sender.picture == null ? Icon(Icons.person, color: Colors.white) : null,
                      ),
                      title: Text(sender.username),
                      subtitle: Text(message),
                      // Going to be set to display the lst send message
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RequestedChatScreen(
                              contact: Chat(
                                user: widget.currentUserId,
                                contact: sender.id!,
                                email: sender.email,
                                name: sender.username,
                                picture: sender.picture,
                              ),
                              currentUser: widget.currentUserId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}