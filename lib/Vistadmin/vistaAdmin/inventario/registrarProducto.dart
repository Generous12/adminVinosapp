import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:app_bootsup/Widgets/alertas.dart';
import 'package:app_bootsup/Widgets/cajasdetexto.dart';
import 'package:app_bootsup/Widgets/dropdownbutton2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProductoPage extends StatefulWidget {
  const ProductoPage({Key? key}) : super(key: key);

  @override
  State<ProductoPage> createState() => _ProductoPageState();
}

class _ProductoPageState extends State<ProductoPage> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController marcaController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController descuentoController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  File? _mainImage;
  List<File> _selectedImages = [];
  User? _user = FirebaseAuth.instance.currentUser;

  final List<String> categorias = [
    'Vino Tinto',
    'Vino Blanco',
    'Pisco Quebranta',
    'Pisco Acholado',
    'Pisco Italia',
    'Pisco Mosto Verde',
  ];

  final List<String> volumenes = ['375 ml', '500 ml', '750 ml', '1 L', '1.5 L'];
  String? selectedCategoria;
  String? selectedVolumen;
  String? selectedGrado;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File newImage = File(pickedFile.path);
      setState(() {
        _selectedImages.insert(0, newImage);
        _mainImage = newImage;
      });
    }
  }

  Future<void> _selectImageSource() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Iconsax.camera, color: Color(0xFFA30000)),
                title: const Text("Cámara"),
                onTap: () => Navigator.pop(ctx, true),
              ),
              ListTile(
                leading: const Icon(Iconsax.gallery, color: Color(0xFFA30000)),
                title: const Text("Galería"),
                onTap: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      await _pickImage(result ? ImageSource.camera : ImageSource.gallery);
    }
  }

  void _showFullScreenImage(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(
                    color: const ui.Color.fromARGB(
                      255,
                      0,
                      0,
                      0,
                    ).withOpacity(0.7),
                  ),
                ),
              ),
              Center(child: Image.file(imageFile)),
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      LucideIcons.minimize,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: const ui.Color.fromARGB(255, 0, 0, 0),
                      radius: 30,
                      child: IconButton(
                        icon: Icon(
                          Iconsax.crop,
                          color: const ui.Color(0xFFFFAF00),
                        ),
                        onPressed: () async {
                          try {
                            final croppedFile = await ImageCropper().cropImage(
                              sourcePath: imageFile.path,
                              compressFormat: ImageCompressFormat.jpg,
                              compressQuality: 100,
                              aspectRatio: const CropAspectRatio(
                                ratioX: 1,
                                ratioY: 1,
                              ),
                              uiSettings: [
                                AndroidUiSettings(
                                  toolbarTitle: 'Cropper',
                                  toolbarColor: const Color(0xFFFFAF00),
                                  toolbarWidgetColor: Colors.white,
                                  lockAspectRatio: true,
                                  hideBottomControls: true,
                                ),
                              ],
                            );

                            if (croppedFile != null) {
                              final File newImageFile = File(croppedFile.path);

                              setState(() {
                                int index = _selectedImages.indexOf(imageFile);
                                if (index != -1) {
                                  _selectedImages[index] = newImageFile;
                                }

                                if (_mainImage?.path == imageFile.path) {
                                  _mainImage = File(newImageFile.path);
                                }
                              });

                              Navigator.pop(context);
                            }
                          } catch (e) {
                            print("Error al recortar imagen: $e");
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Uint8List> convertImageToWebP(File file, {int quality = 90}) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      format: CompressFormat.webp,
      quality: quality,
      minWidth: 1080,
      minHeight: 1080,
    );
    if (result == null) throw Exception('No se pudo convertir a WebP');
    return result;
  }

  Future<void> _guardarProducto(String _userId) async {
    List<String> errores = [];
    if (nombreController.text.isEmpty ||
        precioController.text.isEmpty ||
        stockController.text.isEmpty) {
      errores.add("Completa todos los campos obligatorios.");
    }

    if (selectedCategoria == null || selectedCategoria!.isEmpty) {
      errores.add("Selecciona la categoría / tipo.");
    }

    if (selectedVolumen == null || selectedVolumen!.isEmpty) {
      errores.add("Selecciona el volumen.");
    }

    if (_selectedImages.isEmpty) {
      errores.add("Selecciona al menos una imagen.");
    }

    // Mostrar errores si existen
    if (errores.isNotEmpty) {
      await showCustomDialog(
        context: context,
        title: "Formulario incompleto",
        message: errores.join("\n"),
        confirmButtonText: "Cerrar",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> downloadUrls = [];
      for (File imageFile in _selectedImages) {
        final Uint8List webpBytes = await convertImageToWebP(
          imageFile,
          quality: 90,
        );

        String storagePath =
            'Administrador/$_userId/${DateTime.now().millisecondsSinceEpoch}.webp';

        Reference storageReference = FirebaseStorage.instance.ref().child(
          storagePath,
        );

        TaskSnapshot snapshot = await storageReference.putData(
          webpBytes,
          SettableMetadata(contentType: 'image/webp'),
        );

        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }
      DocumentReference productoRef = FirebaseFirestore.instance
          .collection('VinosPiscosProductos')
          .doc();

      Map<String, dynamic> dataToSave = {
        "nombreProducto": nombreController.text.trim(),
        "categoria": selectedCategoria,
        "volumen": selectedVolumen,
        "stock": int.tryParse(stockController.text.trim()) ?? 0,
        "precio":
            double.tryParse(
              precioController.text.trim().replaceAll(",", "."),
            ) ??
            0.0,
        "descripcion": descripcionController.text.trim(),
        "imagenes": downloadUrls,
        "imagenPrincipal":
            (_mainImage != null && _selectedImages.contains(_mainImage))
            ? downloadUrls[_selectedImages.indexOf(_mainImage!)]
            : downloadUrls.first,
        "fecha": FieldValue.serverTimestamp(),
        "usuarioqueRegistro": _userId,
        "marca": marcaController.text.trim(),
        "descuento": descuentoController.text.trim().isNotEmpty
            ? int.tryParse(descuentoController.text.trim()) ?? 0
            : 0,
      };

      await productoRef.set(dataToSave);

      await showCustomDialog(
        context: context,
        title: "Éxito",
        message: "Producto guardado correctamente",
        confirmButtonText: "Cerrar",
      );

      Navigator.pop(context);
    } catch (e, stacktrace) {
      debugPrint("🔥 Error al guardar producto: $e");
      debugPrint("📌 Stacktrace: $stacktrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al guardar el producto: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Theme.of(context).scaffoldBackgroundColor,
          statusBarIconBrightness:
              Theme.of(context).brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        if (_isLoading) {
          return false;
        }
        final haynombre = nombreController.text.trim().isNotEmpty;
        final hayMarca = marcaController.text.trim().isNotEmpty;
        final hayStock = stockController.text.trim().isNotEmpty;
        final hayPrecio = precioController.text.trim().isNotEmpty;
        final hayDescuento = descuentoController.text.trim().isNotEmpty;
        final hayDescripcion = descripcionController.text.trim().isNotEmpty;

        final hayImagenPrincipal = _mainImage != null;
        final hayImagenesSeleccionadas = _selectedImages.isNotEmpty;

        if (hayDescripcion ||
            hayMarca ||
            hayStock ||
            hayPrecio ||
            hayDescuento ||
            haynombre ||
            hayImagenPrincipal ||
            hayImagenesSeleccionadas) {
          bool? result = await showCustomDialog(
            context: context,
            title: 'Aviso',
            message: '¿Estás seguro? Si sales ahora, perderás tu progreso.',
            confirmButtonText: 'Sí, salir',
            cancelButtonText: 'No',
            confirmButtonColor: Colors.red,
            cancelButtonColor: const Color.fromARGB(255, 0, 0, 0),
          );

          if (result == true) {
            if (mounted) {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            }
          }

          return false;
        }

        return true;
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: AppBar(
              automaticallyImplyLeading: false,
              elevation: 5,
              titleSpacing: 0,
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              title: Text(
                "Registros",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 5, 5, 5),
                  child: Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final haynombre = nombreController.text
                              .trim()
                              .isNotEmpty;
                          final hayMarca = marcaController.text
                              .trim()
                              .isNotEmpty;
                          final hayStock = stockController.text
                              .trim()
                              .isNotEmpty;
                          final hayPrecio = precioController.text
                              .trim()
                              .isNotEmpty;
                          final hayDescuento = descuentoController.text
                              .trim()
                              .isNotEmpty;
                          final hayDescripcion = descripcionController.text
                              .trim()
                              .isNotEmpty;

                          final hayImagenPrincipal = _mainImage != null;
                          final hayImagenesSeleccionadas =
                              _selectedImages.isNotEmpty;

                          if (hayDescripcion ||
                              hayMarca ||
                              hayStock ||
                              hayPrecio ||
                              hayDescuento ||
                              haynombre ||
                              hayImagenPrincipal ||
                              hayImagenesSeleccionadas) {
                            bool? result = await showCustomDialog(
                              context: context,
                              title: 'Aviso',
                              message:
                                  '¿Estás seguro? Si sales ahora, perderás tu progreso.',
                              confirmButtonText: 'Sí, salir',
                              cancelButtonText: 'No',
                              confirmButtonColor: Colors.red,
                              cancelButtonColor: const Color.fromARGB(
                                255,
                                0,
                                0,
                                0,
                              ),
                            );

                            if (result == true) {
                              if (mounted) {
                                FocusScope.of(context).unfocus();
                                Navigator.pop(context);
                              }
                            }
                            return;
                          }

                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          "Cancelar",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 5),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFA30000),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (_user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("No hay usuario logueado."),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          print("Usuario logueado: ${_user?.uid}");
                          await _guardarProducto(_user!.uid);
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          "Guardar",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 5),
                  CustomTextField(
                    controller: nombreController,
                    label: "Nombre del producto",
                    prefixIcon: Iconsax.box,
                  ),
                  const SizedBox(height: 12),
                  CustomDropdown(
                    items: categorias,
                    value: selectedCategoria,
                    onChanged: (value) =>
                        setState(() => selectedCategoria = value),
                    icon: Iconsax.category,
                    label: "Categoría / Tipo",
                    iconColor: const ui.Color(0xFFA30000),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: marcaController,
                    label: "Marca / Bodega",
                    prefixIcon: Iconsax.shop,
                  ),
                  const SizedBox(height: 12),
                  CustomDropdown(
                    items: volumenes,
                    value: selectedVolumen,
                    onChanged: (value) =>
                        setState(() => selectedVolumen = value),
                    icon: Iconsax.archive,
                    label: "Volumen",
                    iconColor: const ui.Color(0xFFA30000),
                  ),
                  const SizedBox(height: 12),
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
                            Icon(
                              Iconsax.image,
                              size: 20,
                              color: Colors.black87,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Imágenes seleccionadas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
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
                                      _showFullScreenImage(image);
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        image,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Icon(
                                        Iconsax.tick_circle,
                                        color: ui.Color.fromARGB(
                                          255,
                                          255,
                                          255,
                                          255,
                                        ),
                                        size: 20,
                                      ),
                                    ),
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          setState(() {
                                            _selectedImages.removeAt(index);

                                            if (_selectedImages.isEmpty) {
                                              _mainImage = null;
                                            } else if (_mainImage == image) {
                                              _mainImage =
                                                  _selectedImages.first;
                                            }
                                          });
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
                                      color: const ui.Color.fromARGB(
                                        255,
                                        0,
                                        0,
                                        0,
                                      ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
