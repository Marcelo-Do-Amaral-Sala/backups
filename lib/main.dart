import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/sync.dart';  // Asegúrate de tener importada la clase SyncService
import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'conectivity.dart';  // Asegúrate de importar ConnectivityService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final SyncService syncService = SyncService();

  // Sincronización inicial de Firebase a SQLite
  try {
    await syncService.syncFirebaseToSQLite();
  } catch (e) {
    print("Error durante la sincronización: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final connectivityService = ConnectivityService();
        connectivityService.startConnectivityCheck();  // Inicia la verificación de conectividad
        return connectivityService;
      },
      child: App(),
    ),
  );
}
