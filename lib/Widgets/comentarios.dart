import 'package:app_bootsup/Modulo/publicacionesService.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

class ComentariosScreen extends StatefulWidget {
  final String publicacionId;
  final String userId;

  const ComentariosScreen({
    required this.publicacionId,
    required this.userId,
    super.key,
  });

  @override
  State<ComentariosScreen> createState() => _ComentariosScreenState();
}

class _ComentariosScreenState extends State<ComentariosScreen> {
  final TextEditingController _comentarioCtrl = TextEditingController();

  Future<void> _comentar() async {
    if (_comentarioCtrl.text.trim().isEmpty) return;

    await FirestoreService().comentar(
      widget.publicacionId,
      widget.userId,
      _comentarioCtrl.text.trim(),
    );

    _comentarioCtrl.clear();
  }

  Future<void> _eliminarComentario(String comentarioId) async {
    await FirestoreService().eliminarComentario(
      widget.publicacionId,
      comentarioId,
      widget.userId,
    );
  }

  void _mostrarModalEliminar(BuildContext context, String comentarioId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        height: 215,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.trash, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Eliminar comentario',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '¿Estás seguro de que deseas eliminar este comentario? Esta acción no se puede deshacer.',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  label: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Iconsax.trash,
                    size: 18,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                  label: Text(
                    'Eliminar',
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                  onPressed: () async {
                    _eliminarComentario(comentarioId);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comentariosRef = FirebaseFirestore.instance
        .collection('publicaciones')
        .doc(widget.publicacionId)
        .collection('comentarios')
        .orderBy('fecha', descending: true);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.white,
          appBar: AppBar(
            title: const Text("Comentarios"),
            centerTitle: true,
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream: comentariosRef.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: LoadingAnimationWidget.staggeredDotsWave(
                          color: const Color(0xFFA30000),
                          size: 40,
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "Sé el primero en comentar",
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      reverse: true, // Para que los nuevos aparezcan abajo
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final usuarioId = data['usuarioId'];

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(usuarioId)
                              .get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return const SizedBox();
                            }

                            final userData =
                                userSnapshot.data!.data()
                                    as Map<String, dynamic>?;
                            if (userData == null) return const SizedBox();

                            final username =
                                userData['username'] ?? 'Sin nombre';
                            final profileImageUrl = userData['profileImageUrl'];
                            final fecha = (data['fecha'] as Timestamp).toDate();

                            return GestureDetector(
                              onLongPress: () {
                                if (usuarioId == widget.userId) {
                                  _mostrarModalEliminar(
                                    context,
                                    docs[index].id,
                                  );
                                }
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 21,
                                    backgroundImage: profileImageUrl != null
                                        ? NetworkImage(profileImageUrl)
                                        : null,
                                    backgroundColor: Colors.grey[300],
                                    child: profileImageUrl == null
                                        ? const Icon(Icons.person, size: 22)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey[850]
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                username,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              Text(
                                                timeago.format(
                                                  fecha,
                                                  locale: 'es',
                                                ),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 8,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            data['texto'],
                                            style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.favorite_border,
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  // Acción de Me gusta
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              _buildCommentInput(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _comentarioCtrl,
                maxLength: 200,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Escribe un comentario...",
                  border: InputBorder.none,
                  counterText: "",
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFA30000),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Iconsax.send_2),
              color: Colors.white,
              onPressed: _comentar,
            ),
          ),
        ],
      ),
    );
  }
}

//PARA COMENTARIOS DE VIDEOS
class ComentariosScreenVideos extends StatefulWidget {
  final String videoid;
  final String userId;

  const ComentariosScreenVideos({
    required this.videoid,
    required this.userId,
    super.key,
  });

  @override
  State<ComentariosScreenVideos> createState() =>
      _ComentariosScreenVideosState();
}

class _ComentariosScreenVideosState extends State<ComentariosScreenVideos> {
  final TextEditingController _comentarioCtrl = TextEditingController();
  bool _isSending = false;

  Future<void> _comentar() async {
    if (_comentarioCtrl.text.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);

    await FirestoreService().comentar(
      widget.videoid,
      widget.userId,
      _comentarioCtrl.text.trim(),
    );

    _comentarioCtrl.clear();
    setState(() => _isSending = false);
  }

  Future<void> _eliminarComentario(String comentarioId) async {
    await FirestoreService().eliminarComentario(
      widget.videoid,
      comentarioId,
      widget.userId,
    );
  }

  void _mostrarModalEliminar(BuildContext context, String comentarioId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.remove, color: Colors.grey[500]),
              const SizedBox(height: 15),
              Text(
                "¿Eliminar comentario?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Esta acción no se puede deshacer.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Cancelar"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _eliminarComentario(comentarioId);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Eliminar"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final comentariosRef = FirebaseFirestore.instance
        .collection('videos')
        .doc(widget.videoid)
        .collection('comentarios')
        .orderBy('fecha', descending: true);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: const Text(
          "Comentarios",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: comentariosRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Sé el primero en comentar",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final usuarioId = data['usuarioId'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(usuarioId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) return const SizedBox();

                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>?;
                        if (userData == null) return const SizedBox();

                        final username = userData['username'] ?? 'Usuario';
                        final profileImageUrl = userData['profileImageUrl'];
                        final fecha = (data['fecha'] as Timestamp).toDate();

                        return GestureDetector(
                          onLongPress: () {
                            if (usuarioId == widget.userId) {
                              _mostrarModalEliminar(context, docs[index].id);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: profileImageUrl != null
                                      ? NetworkImage(profileImageUrl)
                                      : null,
                                  backgroundColor: Colors.grey[300],
                                  child: profileImageUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 20,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.grey[850]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              username,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                            Text(
                                              timeago.format(
                                                fecha,
                                                locale: 'es',
                                              ),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          data['texto'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          _buildCommentInput(context, isDark),
        ],
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context, bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _comentarioCtrl,
                  maxLines: null,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: "Escribe un comentario...",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFFA30000),
              radius: 24,
              child: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _comentar,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
