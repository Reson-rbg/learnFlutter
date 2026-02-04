import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/todo.dart';
import '../models/check_in.dart';

// -------------------------------------------------------------------------
// 知识点：SQLite 数据库封装
// -------------------------------------------------------------------------
// 使用单例模式管理数据库连接，确保全局只有一个数据库实例。
// 涉及 Tables: users, todos, check_ins

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // 获取标准的数据库路径
    String path = join(await getDatabasesPath(), 'flutter_advanced_todo.db');
    
    return await openDatabase(
      path,
      version: 2, // 升级版本号
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // 数据库升级逻辑
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE todos ADD COLUMN reminderTime TEXT');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. 创建用户表
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        username TEXT,
        password TEXT,
        createdAt TEXT
      )
    ''');

    // 2. 创建任务表
    await db.execute('''
      CREATE TABLE todos(
        id TEXT PRIMARY KEY,
        userId TEXT,
        title TEXT,
        description TEXT,
        isCompleted INTEGER,
        createdAt TEXT,
        reminderTime TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    
    // 3. 创建打卡表
    await db.execute('''
      CREATE TABLE check_ins(
        id TEXT PRIMARY KEY,
        userId TEXT,
        checkInTime TEXT,
        note TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');
  }

  // ---- User Operations ----
  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert(
      'users', 
      user.toMap(), 
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUser(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }
  
  Future<bool> checkUserExists(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }

  // ---- Todo Operations ----
  Future<void> insertTodo(Todo todo) async {
    final db = await database;
    await db.insert(
      'todos', 
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Todo>> getTodos(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  Future<void> updateTodo(Todo todo) async {
    final db = await database;
    await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<void> deleteTodo(String id) async {
    final db = await database;
    await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---- CheckIn Operations ----
  Future<void> insertCheckIn(CheckIn checkIn) async {
    final db = await database;
    await db.insert('check_ins', checkIn.toMap());
  }

  Future<List<CheckIn>> getCheckIns(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'check_ins',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'checkInTime DESC',
    );
    return List.generate(maps.length, (i) => CheckIn.fromMap(maps[i]));
  }
  
  // 检查今天是否已打卡
  Future<bool> hasCheckedInToday(String userId) async {
    final db = await database;
    final date = DateTime.now();
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    
    final result = await db.query(
      'check_ins',
      where: 'userId = ? AND checkInTime BETWEEN ? AND ?',
      whereArgs: [userId, startOfDay, endOfDay],
    );
    return result.isNotEmpty;
  }
}
