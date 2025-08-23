import 'dart:async';
import 'package:app_bootsup/Vistadmin/vistaAdmin/pedidos/detallePedidos.dart';
import 'package:app_bootsup/Widgets/navegator.dart';
import 'package:app_bootsup/Widgets/redacted.dart';
import 'package:app_bootsup/Widgets/selector.dart';
import 'package:app_bootsup/Widgets/snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;

class PedidosPage extends StatefulWidget {
  const PedidosPage({Key? key}) : super(key: key);

  @override
  State<PedidosPage> createState() => _ComprasUsuarioPageState();
}

class _ComprasUsuarioPageState extends State<PedidosPage> {
  List<Map<String, dynamic>> _compras = [];
  List<Map<String, dynamic>> _comprasFiltradas = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String? filtroSeleccionado;
  String estadoSeleccionado = 'No atendidos';
  late final StreamSubscription _comprasSubscription;
  Map<String, String> _estadosAnteriores = {};

  @override
  void initState() {
    super.initState();
    _fetchComprasDelUsuario();
    _escucharComprasEnTiempoReal();
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'enviado':
        return const Color.fromARGB(255, 0, 0, 0);
      case 'preparación':
        return const Color.fromARGB(255, 0, 0, 0);
      case 'recibidos':
        return const Color.fromARGB(255, 0, 0, 0);
      case 'no atendido':
      default:
        return const Color.fromARGB(255, 0, 0, 0);
    }
  }

  void _escucharComprasEnTiempoReal() {
    _isLoading = true;
    _comprasSubscription = FirebaseFirestore.instance
        .collection('compras')
        .orderBy('fecha', descending: true) // ordenar por fecha descendente
        .snapshots()
        .listen((snapshot) async {
          List<Map<String, dynamic>> comprasList = [];

          for (var doc in snapshot.docs) {
            final compraData = doc.data();
            final usuarioId = compraData['usuarioId'];
            final compraId = doc.id;
            final nuevoEstado = (compraData['estado'] ?? 'Sin estado')
                .toString();

            // Verificar cambio de estado
            if (_estadosAnteriores.containsKey(compraId) &&
                _estadosAnteriores[compraId] != nuevoEstado) {
              final username = await _obtenerNombreUsuario(usuarioId);
              final colorEstado = _colorEstado(nuevoEstado);

              if (mounted) {
                SnackBarUtil.mostrarSnackBarPersonalizado(
                  context: context,
                  mensaje: 'El pedido de $username cambió a "$nuevoEstado"',
                  icono: Icons.info_outline,
                  colorFondo: colorEstado,
                );
              }
            }

            _estadosAnteriores[compraId] = nuevoEstado;

            if (usuarioId != null) {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(usuarioId)
                  .get();

              final userData = userDoc.data() ?? {};

              comprasList.add({
                'username': userData['username'] ?? 'Sin nombre',
                'profileImageUrl': userData['profileImageUrl'] ?? '',
                'estado': nuevoEstado,
                'fecha': compraData['fecha'] as Timestamp?,
                'usuarioId': usuarioId,
                'compraId': compraId, // <-- esto es el diferenciador
              });
            }
          }

          if (!mounted) return;
          setState(() {
            _compras = comprasList;
            _filtrarCompras();
            _isLoading = false;
          });
        });
  }

  Future<void> _fetchComprasDelUsuario() async {
    try {
      final comprasSnapshot = await FirebaseFirestore.instance
          .collection('compras')
          .get();

      List<Map<String, dynamic>> comprasList = [];

      for (var doc in comprasSnapshot.docs) {
        final compraData = doc.data();
        final usuarioId = compraData['usuarioId'];

        if (usuarioId != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(usuarioId)
              .get();

          final userData = userDoc.data() ?? {};

          comprasList.add({
            'username': userData['username'] ?? 'Sin nombre',
            'profileImageUrl': userData['profileImageUrl'] ?? '',
            'estado': compraData['estado'] ?? 'Sin estado',
            'fecha': compraData['fecha'] as Timestamp?,
            'usuarioId': usuarioId,
            'compraId': doc.id,
          });
        }
      }
      comprasList.sort((a, b) {
        final fechaA = (a['fecha'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final fechaB = (b['fecha'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return fechaA.compareTo(fechaB);
      });

      if (mounted) {
        setState(() {
          _compras = comprasList;
          _filtrarCompras();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al obtener compras: $e');
    }
  }

  void _filtrarCompras() {
    final textoBusqueda = _searchController.text.toLowerCase();

    setState(() {
      _comprasFiltradas = _compras.where((compra) {
        final username = (compra['username'] as String?)?.toLowerCase() ?? '';
        final coincideTexto = username.contains(textoBusqueda);

        final coincideEstado =
            estadoSeleccionado == 'Todos' ||
            compra['estado'] == estadoSeleccionado;

        return coincideTexto && coincideEstado;
      }).toList();
    });
  }

  Future<String> _obtenerNombreUsuario(String usuarioId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(usuarioId)
        .get();

    return (userDoc.data()?['username'] ?? 'Usuario') as String;
  }

  @override
  void dispose() {
    _comprasSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: theme.dividerColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text(
                      'Pedidos',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: false,
                        onChanged: (query) => _filtrarCompras(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontFamily: 'Afacad',
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar pedido...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                            fontFamily: 'Afacad',
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _searchController.clear();
                                      _filtrarCompras();
                                    });
                                  },
                                  child: Icon(
                                    Iconsax.close_circle,
                                    size: 24,
                                    color: theme.iconTheme.color,
                                  ),
                                )
                              : Icon(
                                  Iconsax.search_normal,
                                  size: 24,
                                  color: theme.iconTheme.color,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            PedidoFiltroSelector(
              onFiltroSelected: (estado) {
                estadoSeleccionado = estado;
                _filtrarCompras();
              },
            ),
            Expanded(
              child: _isLoading
                  ? const RedactedChat()
                  : _comprasFiltradas.isEmpty
                  ? Center(
                      child: Text(
                        'No hay pedidos en este apartado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(5),
                        itemCount: _comprasFiltradas.length,
                        itemBuilder: (context, index) {
                          final compra = _comprasFiltradas[index];
                          final fecha = (compra['fecha'] as Timestamp?)
                              ?.toDate();
                          final fechaFormateada = fecha != null
                              ? timeago.format(fecha, locale: 'es')
                              : 'Sin fecha';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundImage:
                                    (compra['profileImageUrl'] != null &&
                                        compra['profileImageUrl'].isNotEmpty)
                                    ? NetworkImage(compra['profileImageUrl'])
                                    : const AssetImage(
                                            'assets/images/empresa.png',
                                          )
                                          as ImageProvider,
                              ),
                              title: Text(
                                compra['username'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text('Fecha: $fechaFormateada'),
                              trailing: TextButton(
                                onPressed: () {
                                  navegarConSlideDerecha(
                                    context,
                                    EmpresaPedidosScreen(
                                      usuarioId: compra['usuarioId'],
                                      compraId: compra['compraId'],
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Color(0xFFA30000),
                                  elevation: 5.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                ),
                                child: Text(
                                  /* estadoSeleccionado == 'Rechazado'
                                            ? 'Ver'
                                            : estadoSeleccionado ==
                                                    'No atendido'
                                                ? 'Verificar'
                                                : */
                                  'Atender',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Afacad',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
