import 'dart:convert'; // Para manejar JSON
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  /// Inicializa o retorna la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'traducciones.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> initializeDatabase() async {
    // Verifica si la base de datos ya está inicializada
    if (_database == null || !_database!.isOpen) {
      _database = await _initDatabase();  // Inicializa la base de datos si no está abierta
    }
    if (_database == null || !_database!.isOpen) {
      throw Exception('La base de datos no pudo abrirse');
    }
  }


  /// Crea la tabla `TRADUCCIONES`
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE TRADUCCIONES (
        idioma TEXT PRIMARY KEY, -- El UID del idioma ('es', 'en', etc.)
        traducciones TEXT NOT NULL -- Un string JSON con las claves y valores
      )
    ''');
  }

  /// Inserta o actualiza las traducciones para un idioma
  Future<void> insertOrUpdateTranslations(String idioma, Map<String, dynamic> traducciones) async {
    final db = await database;
    await db.insert(
      'TRADUCCIONES',
      {
        'idioma': idioma,
        'traducciones': jsonEncode(traducciones), // Convierte el mapa a JSON
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // Reemplaza si ya existe
    );
  }

  /// Inserta o actualiza traducciones para varios idiomas
  Future<void> insertOrUpdateMultipleTranslations(Map<String, dynamic> allTranslations) async {
    final db = await database;

    Batch batch = db.batch();
    allTranslations.forEach((idioma, traducciones) {
      batch.insert(
        'TRADUCCIONES',
        {
          'idioma': idioma,
          'traducciones': jsonEncode(traducciones), // Convierte el mapa a JSON
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    await batch.commit(noResult: true);
  }

  Future<void> updateSQLiteDatabase(List<Map<String, dynamic>> firebaseData) async {
    final db = await database;

    // Inicia una transacción para actualizar la base de datos de forma eficiente
    Batch batch = db.batch();

    for (var data in firebaseData) {
      batch.insert(
        'TRADUCCIONES',
        {
          'idioma': data['idioma'],
          'traducciones': jsonEncode(data['traducciones']), // Convierte las traducciones a JSON
        },
        conflictAlgorithm: ConflictAlgorithm.replace, // Reemplaza si ya existe
      );
    }

    // Ejecuta las operaciones de la transacción
    await batch.commit(noResult: true);
  }

  Stream<List<Map<String, dynamic>>> getTranslationsStream() async* {
    final db = await database;
    // Esto emite los cambios en las traducciones
    while (true) {
      final translations = await db.query('TRADUCCIONES');
      yield translations;
      await Future.delayed(Duration(seconds: 1)); // Espera un segundo antes de volver a obtener datos
    }
  }

  Future<Map<String, String>> getTranslationsByLanguage(String idioma) async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> result = await db.query(
        'TRADUCCIONES',
        where: 'idioma = ?',
        whereArgs: [idioma],
      );

      if (result.isNotEmpty) {
        final String jsonString = result.first['traducciones'];
        final Map<String, dynamic> decoded = jsonDecode(jsonString);

        // Retorna el mapa de claves y valores como Map<String, String>.
        return Map<String, String>.from(decoded);
      } else {
        throw Exception('No se encontraron traducciones para el idioma: $idioma');
      }
    } catch (e) {
      // Aquí puedes loguear el error o manejarlo como prefieras.
      throw Exception('Error al obtener las traducciones: $e');
    }
  }


  Future<List<Map<String, dynamic>>> getAllTranslations() async {
    final db = await database;

    if (db.isOpen) {
      return await db.query('TRADUCCIONES');
    } else {
      throw Exception('La base de datos está cerrada');
    }
  }



  /// Obtiene todos los idiomas almacenados
  Future<List<String>> getAllLanguages() async {
    final db = await database;

    final List<Map<String, dynamic>> result =
    await db.query('TRADUCCIONES', columns: ['idioma']);

    return result.map((row) => row['idioma'] as String).toList();
  }

}


