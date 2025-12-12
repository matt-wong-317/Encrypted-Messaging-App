import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


// CHAT DATABASE
// used to handle the contact's chat but not the messages themselves
class Chat{
  int? id;
  int user;
  int contact;
  String email;
  String name;
  String? picture;

  Chat({this.id, required this.user, required this.contact, required this.email, required this.name, required this.picture});

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'user': this.user,
      'contact': this.contact,
      'email': this.email,
      'name': this.name,
      'picture': this.picture,
    };
  }

  Chat.fromMap(Map<String, dynamic> map) :
        id = map['id'],
        user = map['user'],
        contact = map['contact'],
        email = map['email'],
        name = map['name'],
        picture = map['picture'];
}

class ChatsModel{
  late Database database;


  Future<void> initDatabase() async {
    var dbPath = await getDatabasesPath();
    String path = join(dbPath, 'chats.db');

    database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute("CREATE TABLE chats(id INTEGER PRIMARY KEY, user INTEGER, contact INTEGER, email TEXT, name TEXT, picture TEXT)");
      },
    );
  }


  // Insert Chat
  Future<int> insertChat(Chat name) async {
    int id = await database.insert(
      'chats',
      name.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  // Gets the Chats
  Future<List<Chat>> getAllChats(int user) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'chats',
      where: 'user = ?',
      whereArgs: [user],
    );

    List<Chat> chats = [];
    if (maps.length > 0) {
      for (int i = 0; i < maps.length; i++) {
        chats.add(Chat.fromMap(maps[i]));
      }
    }
    return chats;
  }

  Future<void> updateContactName(int contact, String name) async{
    await database.update(
      'chats',
      {'name': name},
      where: 'contact = ?',
      whereArgs: [contact],
    );
  }

  Future<void> updateContactPicture(int contact, String imgPath) async{
    await database.update(
      'chats',
      {'picture': imgPath},
      where: 'contact = ?',
      whereArgs: [contact],
    );
  }


}