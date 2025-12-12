import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


// CONTACT DATABASE
// used to handle the contact's
class Contact{
  int? id;
  int user;
  int contact;
  String email;
  String name;
  String? picture;

  Contact({this.id, required this.user, required this.contact, required this.email, required this.name, required this.picture});

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

  Contact.fromMap(Map<String, dynamic> map) :
        id = map['id'],
        user = map['user'],
        contact = map['contact'],
        email = map['email'],
        name = map['name'],
        picture = map['picture'];
}

class ContactsModel{
  late Database database;


  Future<void> initDatabase() async {
    var dbPath = await getDatabasesPath();
    String path = join(dbPath, 'contacts.db');

    database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute("CREATE TABLE contacts(id INTEGER PRIMARY KEY, user INTEGER, contact INTEGER, email TEXT, name TEXT, picture TEXT)");
      },
    );
  }


  // Insert Contact
  Future<int> insertContact(Contact name) async {
    int id = await database.insert(
      'contacts',
      name.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  // Gets the Contacts
  Future<List<Contact>> getAllContacts(int user) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'contacts',
      where: 'user = ?',
      whereArgs: [user],
    );

    List<Contact> contacts = [];
    if (maps.length > 0) {
      for (int i = 0; i < maps.length; i++) {
        contacts.add(Contact.fromMap(maps[i]));
      }
    }
    return contacts;
  }

  Future<void> updateContactName(int contact, String name) async{
    await database.update(
      'contacts',
      {'name': name},
      where: 'contact = ?',
      whereArgs: [contact],
    );
  }

  Future<void> updateContactPicture(int contact, String imgPath) async{
    await database.update(
      'contacts',
      {'picture': imgPath},
      where: 'contact = ?',
      whereArgs: [contact],
    );
  }

}