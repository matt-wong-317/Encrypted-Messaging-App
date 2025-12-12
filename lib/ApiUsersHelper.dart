import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'ApiUsers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'UserDatabase.dart';

// HELPER CLASS TO MAKE HTTPS CALLS FOR API USERS
class ApiUsersHelper {
  static final ApiUsersHelper instance = ApiUsersHelper._init();
  static Database? _database;

  ApiUsersHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('api.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE api(
        id INTEGER PRIMARY KEY,
        username TEXT,
        email TEXT,
        password TEXT,
        image TEXT,
      )
    ''');
  }

  // used to add users to database
  Future<void> insertUser(ApiUser user) async {
    final db = await instance.database;
    await db.insert('api', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // gets users from database
  Future<List<ApiUser>> getUsers() async {
    final db = await instance.database;
    final maps = await db.query('api');

    return List.generate(maps.length, (i) {
      return ApiUser(
        id: maps[i]['id'] as int,
        username: maps[i]['username'] as String,
        email: maps[i]['email'] as String,
        password: maps[i]['password'] as String,
        image: maps[i]['image'] as String,
      );
    });
  }

  // gets users from api
  static Future<List<ApiUser>> fetchUsersFromApi() async {
    final response = await http.get(Uri.parse('https://dummyjson.com/users'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final List data = body['users'];
      return data.map((json) => ApiUser(
        id: json['id'],
        username: json['username'],
        email: json['email'],
        password: json['password'],
        image: json['image'],
      )).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  // gets api users by email
  static Future<ApiUser?> fetchUsersByEmail(String email) async {
    final List<ApiUser> users = await fetchUsersFromApi();

    try{
      return users.firstWhere((user) => user.email.toLowerCase() == email.toLowerCase());
    }catch(_){
      return null;
    }
  }


  static Future<ApiUser> addUserToApi(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('https://dummyjson.com/users'),
      headers: {"Content-Type": "application/json; charset=UTF-8"},
      body: jsonEncode({"username": username, "email": email, "password": password}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return ApiUser(
        id: data['id'],
        username: data['username'],
        email: data['email'],
        password: data['password'],
        image: data['image'],
      );
    } else {
      throw Exception('Failed to create user');
    }
  }

  static Future<ApiUser> editApiUsername(int id, String newUsername) async {
    final response = await http.put(
      Uri.parse('https://dummyjson.com/users/$id'),
      headers: {"Content-Type": "application/json; charset=UTF-8"},
      body: jsonEncode({"username": newUsername}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ApiUser(
        id: data['id'],
        username: data['username'],
        email: data['email'],
        password: data['password'],
        image: data['image'],
      );
    } else {
      throw Exception('Failed to edit username for user $id');
    }
  }

  static Future<ApiUser> editApiImage(int id, String image) async {
    final response = await http.put(
      Uri.parse('https://dummyjson.com/users/$id'),
      headers: {"Content-Type": "application/json; charset=UTF-8"},
      body: jsonEncode({"image": image}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ApiUser(
        id: data['id'],
        username: data['username'],
        email: data['email'],
        password: data['password'],
        image: data['image'],
      );
    } else {
      throw Exception('Failed to edit username for user $id');
    }
  }

  Future<void> saveUpdatesLocally(ApiUser user) async{
    final db = await instance.database;
    await db.insert(
      'api',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ApiUser?> loadUpdatesLocally(String email) async{
    final db = await instance.database;
    final user = await db.query(
      'api',
      where: 'email = ?',
      whereArgs: [email],
    );

    if(user.isEmpty){
      return null;
    }
    return ApiUser(
      id: user.first['id'] as int,
      username: user.first['username'] as String,
      email: user.first['email'] as String,
      password: user.first['password'] as String,
      image: user.first['image'] as String,
    );
  }



}