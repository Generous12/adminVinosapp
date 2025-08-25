import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({Key? key}) : super(key: key);

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _isLoading = false;

  Future<void> _revisarConexion() async {
    setState(() => _isLoading = true);

    try {
      final result = await Connectivity().checkConnectivity();
      final bool conectado =
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi;

      if (conectado) {
      } else {}
    } catch (e) {
      debugPrint("❌ Error verificando conexión: $e");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 248, 248),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Image.asset('assets/images/inter.png', width: 200, height: 200),
            const SizedBox(height: 20),
            const Text(
              'Sin conexión a Internet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Por favor, verifica tu conexión e inténtalo nuevamente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 40),

            // 🔹 Botón "Actualizar"
            _isLoading
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: _revisarConexion,
                    child: const Text(
                      "Actualizar",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
