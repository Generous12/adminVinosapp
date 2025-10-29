import 'dart:math';
import 'package:app_bootsup/Modulo/authService.dart';
import 'package:app_bootsup/VistaCliente/screePrincipal/Comprasrealizadas/listaComprasV.dart';
import 'package:app_bootsup/VistaCliente/screePrincipal/atencionCliente/atencionClient.dart';
import 'package:app_bootsup/VistaCliente/screePrincipal/atencionCliente/ayuda.dart';
import 'package:app_bootsup/VistaCliente/screePrincipal/menuOpcionesPerfil/menu.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/temaoscuro.dart';
import 'package:app_bootsup/Widgets/boton.dart';
import 'package:app_bootsup/Widgets/navegator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_initicon/flutter_initicon.dart';
import 'package:iconsax/iconsax.dart';

class PerfilPageVinosC extends StatefulWidget {
  const PerfilPageVinosC({super.key});

  @override
  _PerfilState createState() => _PerfilState();
}

class _PerfilState extends State<PerfilPageVinosC> {
  String? _firestoreUsername;
  String? _firestoreProfileImageUrl;
  User? _user = FirebaseAuth.instance.currentUser;

  bool _showCameraIcon = false;
  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    if (mounted) {
      setState(() {
        _user = _user;
      });
      await _fetchFirestoreData();
    }
  }

  Future<void> _fetchFirestoreData() async {
    if (_user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        setState(() {
          _firestoreUsername = userDoc['username'];
          _firestoreProfileImageUrl = userDoc['profileImageUrl'];
        });
      }
    } catch (e) {
      if (mounted) {
        print("Error al obtener los datos de Firestore: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _user != null
          ? SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    child: _buildProfileContainer(),
                  ),
                  FullWidthMenuTile(
                    option: MenuOption(
                      title: 'Configuracion de la cuenta',
                      description: 'Ver y editar la informacion de la cuenta.',
                      icon: Iconsax.user,
                      onTap: () {
                        navegarConSlideDerecha(context, MenuScreen());
                      },
                    ),
                  ),
                  FullWidthMenuTile(
                    option: MenuOption(
                      title: 'Personalización de la cuenta',
                      description: 'Cambia el tema y colores de la app.',
                      icon: Iconsax.setting_2,
                      onTap: () {
                        navegarConSlideDerecha(
                          context,
                          const PersonalizacionCuentaScreen(),
                        );
                      },
                    ),
                  ),
                  FullWidthMenuTile(
                    option: MenuOption(
                      title: 'Compras',
                      description: 'Ver tus compras realizadas.',
                      icon: Iconsax.shopping_cart,
                      onTap: () {
                        navegarConSlideDerecha(
                          context,
                          HistorialComprasScreenVinos(),
                        );
                      },
                    ),
                  ),
                  FullWidthMenuTile(
                    option: MenuOption(
                      title: 'Atención al Cliente',
                      description: 'Contáctanos para resolver tus dudas',
                      icon: Iconsax.support,
                      onTap: () {
                        navegarConSlideDerecha(
                          context,
                          AtencionClienteScreenVinos(),
                        );
                      },
                    ),
                  ),
                  FullWidthMenuTile(
                    option: MenuOption(
                      title: 'Ayuda',
                      description: 'Encuentra respuestas a tus preguntas',
                      icon: Iconsax.info_circle,
                      onTap: () {
                        navegarConSlideDerecha(context, AyudaScreenVinos());
                      },
                    ),
                  ),
                  FullWidthMenuTile(
                    option: MenuOption(
                      title: 'Cerrar Sesión',
                      description: 'Salir de la cuenta',
                      icon: Iconsax.logout,
                      onTap: () {
                        if (!mounted) return;
                        User? currentUser = FirebaseAuth.instance.currentUser;
                        AuthService().signOut(context, currentUser?.uid);
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            )
          : const Center(),
    );
  }

  Widget _buildProfileContainer() {
    final theme = Theme.of(context);

    final String initText = (_firestoreUsername?.trim().isNotEmpty ?? false)
        ? _firestoreUsername!
        : (_user?.displayName?.trim().isNotEmpty ?? false)
        ? _user!.displayName!
        : 'C';

    final String? imageUrl = _firestoreProfileImageUrl ?? _user?.photoURL;

    final Color avatarColor = Color(
      (Random().nextDouble() * 0xFFFFFF).toInt(),
    ).withOpacity(1.0);

    return SizedBox(
      width: double.infinity,
      child: Material(
        borderRadius: BorderRadius.circular(0),
        color: theme.scaffoldBackgroundColor,
        child: Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'profile-image-hero',
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: avatarColor,
                      child: imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              imageBuilder: (context, imageProvider) =>
                                  CircleAvatar(
                                    backgroundImage: imageProvider,
                                    radius: 40,
                                  ),
                              placeholder: (context, url) => const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFA30000),
                                  strokeWidth: 3,
                                ),
                              ),
                              errorWidget: (context, url, error) => Initicon(
                                text: initText,
                                size: 80,

                                backgroundColor: avatarColor,
                              ),
                            )
                          : Initicon(
                              text: initText,
                              size: 80,

                              backgroundColor: avatarColor,
                            ),
                    ),
                  ),
                  if (_showCameraIcon)
                    Positioned(
                      bottom: 27,
                      right: 27,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.photo_camera_outlined,
                          color: Color(0xFFA30000),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    initText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _user?.email ?? 'Cargando correo electrónico',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
