import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConnectivityService extends ChangeNotifier {
  String _connectionStatus = "Desconocido";  // Estado de la conexión
  bool _isCheckingInternet = false;  // Para evitar múltiples verificaciones

  String get connectionStatus => _connectionStatus;

  // Verifica si el dispositivo tiene acceso a Internet
  Future<bool> _checkInternetAccess() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));
      if (response.statusCode == 200) {
        return true;  // Conexión a Internet
      } else {
        return false;  // No hay acceso
      }
    } on SocketException catch (_) {
      return false;  // No hay acceso a Internet
    }
  }
  void _initializeConnectivity() {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> connectivityResults) {
      // Verifica si la lista no está vacía y pasa el primer valor
      if (connectivityResults.isNotEmpty) {
        _updateConnectionStatus(connectivityResults[0]);
      }
    });
  }
  // Actualiza el estado de la conexión
  void _updateConnectionStatus(ConnectivityResult connectivityResult) async {
    String newStatus = "Desconocido";

    if (connectivityResult == ConnectivityResult.none) {
      newStatus = "Sin conexión a Internet";
    } else {
      newStatus = "Conexión a red disponible";
      if (!_isCheckingInternet) {
        _isCheckingInternet = true;
        bool isConnected = await _checkInternetAccess();
        newStatus = isConnected
            ? "Conexión a Internet disponible"
            : "Conexión a red, pero sin acceso a Internet";
        _isCheckingInternet = false;
      }
    }

    if (_connectionStatus != newStatus) {
      _connectionStatus = newStatus;
      notifyListeners();  // Notifica a los listeners cuando el estado cambia
    }
    print('ESTADO DE CONEXION: $newStatus');
  }

  // Método para comenzar la verificación de conectividad al inicio
  void startConnectivityCheck() {
    _initializeConnectivity();  // Inicia la escucha de cambios en la conectividad
  }
}
