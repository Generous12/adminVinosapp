import 'package:app_bootsup/Modulo/crritoServiceV.dart';
import 'package:app_bootsup/Modulo/usuarioService.dart';
import 'package:app_bootsup/VistaCliente/screePrincipal/mainScreens.dart';
import 'package:app_bootsup/Vistadmin/autenticacion/SinConexion.dart';
import 'package:app_bootsup/Vistadmin/autenticacion/SplashScreen.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/mainScreenAdmin.dart';
import 'package:app_bootsup/Widgets/themeprovider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 0, 0, 0),
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarritoServiceVinos()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isConnected = true;
  bool _verificacionCompleta = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnectivity();
      _listenToAuthChanges();
      Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint("❌ Error al verificar la conexión: $e");
      _updateConnectionStatus(ConnectivityResult.none);
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final bool isNowConnected =
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi;

    if (_isConnected != isNowConnected) {
      _isConnected = isNowConnected;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!_isConnected) {
          // 🔹 Sin conexión → Pantalla NoInternet
          _navigatorKey.currentState?.pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => NoInternetScreen(),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        } else {
          // 🔹 Con conexión → Verificar membresía y navegar
          await _decidirPantalla();
        }
      });
    }
  }

  void _listenToAuthChanges() {
    _auth.authStateChanges().listen((user) async {
      if (mounted) {
        setState(() {
          _verificacionCompleta = true;
        });
      }
      if (user != null && user.emailVerified) {
        await _decidirPantalla();
      } else {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'MontserratAlternates',
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFA30000),
          onPrimary: Color(0xFFFAFAFA),
          surface: Color(0xFFFAFAFA),
          onSurface: Colors.black,
        ),
        scaffoldBackgroundColor: Color(0xFFFAFAFA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFAFAFA),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomAppBarTheme: BottomAppBarThemeData(color: Color(0xFFFAFAFA)),
        iconTheme: const IconThemeData(color: Colors.black),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'MontserratAlternates',
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFA30000),
          onPrimary: Colors.black,
          background: Color(0xFF121212),
          onBackground: Colors.white,
        ),
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomAppBarTheme: BottomAppBarThemeData(color: Color(0xFF121212)),
        iconTheme: const IconThemeData(color: Colors.white),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      home: !_verificacionCompleta
          ? const SplashScreen()
          : const SplashScreen(),
    );
  }
}
