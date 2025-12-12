import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'ContactsModel.dart';
import 'ChatsModel.dart';

// USER DATABASE
class User {
  int? id;
  String username;
  String email;
  String password;
  int isLoggedIn = 0;
  String? picture;
  int isPublic = 0;

  User({this.id, required this.username, required this.email, required this.password, required this.isLoggedIn, this.picture, this.isPublic = 0});


  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'username': this.username,
      'email': this.email,
      'password': this.password,
      'isLoggedIn': this.isLoggedIn,
      'picture': picture,
      'isPublic': isPublic,
    };
  }

  User.fromMap(Map<String, dynamic> map) :
        id = map['id'],
        username = map['username'],
        email = map['email'],
        password = map['password'],
        isLoggedIn = map['isLoggedIn'],
        picture = map['picture'],
        isPublic = map['isPublic'] ?? 0;
}



class UsersModel{
  late Database database;


  Future<void> initDatabase() async {
    var dbPath = await getDatabasesPath();
    String path = join(dbPath, 'users.db');

    database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute("CREATE TABLE users(id INTEGER PRIMARY KEY, username TEXT, email TEXT, password TEXT, isLoggedIn INTEGER, picture TEXT, isPublic INTEGER)");
      },
    );
  }

  // Gets existing users
  Future<User?> getUser() async {
    final List<Map<String, dynamic>> maps = await database.query('users', where: 'isLoggedIn = ?', whereArgs: [1]);
    if (maps.length > 0) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Handles logging in if the account exists on local storage
  Future<User?> login(String email, String password) async {
    logout();
    email = email.toLowerCase();
    final List<Map<String, dynamic>> maps = await database.query('users', where: 'email = ? AND password = ?', whereArgs: [email, password]);
    if (maps.length > 0) {
      User user = User.fromMap(maps.first);
      await LoggedIn(user.id!, 1);
      return await getUserById(user.id!);
    }
    return null;
  }


  // Adds new users to the locally stored database
  Future<int> insertUser(User user) async {
    user.email = user.email.toLowerCase();

    // Handles dummy api user id's to avoid overlapping ids
    const int apiUserCount = 30;
    if(user.id == null){
      final List<Map<String, dynamic>> ids = await database.rawQuery(
          'SELECT MAX(id) as maxId FROM users'
      );
      int maxId = ids.first['maxId'] ?? apiUserCount; // Starts ids after the api's ids
      if(maxId < apiUserCount){
        user.id = apiUserCount + 1;
      }else{
        user.id = maxId + 1;
      }
    }

    // Inserts user id
    int id = await database.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id;
  }

  // Determines if a user is logged in
  Future<void> LoggedIn(int id, int option) async {
    await database.update(
      'users',
      {'isLoggedIn' : option},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Handles logging out
  Future<void> logout() async{
    await database.update('users', {'isLoggedIn': 0});
  }

  // Handles saving new usernames locally
  Future<void> editUsername(int id, String newUsername) async{
    await database.update(
      'users',
      {'username': newUsername},
      where: 'id = ?',
      whereArgs: [id],
    );

    final contactsModel = ContactsModel();
    await contactsModel.initDatabase();
    await contactsModel.updateContactName(id, newUsername);

    final chatsModel = ChatsModel();
    await chatsModel.initDatabase();
    await chatsModel.updateContactName(id, newUsername);

  }

  Future<User?> getUserById(int id) async{
    final db = await database;
    final user  = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if(user.isEmpty){
      return null;
    }
    return User.fromMap(user.first);
  }

  Future<User?> getUserByEmail(String email) async{
    email = email.toLowerCase();
    final List<Map<String, dynamic>> user = await database.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if(user.isEmpty){
      return null;
    }
    return User.fromMap(user.first);
  }

  Future<void> profilePicture(int id, String imgPath) async{
    await database.update(
      'users',
      {'picture': imgPath},
      where: 'id = ?',
      whereArgs: [id],
    );

    final contactsModel = ContactsModel();
    await contactsModel.initDatabase();
    await contactsModel.updateContactPicture(id, imgPath);

    final chatsModel = ChatsModel();
    await chatsModel.initDatabase();
    await chatsModel.updateContactPicture(id, imgPath);

  }

  Future<void> togglePublic(int userId, int isPublic) async{
    await database.update(
      'users',
      {'isPublic': isPublic},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<User>> getPublicUsers() async{
    final List<Map<String, dynamic>> maps = await database.query(
      'users',
      where: 'isPublic = ?',
      whereArgs: [1]
    );

    List<User> users = [];
    if(maps.isNotEmpty){
      for(int i = 0; i < maps.length; i++){
        users.add(User.fromMap(maps[i]));
      }
    }
    return users;
  }

  Future<List<User>> getAllUsers() async{
    final List<Map<String, dynamic>> maps = await database.query('users');

    List<User> users = [];
    if(maps.isNotEmpty){
      for(int i = 0; i < maps.length; i++){
        users.add(User.fromMap(maps[i]));
      }
    }
    return users;
  }

}