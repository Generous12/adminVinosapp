import 'dart:io';
import 'package:app_bootsup/Vistadmin/vistaAdmin/inventario/Video/trimmer.dart';
import 'package:app_bootsup/Widgets/alertas.dart';
import 'package:app_bootsup/Widgets/cajasdetexto.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:video_player/video_player.dart';

class VideoEditorPage extends StatefulWidget {
  const VideoEditorPage({Key? key}) : super(key: key);

  @override
  State<VideoEditorPage> createState() => _VideoEditorPageState();
}

class _VideoEditorPageState extends State<VideoEditorPage> {
  File? _videoFile;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isLoading1 = false;

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo({required bool fromCamera}) async {
    setState(() {
      _isLoading = true; // mostrar loading
    });

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickVideo(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );
      if (pickedFile == null) return;

      final file = File(pickedFile.path);

      // Inicializar temporalmente para medir la duración
      final tempController = VideoPlayerController.file(file);
      await tempController.initialize();
      final duration = tempController.value.duration;
      await tempController.dispose(); // Liberamos el controlador temporal

      if (duration.inSeconds > 30) {
        showCustomDialog(
          context: context,
          title: "Oops",
          message: "El video debe ser menor o igual a 30 segundos",
          confirmButtonText: "Cerrar",
        );
        return; // No seleccionamos el video
      }

      // Si pasa la validación, inicializamos los controladores reales
      _videoPlayerController?.dispose();
      _chewieController?.dispose();

      _videoPlayerController = VideoPlayerController.file(file);
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
      );

      setState(() {
        _videoFile = file;
      });
    } finally {
      setState(() {
        _isLoading = false; // ocultar loading
      });
    }
  }

  Future<void> _uploadVideo({String? descripcion}) async {
    if (_videoFile == null) return;

    setState(() {
      _isLoading1 = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Usuario no autenticado")));
        return;
      }

      final userId = user.uid;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'Administrador/$userId/videos/$timestamp.mp4';

      // Subir video a Firebase Storage
      final ref = _storage.ref().child(storagePath);
      await ref.putFile(_videoFile!);

      // Obtener URL de descarga
      final urlVideo = await ref.getDownloadURL();

      // Guardar datos en Firestore con descripción
      await _firestore.collection('videos').add({
        'fechaSubida': Timestamp.now(),
        'usuarioQueSubio': userId,
        'urlVideo': urlVideo,
        'descripcion': descripcion ?? '', // aquí guardamos la descripción
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Video subido con éxito")));

      setState(() {
        _videoFile = null;
      });
    } catch (e) {
      debugPrint("❌ Error al subir el video: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al subir el video: $e")));
    } finally {
      setState(() {
        _isLoading1 = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: _videoFile == null
                ? Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Builder(
                            builder: (context) {
                              final isDark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;
                              final naranja = const Color(0xFFA30000);
                              final grisClaro = const Color(0xFFFAFAFA);
                              final textColor = isDark
                                  ? grisClaro
                                  : Colors.black;

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(28),
                                    decoration: BoxDecoration(
                                      color: naranja.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Iconsax.video,
                                      size: 80,
                                      color: naranja,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Título
                                  Text(
                                    "Crea tu contenido",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Subtítulo
                                  Text(
                                    "Graba un nuevo video o selecciona uno de tu galería.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: textColor.withOpacity(0.7),
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Botón grabar video
                                  ElevatedButton.icon(
                                    icon: const Icon(
                                      Iconsax.video,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Grabar video',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    onPressed: () =>
                                        _pickVideo(fromCamera: true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: naranja,
                                      minimumSize: const Size(
                                        double.infinity,
                                        55,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 4,
                                      shadowColor: naranja.withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Botón seleccionar video
                                  ElevatedButton.icon(
                                    icon: Icon(
                                      Iconsax.gallery,
                                      size: 22,
                                      color: naranja,
                                    ),
                                    label: Text(
                                      'Seleccionar video',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: naranja,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    onPressed: () =>
                                        _pickVideo(fromCamera: false),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: naranja.withOpacity(
                                        0.08,
                                      ),
                                      minimumSize: const Size(
                                        double.infinity,
                                        55,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        left: 16,
                        child: Builder(
                          builder: (context) {
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;
                            final textColor = isDark
                                ? const Color(0xFFFAFAFA)
                                : Colors.black;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Iconsax.arrow_left,
                                    size: 24,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: Colors.black,
                          child: _chewieController != null
                              ? Chewie(controller: _chewieController!)
                              : const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      Positioned(
                        top: 10,
                        left: 15,
                        right: 15,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _videoFile = null;
                                      _videoPlayerController?.dispose();
                                      _chewieController?.dispose();
                                      _videoPlayerController = null;
                                      _chewieController = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Iconsax.arrow_left_2,
                                      color: Color.fromARGB(255, 255, 255, 255),
                                    ),
                                  ),
                                ),
                              ),

                              // Segundo bloque (Recortar)
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final File? trimmedVideo =
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => VideoTrimmerPage(
                                              videoFile: _videoFile!,
                                            ),
                                          ),
                                        );

                                    if (trimmedVideo != null) {
                                      _videoPlayerController?.dispose();
                                      _chewieController?.dispose();

                                      _videoPlayerController =
                                          VideoPlayerController.file(
                                            trimmedVideo,
                                          );
                                      await _videoPlayerController!
                                          .initialize();

                                      _chewieController = ChewieController(
                                        videoPlayerController:
                                            _videoPlayerController!,
                                        autoPlay: false,
                                        looping: false,
                                        showOptions: false,
                                      );

                                      setState(() {
                                        _videoFile = trimmedVideo;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Iconsax.scissor,
                                      color: Color.fromARGB(255, 255, 255, 255),
                                    ),
                                  ),
                                ),
                              ),

                              // Tercer bloque (Subir)
                              Expanded(
                                child: InkWell(
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  onTap: () {
                                    final TextEditingController
                                    descripcionController =
                                        TextEditingController();

                                    showMaterialModalBottomSheet(
                                      context: context,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).scaffoldBackgroundColor,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (context) {
                                        return SafeArea(
                                          child: SingleChildScrollView(
                                            child: AnimatedPadding(
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              curve: Curves.easeOut,
                                              padding: EdgeInsets.only(
                                                left: 16,
                                                right: 16,
                                                top: 0,
                                                bottom:
                                                    MediaQuery.of(
                                                      context,
                                                    ).viewInsets.bottom +
                                                    16,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 50,
                                                    height: 5,
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(
                                                        context,
                                                      ).dividerColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),

                                                  // Título
                                                  Text(
                                                    "Agregar descripción",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.color,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),

                                                  // Instrucción
                                                  Text(
                                                    "Escribe una breve descripción o notas sobre tu video. Esto ayudará a que otros usuarios comprendan tu contenido.",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.color
                                                          ?.withOpacity(0.7),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 16),

                                                  // Campo de texto
                                                  CustomTextField(
                                                    controller:
                                                        descripcionController,
                                                    label:
                                                        "Descripción / Notas de cata",
                                                    prefixIcon: Iconsax.note,
                                                    minLines: 1,
                                                    maxLines: 2,
                                                  ),
                                                  const SizedBox(height: 18),

                                                  // Botón de publicar
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        final descripcion =
                                                            descripcionController
                                                                .text;
                                                        _uploadVideo(
                                                          descripcion:
                                                              descripcion,
                                                        );
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 12,
                                                            ),
                                                        backgroundColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        elevation: 4,
                                                        shadowColor:
                                                            Colors.black26,
                                                      ),
                                                      child: Text(
                                                        "Publicar",
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color.fromARGB(
                                                            255,
                                                            255,
                                                            255,
                                                            255,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Iconsax.cloud_plus,
                                      color: Color.fromARGB(255, 255, 255, 255),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Overlay de carga
                      if (_isLoading1)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black54,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFA30000),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
