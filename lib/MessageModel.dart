import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


// Message Database
class Message{
  int? id;
  int sender;
  int recipient;
  String msg;
  int time;
  int read;
  int notified;

  Message({this.id, required this.sender, required this.recipient, required this.msg, required this.time, required this.read, this.notified = 0});

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'sender': this.sender,
      'recipient': this.recipient,
      'msg': this.msg,
      'time': this.time,
      'read': this.read,
      'notified': this.notified,
    };
  }

  Message.fromMap(Map<String, dynamic> map) :
        id = map['id'],
        sender = map['sender'],
        recipient = map['recipient'],
        msg = map['msg'],
        time = map['time'],
        read = map['read'],
        notified = map['notified'];
}

class MessageModel{
  late Database database;

  // Initializes the messgae database
  Future<void> initDatabase() async {
    var dbPath = await getDatabasesPath();
    String path = join(dbPath, 'messages.db');

    // Creates a table for the message database
    database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute("CREATE TABLE messages(id INTEGER PRIMARY KEY, sender INTEGER, recipient INTEGER, msg TEXT, time INTEGER, read INTEGER, notified INTEGER)");
      },
    );
  }

  // Inserts chat to send messages
  Future<int> insertChat(Message msg) async {
    int id = await database.insert(
      'messages',
      msg.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  // Gets the messages depending on who sent them
  Future<List<Message>> getAllMessages(int sender, int recipient) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'messages',
      where: '(sender = ? AND recipient = ?) OR (sender = ? AND recipient = ?)',
      whereArgs: [sender, recipient, recipient, sender],
      orderBy: 'time ASC',
    );

    List<Message> msgs = [];
    if (maps.length > 0) {
      for (int i = 0; i < maps.length; i++) {
        msgs.add(Message.fromMap(maps[i]));
      }
    }
    return msgs;
  }

  Future<void> markAsRead(int id) async{
    await database.update(
      'messages',
      {'read':1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Message?> recentMessage(int id) async{
    final db = await database;
    final msg = await db.query(
      'messages',
      where: 'recipient = ? and read = 0',
      whereArgs: [id],
      orderBy: 'time DESC',
      limit: 1,
    );
    if(msg.isNotEmpty){
      return Message.fromMap(msg.first);
    }
    return null;
  }

  Future<void> markAsNotified(int id) async{
    await database.update(
      'messages',
      {'notified':1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }


}