import 'dart:async';
import 'package:app_bootsup/Modulo/authService.dart';
import 'package:app_bootsup/Modulo/estadisticaService.dart';
import 'package:app_bootsup/Widgets/cajasdetexto.dart';
import 'package:app_bootsup/Widgets/themeprovider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  _PerfilState createState() => _PerfilState();
}

class _PerfilState extends State<PerfilPage> {
  String? _firestoreUsername;
  String? _firestoreProfileImageUrl;
  User? _user = FirebaseAuth.instance.currentUser;

  bool _showCameraIcon = false;
  final _comprasService = EstadisticaService();

  Map<String, int> _comprasPorDia = {};
  double _ingresosTotales = 0;
  double _descuentosTotales = 0;
  double _impuestosTotales = 0;
  double _subtotalPromedio = 0;
  int _totalCompras = 0;
  Map<String, int> _topProductos = {};
  Map<String, int> _topCategorias = {};
  StreamSubscription<Map<String, dynamic>>? _statsSubscription;

  @override
  void initState() {
    super.initState();

    _checkSignInStatus();
    _escucharDatosTiempoReal();
  }

  void _escucharDatosTiempoReal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _statsSubscription = _comprasService
        .obtenerEstadisticasComprasStream()
        .listen((resultado) {
          setState(() {
            _comprasPorDia = Map<String, int>.from(resultado['comprasPorDia']);
            _ingresosTotales = (resultado['ingresosTotales'] as num).toDouble();
            _descuentosTotales = (resultado['descuentosTotales'] as num)
                .toDouble();
            _impuestosTotales = (resultado['impuestosTotales'] as num)
                .toDouble();
            _subtotalPromedio = (resultado['subtotalPromedio'] as num)
                .toDouble();
            _totalCompras = resultado['totalCompras'];
            _topProductos = Map<String, int>.from(resultado['topProductos']);
            _topCategorias = Map<String, int>.from(resultado['topCategorias']);
          });
        });
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _user != null
          ? SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileContainer(),
                      buildLineChartCard(
                        'Compras por día',
                        _comprasPorDia,
                        context,
                      ),
                      const SizedBox(height: 20),
                      buildEstadisticaTile(
                        context,
                        'Total de compras',
                        '$_totalCompras',
                      ),
                      buildEstadisticaTile(
                        context,
                        'Ingresos totales',
                        'S/ ${_ingresosTotales.toStringAsFixed(2)}',
                      ),
                      buildEstadisticaTile(
                        context,
                        'Descuentos totales',
                        'S/ ${_descuentosTotales.toStringAsFixed(2)}',
                      ),
                      buildEstadisticaTile(
                        context,
                        'Impuestos totales',
                        'S/ ${_impuestosTotales.toStringAsFixed(2)}',
                      ),
                      buildEstadisticaTile(
                        context,
                        'Subtotal promedio',
                        'S/ ${_subtotalPromedio.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 20),
                      buildTopList(
                        context,
                        'Top productos vendidos',
                        _topProductos,
                      ),
                      const SizedBox(height: 16),
                      buildTopList(context, 'Top categorías', _topCategorias),
                    ],
                  ),
                ),
              ),
            )
          : const Center(),
    );
  }

  Widget _buildProfileContainer() {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
      padding: const EdgeInsets.fromLTRB(5, 0, 0, 5),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _user!.email != null && _user!.email!.endsWith('@gmail.com')
                ? null
                : () {
                    setState(() {
                      _showCameraIcon = !_showCameraIcon;
                    });
                  },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: ClipOval(
                    child:
                        _firestoreProfileImageUrl != null ||
                            _user?.photoURL != null
                        ? CachedNetworkImage(
                            imageUrl:
                                _firestoreProfileImageUrl ?? _user!.photoURL!,
                            imageBuilder: (context, imageProvider) =>
                                CircleAvatar(
                                  backgroundImage: imageProvider,
                                  radius: 26,
                                ),
                            placeholder: (context, url) => const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                color: Color(0xFFFFAF00),
                                strokeWidth: 2.5,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              LucideIcons.user2,
                              size: 36,
                              color: theme.iconTheme.color,
                            ),
                          )
                        : const CircularProgressIndicator(
                            color: Color(0xFFFFAF00),
                            strokeWidth: 2.5,
                          ),
                  ),
                ),
                if (_showCameraIcon)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                      ),
                      padding: const EdgeInsets.all(5),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // 🔹 Info de usuario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _firestoreUsername ??
                      _user!.displayName ??
                      'Cargando usuario',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatText(
                    _user?.email ?? 'Cargando correo electrónico',
                    maxLength: 29,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 🔹 Botones de acción
          Row(
            children: [
              _buildCircleIconButton(
                icon: themeProvider.themeMode == ThemeMode.dark
                    ? Iconsax.sun_1
                    : Iconsax.moon,
                tooltip: 'Cambiar tema',
                onPressed: () {
                  final isDark = themeProvider.themeMode == ThemeMode.dark;
                  themeProvider.setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildCircleIconButton(
                icon: Iconsax.logout,
                tooltip: 'Cerrar sesión',
                onPressed: () async {
                  User? currentUser = FirebaseAuth.instance.currentUser;
                  await AuthService().signOut(context, currentUser?.uid);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withOpacity(0.08),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: theme.colorScheme.primary),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
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
}
