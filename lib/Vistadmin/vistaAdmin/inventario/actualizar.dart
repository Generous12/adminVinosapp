import 'package:app_bootsup/Modulo/inventarioService.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/inventario/actulizandoProducto.dart';
import 'package:app_bootsup/Widgets/cajasdetexto.dart';
import 'package:app_bootsup/Widgets/navegator.dart';
import 'package:app_bootsup/Widgets/selector.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class ActualizarProductoPage extends StatefulWidget {
  const ActualizarProductoPage({Key? key}) : super(key: key);

  @override
  State<ActualizarProductoPage> createState() => _ActualizarProductoPageState();
}

class _ActualizarProductoPageState extends State<ActualizarProductoPage> {
  final InventarioService _inventarioService = InventarioService();
  List<Map<String, dynamic>> _productos = [];
  bool _isLoading = false;
  String selectedCategoria = 'General';
  bool _isSearching = false;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos({String? categoria}) async {
    setState(() => _isLoading = true);

    if (categoria == null || categoria == 'General') {
      _productos = await _inventarioService.listarProductos();
    } else {
      _productos = await _inventarioService.listarProductosPorCategoria(
        categoria,
      );
    }

    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get filteredProductos {
    if (searchQuery.isEmpty) return _productos;
    return _productos
        .where(
          (p) => p['nombreProducto'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                alignment: Alignment.bottomLeft,

                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Iconsax.arrow_left),
                      onPressed: () => Navigator.pop(context),
                    ),

                    const SizedBox(width: 8),
                    Expanded(
                      child: _isSearching
                          ? TextField(
                              controller: searchController,
                              autofocus: true,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 17,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Buscar producto...',
                                hintStyle: TextStyle(
                                  color: Color.fromARGB(179, 118, 118, 118),
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                setState(() => searchQuery = value);
                              },
                            )
                          : Text(
                              'Actualizar Producto',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isSearching ? Icons.close : Iconsax.search_normal,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_isSearching) {
                            searchQuery = '';
                            searchController.clear();
                          }
                          _isSearching = !_isSearching;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            CategoriaSelector(
              onCategoriaSelected: (categoria) {
                selectedCategoria = categoria;
                _cargarProductos(categoria: categoria);
              },
            ),

            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredProductos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final producto = filteredProductos[index];
                        final List<dynamic> imagenes =
                            producto['imagenes'] ?? [];
                        final String? primeraImagen = imagenes.isNotEmpty
                            ? imagenes[0]
                            : null;
                        Timestamp? timestamp = producto['fecha'];
                        String fecha = '';
                        if (timestamp != null) {
                          final date = timestamp.toDate();
                          fecha = DateFormat('dd/MM/yyyy').format(date);
                        }

                        return InkWell(
                          onTap: () {
                            navegarConSlideDerecha(
                              context,
                              EditarProductoPage(producto: producto),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[850] : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: primeraImagen == null
                                        ? const Color(0xFFA30000)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: primeraImagen != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            primeraImagen,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  color: const Color(
                                                    0xFFA30000,
                                                  ),
                                                  child: const Icon(
                                                    Iconsax.box,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                          ),
                                        )
                                      : const Icon(
                                          Iconsax.box,
                                          color: Colors.white,
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formatText(
                                          producto['nombreProducto'] ??
                                              'Sin nombre',
                                          maxLength: 23,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            producto['categoria'] ??
                                                'Sin categoría',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                            ),
                                          ),
                                          if (fecha.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              fecha,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
