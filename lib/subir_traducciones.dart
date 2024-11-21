import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TranslationUploader extends StatefulWidget {
  @override
  _TranslationUploaderState createState() => _TranslationUploaderState();
}

class _TranslationUploaderState extends State<TranslationUploader> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Simulamos un archivo JSON de traducciones
  Map<String, Map<String, String>> translations = {
    "es": {
      "key_1": "Hola",
      "key_2": "Adiós",
      "key_3": "Perro",
      "key_4": "Gato",
      "key_5": "Amigo",
      "key_6": "Casa",
      "key_7": "Coche",
      "key_8": "Trabajo",
      "key_9": "Comida",
      "key_10": "Bebida",
      "key_11": "Feliz",
      "key_12": "Triste",
      "key_13": "Buenos días",
      "key_14": "Buenas noches",
      "key_15": "Gracias",
      "key_16": "Por favor",
      "key_17": "Disculpa",
      "key_18": "Perdón",
      "key_19": "Te quiero",
      "key_20": "Bienvenido",
      "key_21": "Adiós",
      "key_22": "Escuela",
      "key_23": "Familia",
      "key_24": "Trabajo",
      "key_25": "Amor",
      "key_26": "Día",
      "key_27": "Noche",
      "key_28": "Feliz cumpleaños",
      "key_29": "Te extraño",
      "key_30": "Nos vemos pronto"
    },
    "en": {
      "key_1": "Hello",
      "key_2": "Goodbye",
      "key_3": "Dog",
      "key_4": "Cat",
      "key_5": "Friend",
      "key_6": "House",
      "key_7": "Car",
      "key_8": "Work",
      "key_9": "Food",
      "key_10": "Drink",
      "key_11": "Happy",
      "key_12": "Sad",
      "key_13": "Good morning",
      "key_14": "Good night",
      "key_15": "Thank you",
      "key_16": "Please",
      "key_17": "Sorry",
      "key_18": "Excuse me",
      "key_19": "I love you",
      "key_20": "Welcome",
      "key_21": "Goodbye",
      "key_22": "School",
      "key_23": "Family",
      "key_24": "Job",
      "key_25": "Love",
      "key_26": "Day",
      "key_27": "Night",
      "key_28": "Happy birthday",
      "key_29": "I miss you",
      "key_30": "See you soon"
    },
    "fr": {
      "key_1": "Bonjour",
      "key_2": "Au revoir",
      "key_3": "Chien",
      "key_4": "Chat",
      "key_5": "Ami",
      "key_6": "Maison",
      "key_7": "Voiture",
      "key_8": "Travail",
      "key_9": "Nourriture",
      "key_10": "Boisson",
      "key_11": "Heureux",
      "key_12": "Triste",
      "key_13": "Bonjour",
      "key_14": "Bonne nuit",
      "key_15": "Merci",
      "key_16": "S'il vous plaît",
      "key_17": "Désolé",
      "key_18": "Excusez-moi",
      "key_19": "Je t'aime",
      "key_20": "Bienvenue",
      "key_21": "Au revoir",
      "key_22": "École",
      "key_23": "Famille",
      "key_24": "Travail",
      "key_25": "Amour",
      "key_26": "Jour",
      "key_27": "Nuit",
      "key_28": "Joyeux anniversaire",
      "key_29": "Tu me manques",
      "key_30": "À bientôt"
    },
    "pt": {
      "key_1": "Olá",
      "key_2": "Adeus",
      "key_3": "Cão",
      "key_4": "Gato",
      "key_5": "Amigo",
      "key_6": "Casa",
      "key_7": "Carro",
      "key_8": "Trabalho",
      "key_9": "Comida",
      "key_10": "Bebida",
      "key_11": "Feliz",
      "key_12": "Triste",
      "key_13": "Bom dia",
      "key_14": "Boa noite",
      "key_15": "Obrigado",
      "key_16": "Por favor",
      "key_17": "Desculpa",
      "key_18": "Com licença",
      "key_19": "Eu te amo",
      "key_20": "Bem-vindo",
      "key_21": "Adeus",
      "key_22": "Escola",
      "key_23": "Família",
      "key_24": "Trabalho",
      "key_25": "Amor",
      "key_26": "Dia",
      "key_27": "Noite",
      "key_28": "Feliz aniversário",
      "key_29": "Sinto sua falta",
      "key_30": "Até logo"
    },
    "de": {
      "key_1": "Hallo",
      "key_2": "Tschüss",
      "key_3": "Hund",
      "key_4": "Katze",
      "key_5": "Freund",
      "key_6": "Haus",
      "key_7": "Auto",
      "key_8": "Arbeit",
      "key_9": "Essen",
      "key_10": "Trinken",
      "key_11": "Glücklich",
      "key_12": "Traurig",
      "key_13": "Guten Morgen",
      "key_14": "Gute Nacht",
      "key_15": "Danke",
      "key_16": "Bitte",
      "key_17": "Entschuldigung",
      "key_18": "Entschuldigen Sie",
      "key_19": "Ich liebe dich",
      "key_20": "Willkommen",
      "key_21": "Tschüss",
      "key_22": "Schule",
      "key_23": "Familie",
      "key_24": "Arbeit",
      "key_25": "Liebe",
      "key_26": "Tag",
      "key_27": "Nacht",
      "key_28": "Alles Gute zum Geburtstag",
      "key_29": "Ich vermisse dich",
      "key_30": "Bis bald"
    }
  };

  Future<void> uploadTranslations() async {
    try {
      for (var language in translations.keys) {
        await _firestore
            .collection('traducciones')
            .doc(language)
            .set(translations[language]!);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Traducciones subidas correctamente")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al subir traducciones")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Subir Traducciones')),
      body: Center(
        child: ElevatedButton(
          onPressed: uploadTranslations,
          child: Text('Subir Traducciones a Firestore'),
        ),
      ),
    );
  }
}
