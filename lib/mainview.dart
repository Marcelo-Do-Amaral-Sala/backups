import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/sync.dart';

import 'conectivity.dart';
import 'database_helper_translations.dart';
import 'database_helper_usuarios.dart';

class TranslationScreen extends StatefulWidget {
  @override
  _TranslationScreenState createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final SyncService _syncService = SyncService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool isLoading = false;
  String statusMessage = 'Listo para hacer la copia de seguridad';
  String? _selectedLanguage;
  Map<String, String> _translations = {};
  List<Map<String, dynamic>> _users = []; // Lista para almacenar los usuarios

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _initializeDatabaseUsers();
    _fetchUsers();
    _showStoredTranslations();
    // Establecer el idioma seleccionado por defecto como 'es'
    _selectedLanguage = 'es';
    _loadTranslations();
    _fetchLocalTranslations('es'); // Cargar las traducciones en español
  }

  Future<void> _initializeDatabase() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        debugPrint("Inicializando base de datos para Móviles...");
        await DatabaseHelper().initializeDatabase();
      } else {
        throw UnsupportedError(
            'Plataforma no soportada para la base de datos.');
      }
      debugPrint("Base de datos inicializada correctamente.");
    } catch (e) {
      debugPrint("Error al inicializar la base de datos: $e");
    }
  }

  Future<void> _initializeDatabaseUsers() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await DatabaseHelperUsers().initializeDatabaseUsers();
      } else {
        throw UnsupportedError(
            'Plataforma no soportada para la base de datos.');
      }
      debugPrint("Base de datos inicializada correctamente. USUARIOS");
    } catch (e) {
      debugPrint("Error al inicializar la base de datos: $e");
    }
  }

  // Método para obtener los usuarios desde la base de datos
  Future<void> _fetchUsers() async {
    DatabaseHelperUsers dbHelperU = DatabaseHelperUsers();
    try {
      final users = await dbHelperU.getAllUsers();

      setState(() {
        _users = List<Map<String, dynamic>>.from(users); // Asegúrate de que sea una lista mutable
        if (_users.isEmpty) {
          statusMessage = "No hay usuarios disponibles en la base de datos.";
        }
      });
    } catch (e) {
      setState(() {
        statusMessage = "Error al cargar los usuarios: $e";
      });
      print("Error al obtener los usuarios: $e");
    }
  }


  void _loadTranslations() async {
    await _syncService.syncFirebaseToSQLite();
    if (_selectedLanguage != null) {
      _fetchLocalTranslations(_selectedLanguage!);
    }
  }

  void _fetchLocalTranslations(String language) async {
    final translations = await _dbHelper.getTranslationsByLanguage(language);
    setState(() {
      _translations = Map<String, String>.from(translations);
      if (_translations.isEmpty) {
        statusMessage =
            "No hay datos disponibles, la base de datos está vacía.";
        print("La base de datos está vacía.");
      }
    });
  }

  void _showStoredTranslations() async {
    final allTranslations = await _dbHelper.getAllTranslations();
    if (allTranslations.isEmpty) {
      print("No hay traducciones almacenadas.");
    } else {
      for (var translation in allTranslations) {
        print(translation);
      }
    }
  }

  Future<void> _uploadBackup() async {
    try {
      setState(() {
        isLoading = true;
        statusMessage = 'Subiendo la copia de seguridad a GitHub...';
      });

      // Obtén la instancia del helper
      DatabaseHelper dbHelper = DatabaseHelper();

      await dbHelper.initializeDatabase();

      print('BASE DE DATOS INICIALIZADA');

      // Espera antes de subir el backup
      await Future.delayed(Duration(seconds: 2));

      print('SUBIENDO BACKUP...');

      // Realiza la subida del backup a GitHub
      await DatabaseHelperUsers.uploadDatabaseToGitHub();

      // Reabrir la base de datos después de subir el backup
      await dbHelper.initializeDatabase();

      setState(() {
        isLoading = false;
        statusMessage = 'Copia de seguridad subida exitosamente a GitHub';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        statusMessage = 'Error al subir la copia de seguridad: $e';
      });
    }
  }

  Future<void> _deleteDatabase() async {
    final dbHelperU = DatabaseHelperUsers();
    try {
      // Obtener la instancia de la base de datos
      final db = await dbHelperU.database;

      // Verificar si la base de datos está abierta antes de cerrarla
      if (db.isOpen) {
        debugPrint("Database open (before close): ${db.isOpen}");
        await db.close();
        debugPrint(
            "Database open (after close): ${db.isOpen}"); // Confirmará que se ha cerrado
      }

      // Eliminar el archivo de la base de datos
      await dbHelperU.deleteDatabaseFile();

      // Mostrar un mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Base de datos eliminada con éxito.')),
      );

      // Limpiar las traducciones y actualizar el estado
      setState(() {
        _users.clear();
        _fetchUsers();
      });

      print("Base de datos eliminada correctamente.");

      // Asegurarse de inicializar correctamente la base de datos después de eliminarla
      await dbHelperU
          .initializeDatabaseUsers(); // Asegúrate de que la base de datos esté abierta correctamente

      // Verificar si la base de datos está abierta
      final newDb = await dbHelperU.database;
      debugPrint("Database open (after initialization): ${newDb.isOpen}");
    } catch (e) {
      print("Error al eliminar la base de datos: $e");
    }
  }

  Future<void> _downloadBackup() async {
    try {
      final dbHelper = DatabaseHelperUsers();
      final db = await dbHelper.database;

      // Imprimir el estado actual de la base de datos antes de hacer cualquier cosa
      debugPrint(
          "Estado de la base de datos antes de la inicialización: ${db.isOpen ? 'Abierta' : 'Cerrada'}");

      setState(() {
        isLoading = true;
        statusMessage = 'Descargando la copia de seguridad desde GitHub...';
      });

      // Inicializar la base de datos (asegúrate de que esté abierta después de la eliminación)
      await dbHelper.initializeDatabaseUsers();

      // Verificar si la base de datos está abierta después de la inicialización
      if (!db.isOpen) {
        throw Exception(
            'La base de datos no se pudo abrir después de la inicialización');
      }

      debugPrint("Database open (after re-opening): ${db.isOpen}");

      // Descargar la copia de seguridad desde GitHub
      await DatabaseHelperUsers.downloadDatabaseFromGitHub();

      // Verificar nuevamente si la base de datos sigue abierta después de la descarga
      final dbAfterDownload = await dbHelper.database;
      debugPrint(
          "Estado de la base de datos después de la descarga: ${dbAfterDownload.isOpen ? 'Abierta' : 'Cerrada'}");

      if (!dbAfterDownload.isOpen) {
        throw Exception('La base de datos está cerrada después de la descarga');
      }

      // Actualizar las traducciones después de la descarga
      _fetchUsers();

      setState(() {
        isLoading = false;
        statusMessage = 'Copia de seguridad descargada exitosamente';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          statusMessage = 'Error al descargar la copia de seguridad: $e';
        });
      }
      print("Error durante la descarga del backup: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivityStatus =
        Provider.of<ConnectivityService>(context).connectionStatus;

    return Scaffold(
      appBar: AppBar(
        title: Text('Traducciones'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width * 0.5,
                child: Column(
                  children: [
                    // Mostrar el estado de la conexión
                    Text('$connectivityStatus'),
                    SizedBox(height: 20),
                    // Dropdown para seleccionar idioma
                    DropdownButton<String>(
                      value: _selectedLanguage,
                      hint: Text("Selecciona un idioma"),
                      items: ['es', 'en', 'fr', 'pt', 'de', 'zh', 'it']
                          .map((lang) => DropdownMenuItem<String>(
                                value: lang,
                                child: Text(lang.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLanguage = value;
                          _translations.clear();
                        });
                        if (value != null) {
                          _fetchLocalTranslations(value);
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    // Mostrar las traducciones en una lista
                    Expanded(
                      child: _translations.isEmpty
                          ? Center(child: Text("NO HAY DATOS DISPONIBLES"))
                          : ListView.builder(
                              itemCount: _translations.length,
                              itemBuilder: (context, index) {
                                String key =
                                    _translations.keys.elementAt(index);
                                return ListTile(
                                  title: Text(_translations[key]!),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: Column(
                    children: [
                      Text(statusMessage),
                      Expanded(
                        child: _users.isEmpty
                            ? Center(child: Text("No hay usuarios disponibles"))
                            : ListView.builder(
                                itemCount: _users.length,
                                itemBuilder: (context, index) {
                                  String userName = _users[index]['name'];
                                  return ListTile(
                                    title: Text(
                                        userName), // Mostrar el nombre del usuario
                                  );
                                },
                              ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _uploadBackup,
                        child: Text('Hacer copia de seguridad'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TranslationScreen()),
                          );
                        },
                        child: Text('Refrescar página'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _downloadBackup();
                        },
                        child: Text('RECUPERAR DATABASE'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          // Eliminar la base de datos
                          await _deleteDatabase();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TranslationScreen()),
                          );
                        },
                        child: Text('BORRAR DATABASE'),
                      ),

                    ],
                  )),
            ],
          )),
    );
  }
}
