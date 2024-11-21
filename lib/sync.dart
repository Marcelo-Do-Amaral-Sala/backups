
import 'package:untitled/translation.dart';

import 'database_helper_translations.dart';

class SyncService {
  final TranslationService _translationService = TranslationService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Sincroniza las traducciones de Firebase con SQLite.
  Future<void> syncFirebaseToSQLite() async {
    try {
      // Paso 1: Descargar traducciones desde Firebase
      final Map<String, dynamic> firebaseTranslations =
      await _translationService.fetchTranslations();

      // Paso 2: Guardar las traducciones en SQLite
      await _databaseHelper.insertOrUpdateMultipleTranslations(firebaseTranslations);

      print("Sincronización completada: datos guardados localmente.");
    } catch (e) {
      print("Error durante la sincronización: $e");
    }
  }

}
