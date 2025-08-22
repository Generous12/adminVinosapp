import 'dart:io';
import 'package:app_bootsup/Widgets/boton.dart';
import 'package:app_bootsup/Widgets/cajasdetexto.dart';
import 'package:app_bootsup/Widgets/dropdownbutton2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;

class EditarProductoPage extends StatefulWidget {
  final Map<String, dynamic> producto;

  const EditarProductoPage({Key? key, required this.producto})
    : super(key: key);

  @override
  State<EditarProductoPage> createState() => _EditarProductoPageState();
}

class _EditarProductoPageState extends State<EditarProductoPage> {
  late TextEditingController nombreController;
  late TextEditingController marcaController;
  late TextEditingController stockController;
  late TextEditingController precioController;
  late TextEditingController descuentoController;
  late TextEditingController descripcionController;

  String? selectedCategoria;
  String? selectedVolumen;

  final List<String> categorias = [
    'General',
    'Vino Tinto',
    'Vino Blanco',
    'Pisco Quebranta',
    'Pisco Acholado',
    'Pisco Italia',
    'Pisco Mosto Verde',
  ];

  final List<String> volumenes = ['250ml', '375ml', '500ml', '750ml', '1L'];
  String normalize(String s) => s.replaceAll(' ', '').toLowerCase();
  dynamic _mainImage;
  List<dynamic> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    final p = widget.producto;

    nombreController = TextEditingController(text: p['nombreProducto'] ?? '');
    marcaController = TextEditingController(text: p['marca'] ?? '');
    stockController = TextEditingController(text: p['stock']?.toString() ?? '');
    precioController = TextEditingController(
      text: p['precio']?.toString() ?? '',
    );
    descuentoController = TextEditingController(
      text: p['descuento']?.toString() ?? '',
    );
    descripcionController = TextEditingController(text: p['descripcion'] ?? '');
    final List<String>? existingUrls = widget.producto['imagenes']
        ?.cast<String>();
    if (existingUrls != null && existingUrls.isNotEmpty) {
      _selectedImages.addAll(existingUrls);
      _mainImage ??= existingUrls.first;
    }
    final categoriasUnicas = categorias.toSet().toList();
    final volumenesUnicos = volumenes.toSet().toList();
    selectedCategoria = categoriasUnicas.contains(p['categoria'])
        ? p['categoria']
        : categoriasUnicas.first;
    selectedVolumen =
        volumenesUnicos.any(
          (v) => normalize(v) == normalize(widget.producto['volumen'] ?? ''),
        )
        ? widget.producto['volumen']
        : volumenesUnicos.first;
  }

  @override
  Widget build(BuildContext context) {
    final categoriasUnicas = categorias.toSet().toList();
    final volumenesUnicos = volumenes.toSet().toList();
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 30),
            CustomTextField(
              controller: nombreController,
              label: "Nombre del producto",
              prefixIcon: Iconsax.box,
            ),
            const SizedBox(height: 12),
            CustomDropdown(
              items: categoriasUnicas,
              value: selectedCategoria,
              onChanged: (v) => setState(() => selectedCategoria = v),
              icon: Iconsax.category,
              label: "Categoría / Tipo",
              iconColor: const Color(0xFFA30000),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: marcaController,
              label: "Marca / Bodega",
              prefixIcon: Iconsax.shop,
            ),
            const SizedBox(height: 12),
            CustomDropdown(
              items: volumenesUnicos,
              value: volumenesUnicos.firstWhere(
                (v) => normalize(v) == normalize(selectedVolumen ?? ''),
                orElse: () => volumenesUnicos.first,
              ),
              onChanged: (v) => setState(() => selectedVolumen = v),
              icon: Iconsax.archive,
              label: "Volumen",
              iconColor: const Color(0xFFA30000),
            ),
            SizedBox(height: 12),
            CustomTextField(
              controller: stockController,
              label: "Stock disponible",
              prefixIcon: Iconsax.box_1,
              isNumeric: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: precioController,
                    label: "Precio de venta (S/.)",
                    prefixIcon: Iconsax.dollar_circle,
                    isNumeric: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: descuentoController,
                    label: "Descuento (%)",
                    prefixIcon: Iconsax.percentage_square,
                    isNumeric: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: descripcionController,
              label: "Descripción / Notas de cata",
              prefixIcon: Iconsax.note,
              minLines: 1,
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(1),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Iconsax.image, size: 20, color: Colors.black87),
                      SizedBox(width: 6),
                      Text(
                        'Imágenes seleccionadas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedImages.length + 1,
                    itemBuilder: (context, index) {
                      if (index < _selectedImages.length) {
                        final image = _selectedImages[index];
                        final isSelected = image == _mainImage;
                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _mainImage = image;
                                });
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: image is File
                                    ? Image.file(image, fit: BoxFit.cover)
                                    : Image.network(image, fit: BoxFit.cover),
                              ),
                            ),
                            if (isSelected)
                              const Positioned(
                                top: 6,
                                right: 6,
                                child: Icon(
                                  Iconsax.tick_circle,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                    if (_selectedImages.isEmpty)
                                      _mainImage = null;
                                    else if (_mainImage == image)
                                      _mainImage = _selectedImages.first;
                                  });
                                },
                                child: const Icon(
                                  Iconsax.trash,
                                  color: ui.Color(0xFFBD0000),
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return GestureDetector(
                          onTap: _selectImageSource,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const ui.Color(0xFF000000),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Iconsax.add_circle,
                                color: Colors.black87,
                                size: 30,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: LoadingOverlayButton(
                    text: 'Cancelar',
                    color: Colors.grey,
                    onPressedLogic: () async {
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: LoadingOverlayButton(
                    text: 'Guardar',
                    color: const Color(0xFFA30000),
                    onPressedLogic: () async {
                      await _guardarProducto(
                        'userId',
                      ); // reemplazar por tu lógica de usuario
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImageSource() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        final file = File(picked.path);
        _selectedImages.add(file);
        if (_mainImage == null) _mainImage = file;
      });
    }
  }

  Future<void> _guardarProducto(String userId) async {
    List<String> uploadedUrls = [];

    for (var image in _selectedImages) {
      if (image is File) {
        // Subir solo imágenes nuevas
        String storagePath =
            'Administrador/$userId/${DateTime.now().millisecondsSinceEpoch}.webp';
        var uploadTask = await FirebaseStorage.instance
            .ref(storagePath)
            .putFile(image);
        final url = await uploadTask.ref.getDownloadURL();
        uploadedUrls.add(url);
      } else if (image is String) {
        // Mantener URLs existentes
        uploadedUrls.add(image);
      }
    }

    // Guardar producto en Firestore
    await FirebaseFirestore.instance
        .collection('productos')
        .doc(widget.producto['id'])
        .update({
          'nombreProducto': nombreController.text,
          'marca': marcaController.text,
          'categoria': selectedCategoria,
          'volumen': selectedVolumen,
          'stock': int.tryParse(stockController.text) ?? 0,
          'precio': double.tryParse(precioController.text) ?? 0,
          'descuento': double.tryParse(descuentoController.text) ?? 0,
          'descripcion': descripcionController.text,
          'imagenes': uploadedUrls,
        });
  }
}
