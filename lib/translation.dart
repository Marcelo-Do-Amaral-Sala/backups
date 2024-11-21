import 'package:cloud_firestore/cloud_firestore.dart';

class TranslationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Descarga todos los documentos de la colección `TRADUCCIONES`.
  Future<Map<String, dynamic>> fetchTranslations() async {
    try {
      // Obtiene todos los documentos en la colección `TRADUCCIONES`.
      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await _firestore.collection('traducciones').get();

      // Convierte los documentos en un Map<String, dynamic>.
      Map<String, dynamic> translations = {};
      for (var doc in snapshot.docs) {
        translations[doc.id] = doc.data(); // doc.id es el idioma ('es', 'en', etc.).
      }

      return translations;
    } catch (e) {
      print("Error al descargar las traducciones: $e");
      throw Exception("Error al descargar las traducciones: $e");
    }
  }

}
