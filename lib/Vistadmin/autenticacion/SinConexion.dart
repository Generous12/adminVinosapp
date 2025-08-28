import 'package:app_bootsup/Modulo/crritoServiceV.dart';
import 'package:app_bootsup/VistaCliente/screePrincipal/mainScreens.dart';
import 'package:app_bootsup/Vistadmin/autenticacion/SplashScreen.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/mainScreenAdmin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({Key? key}) : super(key: key);

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _isLoading = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _revisarConexion() async {
    setState(() => _isLoading = true);

    try {
      final result = await Connectivity().checkConnectivity();
      final bool conectado =
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi;

      if (!conectado) {
        // 🔹 Sin conexión → Pantalla NoInternet
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => NoInternetScreen(),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        });
      } else {
        // 🔹 Con conexión → Verificar membresía y navegar
        await _decidirPantalla();
      }
    } catch (e) {
      debugPrint("❌ Error verificando conexión: $e");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => NoInternetScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _decidirPantalla() async {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) {
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
      return;
    }

    // 🔹 Configurar el UID del carrito aquí
    final carrito = Provider.of<CarritoServiceVinos>(
      _navigatorKey.currentContext!,
      listen: false,
    );
    carrito.setUsuario(user.uid); // <--- MUY IMPORTANTE

    final membresia = await _getUserMembership();
    if (membresia == "Administrador") {
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainScreenVinosAdmin(user: user)),
        (route) => false,
      );
    } else if (membresia == "Clientes") {
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainScreenVinosClientes(user: user)),
        (route) => false,
      );
    } else {
      debugPrint("⚠️ Membresía desconocida o nula.");
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  Future<String?> _getUserMembership() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data();
      final String? membresia = data?['membresia'];

      if (membresia == "Administrador" || membresia == "Clientes") {
        return membresia;
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error al obtener membresía: $e");
      return null;
    }
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
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
