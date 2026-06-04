import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../models/medicine.dart';
import '../models/category.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'medicine_db.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE medicines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        expiryDate TEXT NOT NULL,
        photoPath TEXT,
        categoryId INTEGER,
        dosage TEXT,
        frequency TEXT,
        hasReminder INTEGER DEFAULT 0,
        reminderTime TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories(id)
      )
    ''');

    await insertDefaultCategories(db);
    await _initNotifications();
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE medicines ADD COLUMN photoPath TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon TEXT NOT NULL,
          color INTEGER NOT NULL
        )
      ''');
      await db.execute('ALTER TABLE medicines ADD COLUMN categoryId INTEGER');
      await insertDefaultCategories(db);
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE medicines ADD COLUMN dosage TEXT');
      await db.execute('ALTER TABLE medicines ADD COLUMN frequency TEXT');
      await db.execute('ALTER TABLE medicines ADD COLUMN hasReminder INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE medicines ADD COLUMN reminderTime TEXT');
    }
  }

  // ✅ СДЕЛАНО ПУБЛИЧНЫМ
  Future<void> insertDefaultCategories(Database db) async {
    final defaultCategories = [
      {'name': 'Таблетки', 'icon': '💊', 'color': 0xFF2ECC71},
      {'name': 'Мази', 'icon': '🧴', 'color': 0xFFF39C12},
      {'name': 'Капли', 'icon': '💧', 'color': 0xFF3498DB},
      {'name': 'Витамины', 'icon': '🍊', 'color': 0xFFE67E22},
      {'name': 'Антибиотики', 'icon': '🦠', 'color': 0xFFE74C3C},
      {'name': 'Обезболивающие', 'icon': '🏥', 'color': 0xFF9B59B6},
    ];
    for (var cat in defaultCategories) {
      await db.insert('categories', cat);
    }
  }

  Future _initNotifications() async {
    if (Platform.isWindows) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );
  }

  // КАТЕГОРИИ
  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ЛЕКАРСТВА
  Future<int> insert(Medicine medicine) async {
    final db = await database;
    int id = await db.insert('medicines', medicine.toMap());
    await scheduleNotification(medicine, id);
    return id;
  }

  Future<int> update(Medicine medicine) async {
    final db = await database;
    await cancelNotification(medicine.id!);
    int result = await db.update(
      'medicines',
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
    await scheduleNotification(medicine, medicine.id!);
    return result;
  }

  Future<List<Medicine>> getMedicines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('medicines');
    return List.generate(maps.length, (i) => Medicine.fromMap(maps[i]));
  }

  Future<int> delete(int id) async {
    final db = await database;
    await cancelNotification(id);
    return await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> scheduleNotification(Medicine medicine, int id) async {
    if (Platform.isWindows || !medicine.hasReminder) return;
    
    tz_data.initializeTimeZones();
    final localTimeZone = tz.getLocation('Europe/Moscow');
    DateTime notifyDate = medicine.expiryDate.subtract(const Duration(days: 3));
    if (notifyDate.isBefore(DateTime.now())) {
      notifyDate = DateTime.now().add(const Duration(seconds: 5));
    }
    final tzNotifyDate = tz.TZDateTime.from(notifyDate, localTimeZone);

    const androidDetails = AndroidNotificationDetails(
      'channel_id', 'Medicines',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      '⏰ Срок годности истекает!',
      'Лекарство "${medicine.name}" истекает ${medicine.expiryDate.day}.${medicine.expiryDate.month}.${medicine.expiryDate.year}',
      tzNotifyDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    if (Platform.isWindows) return;
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // ЭКСПОРТ/ИМПОРТ
  Future<String> exportDatabase() async {
    final db = await database;
    final medicines = await db.query('medicines');
    final categories = await db.query('categories');
    final data = {
      'medicines': medicines,
      'categories': categories,
      'exportDate': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }

  Future<void> importDatabase(String jsonData) async {
    final db = await database;
    final data = jsonDecode(jsonData);
    await db.transaction((txn) async {
      await txn.delete('medicines');
      await txn.delete('categories');
      for (var category in data['categories']) {
        await txn.insert('categories', category);
      }
      for (var medicine in data['medicines']) {
        await txn.insert('medicines', medicine);
      }
    });
  }
}