import 'dart:convert'; // Para manejar JSON
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class DatabaseHelperUsers {
  static final DatabaseHelperUsers _instance = DatabaseHelperUsers._internal();
  static Database? _database;

  DatabaseHelperUsers._internal();

  factory DatabaseHelperUsers() => _instance;

  /// Inicializa o retorna la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabasUsers();
    return _database!;
  }

  /// Inicializa la base de datos
  Future<Database> _initDatabasUsers() async {
    final String path = join(await getDatabasesPath(), 'users.db');
    return await openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> initializeDatabaseUsers() async {
    // Verifica si la base de datos ya está inicializada
    if (_database == null || !_database!.isOpen) {
      _database = await _initDatabasUsers();  // Inicializa la base de datos si no está abierta
    }
    if (_database == null || !_database!.isOpen) {
      throw Exception('La base de datos no pudo abrirse');
    }
  }


  /// Crea la tabla `TRADUCCIONES`
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        name TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Verificamos si estamos pasando de la versión 1 a la 2
    if (oldVersion < newVersion) {
      await db.insert('users' , {
        'name' : 'ana'
      }
      );
    }
  }

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    try {
      await db.insert(
        'users',
        user,
        conflictAlgorithm:
        ConflictAlgorithm.replace, // Reemplazar en caso de conflicto
      );
    } catch (e) {
      print('Error inserting client: $e');
    }
  }





  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;

    if (db.isOpen) {
      return await db.query('users');
    } else {
      throw Exception('La base de datos está cerrada');
    }
  }


  Future<void> deleteDatabaseFile() async {
    final databasePath = await getDatabasesPath();
    final path = "$databasePath/users.db";

    // Verificar si el archivo existe antes de intentar eliminarlo
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      debugPrint("Archivo de base de datos eliminado: $path");
    } else {
      debugPrint("El archivo de base de datos no existe: $path");
    }
  }




  static Future<File> backupDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'users.db');

      final file = File(path);
      if (await file.exists()) {
        return file;
      } else {
        throw Exception("La base de datos no existe en la ruta especificada.");
      }
    } catch (e) {
      throw Exception("Error al hacer la copia de seguridad: $e");
    }
  }

  // Método para obtener el SHA del archivo en GitHub
  static Future<String?> _getFileSha(String owner, String repo, String fileName, String token) async {
    String url = 'https://api.github.com/repos/$owner/$repo/contents/$fileName';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['sha'];  // Devuelve el SHA si el archivo existe
    } else {
      return null;  // Si no existe, el archivo será creado
    }
  }

// Método para subir o actualizar el archivo de la base de datos en GitHub
  static Future<void> uploadDatabaseToGitHub() async {
    try {
      // Obtener la copia de seguridad de la base de datos
      File backupFile = await backupDatabase();
      String fileName = 'database_users.db';  // Nombre del archivo en GitHub
      String owner = 'Marcelo-Do-Amaral-Sala';  // Usuario de GitHub
      String repo = 'backups';  // Repositorio de GitHub
      String token = 'GIT_TOKEN_APP';  // Tu token de acceso a GitHub

      // Leer el archivo y codificarlo en base64
      List<int> fileBytes = await backupFile.readAsBytes();
      String contentBase64 = base64Encode(fileBytes);

      // Print para ver el contenido antes de subirlo
      print("Contenido a subir (base64, tamaño ${contentBase64.length} caracteres): $contentBase64");

      // Verificar si el archivo ya existe en el repositorio
      String? fileSha = await _getFileSha(owner, repo, fileName, token);

      // Construir la URL de la API de GitHub para subir el archivo
      String url = 'https://api.github.com/repos/$owner/$repo/contents/$fileName';

      // Realizar la solicitud PUT para subir o actualizar el archivo
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
        },
        body: jsonEncode({
          'message': 'Subida o actualización de copia de seguridad',
          'content': contentBase64,
          'sha': fileSha,  // Si el archivo ya existe, pasamos el SHA para actualizarlo
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Copia de seguridad subida o actualizada exitosamente en GitHub');
      } else {
        throw Exception('Error al subir o actualizar la copia de seguridad: ${response.body}');
      }
    } catch (e) {
      print('Error al subir o actualizar la copia de seguridad a GitHub: $e');
    }
  }

  static Future<void> downloadDatabaseFromGitHub() async {
    try {
      String fileName = 'database_users.db';
      String owner = 'Marcelo-Do-Amaral-Sala'; // Usuario de GitHub
      String repo = 'backups'; // Repositorio de GitHub
      String token = 'GIT_TOKEN_APP'; // Tu token de acceso a GitHub

      // Construir la URL de la API de GitHub
      String url = 'https://api.github.com/repos/$owner/$repo/contents/$fileName';

      // Realizar la solicitud GET para obtener el archivo
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        // Parsear el contenido de la respuesta
        final responseData = jsonDecode(response.body);

        // Obtener el contenido codificado en base64
        String base64Content = responseData['content'];

        // Eliminar saltos de línea del contenido base64
        base64Content = base64Content.replaceAll('\n', '');

        // **Nuevo: Imprimir el contenido base64 descargado**
        print("Contenido descargado (base64, tamaño ${base64Content.length} caracteres): $base64Content");

        // Decodificar el contenido de base64 a bytes
        List<int> fileBytes = base64Decode(base64Content);

        // Guardar los bytes en un archivo local
        final String path = join(await getDatabasesPath(), 'users.db');
        File localFile = File(path);

        await localFile.writeAsBytes(fileBytes);

        print('Copia de seguridad descargada y guardada exitosamente en: $path');
      } else {
        throw Exception('Error al descargar la copia de seguridad: ${response.body}');
      }
    } catch (e) {
      print('Error al descargar la copia de seguridad desde GitHub: $e');
    }
  }


}


