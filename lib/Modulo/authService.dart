import 'dart:math';
import 'package:app_bootsup/VistaCliente/screePrincipal/mainScreens.dart';
import 'package:app_bootsup/Vistadmin/autenticacion/SplashScreen.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/mainScreenAdmin.dart';
import 'package:app_bootsup/Widgets/alertas.dart';
import 'package:app_bootsup/Widgets/bottombar.dart';
import 'package:app_bootsup/Widgets/navegator.dart';
import 'package:app_bootsup/Widgets/themeprovider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getUserMembership() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print("⚠️ No hay usuario autenticado");
        return null;
      }

      DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        print("⚠️ El documento del usuario no existe");
        return null;
      }

      final data = userDoc.data();
      final String? membresia = data?['membresia'];

      if (membresia == "Administrador" || membresia == "Clientes") {
        return membresia;
      } else {
        print("⚠️ Membresía no válida: $membresia");
        return null;
      }
    } catch (e) {
      print("❌ Error al obtener membresía: $e");
      return null;
    }
  }

  Future<void> navegarSegunMembresia(BuildContext context) async {
    final membresia = await getUserMembership();
    final user = _auth.currentUser;

    if (membresia == "Administrador") {
      navegarConSlideDerecha(context, MainScreenVinosAdmin(user: user));
    } else if (membresia == "Clientes") {
      navegarConSlideDerecha(context, MainScreenVinosClientes(user: user));
    } else {
      print("⚠️ No se pudo determinar membresía.");
    }
  }

  Future<User?> checkSignInStatus(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) {
      await signInWithGoogle(context);
      return _auth.currentUser;
    } else {
      return user;
    }
  }

  Future<bool> signInWithEmail(
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      await showCustomDialog(
        context: context,
        title: 'Atención',
        message: 'Complete todos los campos',
        confirmButtonText: 'Cerrar',
      );
      return false;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      await showCustomDialog(
        context: context,
        title: 'Atención',
        message: 'Formato de correo inválido',
        confirmButtonText: 'Cerrar',
      );
      return false;
    }

    try {
      // 🔹 Iniciar sesión con email y contraseña
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        await showCustomDialog(
          context: context,
          title: 'Error',
          message: 'No se pudo obtener la información del usuario.',
          confirmButtonText: 'Cerrar',
        );
        return false;
      }

      // 🔹 Verificar que el correo esté validado
      if (!user.emailVerified) {
        await showCustomDialog(
          context: context,
          title: 'Correo no verificado',
          message: 'Por favor verifica tu correo antes de iniciar sesión.',
          confirmButtonText: 'Cerrar',
        );
        return false;
      }

      // 🔹 Consultar el documento del usuario en Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        // 🔹 Usuario existente → navegar según membresía
        await navegarSegunMembresia(context);
      }

      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Correo o contraseña incorrectos';
      if (e.code == 'user-disabled') {
        errorMessage = 'Cuenta deshabilitada, contacte soporte';
      }

      await showCustomDialog(
        context: context,
        title: 'Error de autenticación',
        message: errorMessage,
        confirmButtonText: 'Cerrar',
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final user = userCredential.user!;
      String email = user.email!;
      String displayName = user.displayName ?? 'Usuario';

      // Verificamos si el usuario ya existe en la colección
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String usernameWithNumber;

      if (userDoc.exists) {
        // 🔹 Usuario existente → validar membresía
        usernameWithNumber = userDoc['username'];
        await navegarSegunMembresia(context);
      } else {
        // 🔹 Usuario nuevo → crear doc y mandar a MainScreenVinosClientes
        String randomNumber = Random()
            .nextInt(999999)
            .toString()
            .padLeft(6, '0');
        usernameWithNumber = '$displayName#$randomNumber';

        String profileImageUrl = user.photoURL ?? '';

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': usernameWithNumber,
          'email': email,
          'profileImageUrl': profileImageUrl,
          'direccion': '',
          'dni': '',
          'telefono': '',
          'membresia': 'Clientes',
        });

        // 🔹 Navegar directo a Clientes
        navegarConSlideDerecha(context, MainScreenVinosClientes(user: user));
      }

      return true;
    } catch (e) {
      print('Error en login: $e');
      if (e is PlatformException && e.code == 'sign_in_canceled') {
        return false;
      }
      await showCustomDialog(
        context: context,
        title: 'Error de autenticación',
        message: 'No se pudo iniciar sesión con Google. Inténtalo nuevamente.',
        confirmButtonText: 'Cerrar',
      );
      return false;
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      await _auth.signOut();
      await _googleSignIn.signOut();
      ImageCacheHelper.clearCache();
      themeProvider.resetTheme();
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (route) => false,
      );
    } catch (e) {}
  }
}
