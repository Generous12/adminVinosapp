// ignore_for_file: unused_local_variable

import 'package:app_bootsup/Clases/ChatResumen.dart';
import 'package:app_bootsup/Modulo/chatsService.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/Chats/chatconCLiente.dart';
import 'package:app_bootsup/Widgets/navegator.dart';
import 'package:app_bootsup/Widgets/selector.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ChatClientesScreen extends StatefulWidget {
  const ChatClientesScreen({Key? key}) : super(key: key);

  @override
  State<ChatClientesScreen> createState() => _ChatClientesScreenState();
}

class _ChatClientesScreenState extends State<ChatClientesScreen> {
  final Color fondo = const Color(0xFFFAFAFA);
  final String empresaId = 'empresa_unica';
  String filtroActivo = 'Todos';

  final TextEditingController _searchController = TextEditingController();
  List<ChatResumen> _allChats = [];
  Set<String> _chatsSeleccionados = {};
  bool get _estaSeleccionando => _chatsSeleccionados.isNotEmpty;
  late Stream<List<ChatResumen>> _streamChats;

  @override
  void initState() {
    super.initState();
    _streamChats = ChatServiceEmpresaVinos.obtenerTodosLosChats();
  }

  bool _todosSeleccionadosEstanFijados() {
    return _chatsSeleccionados.every((chatId) {
      final chat = _allChats.firstWhere(
        (c) => c.chatId == chatId,
        orElse: () => ChatResumen(
          chatId: '',
          clienteId: '',
          nombre: '',
          fotoUrl: '',
          lastMessage: '',
          unreadCount: 0,
          fijado: false,
        ),
      );
      return chat.fijado;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
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
                    if (!_estaSeleccionando) ...[
                      Text(
                        'Chats',
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
                          onChanged: (_) => setState(() {}),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 16,

                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar chat...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 16,
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
                    ] else ...[
                      Expanded(
                        child: Text(
                          '${_chatsSeleccionados.length} seleccionado(s)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _todosSeleccionadosEstanFijados()
                              ? LucideIcons.pinOff
                              : LucideIcons.pin,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        onPressed: () async {
                          final seleccionadosFijados = _chatsSeleccionados
                              .where((id) {
                                final chat = _allChats.firstWhere(
                                  (c) => c.chatId == id,
                                );
                                return chat.fijado;
                              })
                              .toList();

                          final seleccionadosNoFijados = _chatsSeleccionados
                              .where((id) {
                                final chat = _allChats.firstWhere(
                                  (c) => c.chatId == id,
                                );
                                return !chat.fijado;
                              })
                              .toList();

                          final seVanADesfijar = seleccionadosNoFijados.isEmpty;

                          if (!seVanADesfijar) {
                            final totalFijadosActuales = _allChats
                                .where((c) => c.fijado)
                                .length;
                            final nuevosFijados = seleccionadosNoFijados.length;

                            if (totalFijadosActuales + nuevosFijados > 2) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Solo puedes fijar hasta 2 chats',
                                  ),
                                ),
                              );
                              return;
                            }
                          }

                          for (final chatId in _chatsSeleccionados) {
                            final docRef = FirebaseFirestore.instance
                                .collection('chatsVinos')
                                .doc(chatId);
                            await docRef.update({'fijado': !seVanADesfijar});
                          }

                          setState(() {
                            _chatsSeleccionados.clear();
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _chatsSeleccionados.clear();
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
              child: ChatFiltroSelector(
                onFiltroSelected: (filtro) {
                  setState(() {
                    filtroActivo = filtro;
                  });
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ChatResumen>>(
                stream: _streamChats,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Ocurrió un error inesperado."),
                    );
                  }
                  _allChats = snapshot.data ?? [];
                  List<ChatResumen> chats = [..._allChats];
                  if (filtroActivo == 'Chats leídos') {
                    chats = chats.where((c) => c.unreadCount == 0).toList();
                  } else if (filtroActivo == 'Chats no leídos') {
                    chats = chats.where((c) => c.unreadCount > 0).toList();
                  }
                  final query = _searchController.text.toLowerCase();
                  if (query.isNotEmpty) {
                    chats = chats
                        .where((c) => c.nombre.toLowerCase().contains(query))
                        .toList();
                  }
                  if (chats.isEmpty) {
                    return Center(
                      child: Text(
                        "No hay chats disponibles.",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return _ChatItemWidget(
                        resumen: chat,
                        empresaId: empresaId,
                        seleccionado: _chatsSeleccionados.contains(chat.chatId),
                        estaSeleccionando: _estaSeleccionando,
                        onLongPress: (chatId) {
                          setState(() {
                            if (_chatsSeleccionados.contains(chatId)) {
                              _chatsSeleccionados.remove(chatId);
                            } else {
                              _chatsSeleccionados.add(chatId);
                            }
                          });
                        },
                        onTap: (chatId) async {
                          final mensajesSnapshot = await FirebaseFirestore
                              .instance
                              .collection('chatsVinos')
                              .doc(chat.chatId)
                              .collection('messages')
                              .where('authorId', isEqualTo: chat.clienteId)
                              .get();

                          final batch = FirebaseFirestore.instance.batch();
                          for (var doc in mensajesSnapshot.docs) {
                            final readBy = List<String>.from(
                              doc['readBy'] ?? [],
                            );
                            if (!readBy.contains(empresaId)) {
                              batch.update(doc.reference, {
                                'readBy': FieldValue.arrayUnion([empresaId]),
                              });
                            }
                          }

                          await batch.commit();

                          if (!context.mounted) return;
                          navegarConSlideDerecha(
                            context,
                            ContactoEmpresaScreen(
                              userIdVisitante: chat.clienteId,
                            ),
                          );
                        },
                      );
                    },
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

class _ChatItemWidget extends StatelessWidget {
  final ChatResumen resumen;
  final String empresaId;
  final bool seleccionado;
  final bool estaSeleccionando;
  final Function(String chatId) onLongPress;
  final Function(String chatId) onTap;

  const _ChatItemWidget({
    required this.resumen,
    required this.empresaId,
    required this.seleccionado,
    required this.estaSeleccionando,
    required this.onLongPress,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onLongPress: () => onLongPress(resumen.chatId),
      onTap: () async {
        if (estaSeleccionando) {
          onLongPress(resumen.chatId);
        } else {
          await marcarComoLeido(resumen.chatId);
          onTap(resumen.chatId);
        }
      },
      child: Container(
        color: seleccionado
            ? Color.fromARGB(78, 198, 32, 32)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(resumen.fotoUrl),
              backgroundColor: Colors.grey[300],
              radius: 25,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resumen.nombre,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resumen.lastMessage,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (resumen.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 0, 0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  resumen.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (resumen.fijado)
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  LucideIcons.pin,
                  size: 20,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

Future<void> marcarComoLeido(String chatId) async {
  final chatRef = FirebaseFirestore.instance
      .collection('chatsVinos')
      .doc(chatId);

  await chatRef.update({
    'readBy': FieldValue.arrayUnion(['empresa_unica']),
  });
}
