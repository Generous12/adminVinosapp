// ignore_for_file: unused_field

import 'package:app_bootsup/Modulo/inventarioService.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/inventario/Video/reels.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/inventario/actualizar.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/inventario/eliminar.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/inventario/publicaciones.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/inventario/registrarProducto.dart';
import 'package:app_bootsup/Widgets/boton.dart';
import 'package:app_bootsup/Widgets/navegator.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final InventarioService _inventarioService = InventarioService();
  Map<String, int> _productosPorCategoria = {};
  bool _isLoading = true;

  final Map<String, Color> _categoriaColor = {
    'Vino Tinto': const Color(0xFFA30000),
    'Vino Blanco': Colors.white,
    'Pisco Italia': Colors.black,
    'Pisco Acholado': const Color(0xFFA30000),
    'Pisco Mosto Verde': Colors.white,
    'Pisco Quebranta': Colors.black,
  };

  @override
  void initState() {
    super.initState();
    _cargarInventario();
  }

  Future<void> _cargarInventario() async {
    setState(() => _isLoading = true);

    List<String> categoriasMaestras = [
      'Vino Tinto',
      'Vino Blanco',
      'Pisco Italia',
      'Pisco Acholado',
      'Pisco Mosto Verde',
      'Pisco Quebranta',
    ];

    Map<String, int> conteoFirestore = await _inventarioService
        .contarProductosPorCategoria();

    Map<String, int> resultadoFinal = {};
    for (String cat in categoriasMaestras) {
      resultadoFinal[cat] = conteoFirestore[cat] ?? 0;
    }

    setState(() {
      _productosPorCategoria = resultadoFinal;
      _isLoading = false;
    });
  }

  void _mostrarMenu(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Iconsax.document,
                  color: isDarkMode
                      ? const Color.from(alpha: 1, red: 1, green: 1, blue: 1)
                      : Colors.black,
                ),
                title: Text(
                  'Publicaciones',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  navegarConSlideArriba(context, PublicacionesPage());
                },
              ),
              ListTile(
                leading: Icon(
                  Iconsax.box,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                title: Text(
                  'Productos',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  navegarConSlideArriba(context, const ProductoPage());
                },
              ),
              ListTile(
                leading: Icon(
                  Iconsax.video,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                title: Text(
                  'Reels',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  navegarConSlideArriba(context, const VideoEditorPage());
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Inventario',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _mostrarMenu(context),
                      icon: Icon(Iconsax.more, color: textColor, size: 28),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: StreamBuilder<Map<String, int>>(
                stream: _inventarioService.streamConteoProductos(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final productosPorCategoria = snapshot.data!;
                  final isDarkMode =
                      Theme.of(context).brightness == Brightness.dark;

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 5,
                              childAspectRatio: 1.2,
                            ),
                        itemCount: productosPorCategoria.keys.length,
                        itemBuilder: (context, index) {
                          String categoria = productosPorCategoria.keys
                              .elementAt(index);
                          int cantidad = productosPorCategoria[categoria] ?? 0;
                          Color color =
                              _categoriaColor[categoria] ??
                              (isDarkMode ? Colors.white : Colors.grey[400]!);
                          Color textoColor = (color.computeLuminance() > 0.5)
                              ? Colors.black
                              : Colors.white;

                          return Card(
                            color: color.withOpacity(0.85),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            shadowColor: Colors.black54,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    categoria,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textoColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: textoColor.withOpacity(
                                      0.3,
                                    ),
                                    child: Text(
                                      cantidad.toString(),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: textoColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Column(
              children: [
                FullWidthActionButton(
                  icon: Icons.update,
                  iconColor: const Color(0xFFA30000),
                  title: 'Actualizar Producto',
                  subtitle: 'Modifica la información del producto seleccionado',
                  onPressed: () {
                    navegarConSlideDerecha(
                      context,
                      const ActualizarProductoPage(),
                    );
                  },
                ),
                FullWidthActionButton(
                  icon: Icons.delete,
                  iconColor: Colors.black,
                  title: 'Eliminar Producto',
                  subtitle: 'Elimina este producto de forma permanente',
                  onPressed: () {
                    navegarConSlideDerecha(
                      context,
                      const EliminarPageProducto(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
