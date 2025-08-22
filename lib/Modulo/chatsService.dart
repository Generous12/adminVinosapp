import 'package:app_bootsup/Clases/ChatResumen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter/foundation.dart';

class ChatServiceEmpresaVinos {
  static const String empresaIdFija = 'empresa_unica';
  static const String coleccionChats = 'chatsVinos';

  static Future<String?> obtenerChatConCliente(String userIdCliente) async {
    try {
      final chats = await FirebaseFirestore.instance
          .collection(coleccionChats)
          .where('userIds', arrayContains: userIdCliente)
          .get();

      for (final doc in chats.docs) {
        final userIds = List<String>.from(doc['userIds'] ?? []);
        if (userIds.contains(empresaIdFija)) {
          debugPrint(
            '✅ Chat encontrado con el cliente $userIdCliente: ${doc.id}',
          );
          return doc.id;
        }
      }

      debugPrint('⚠️ No se encontró chat con el cliente $userIdCliente');
      return null;
    } catch (e) {
      debugPrint('❌ Error al obtener chat con cliente: $e');
      return null;
    }
  }

  /// Obtiene todos los chats existentes con clientes
  static Stream<List<ChatResumen>> obtenerTodosLosChats() {
    return FirebaseFirestore.instance
        .collection(coleccionChats)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<ChatResumen> chats = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final chatId = doc.id;

            final List<dynamic> userIds = data['userIds'] ?? [];
            final clienteId = userIds.firstWhere(
              (id) => id != empresaIdFija,
              orElse: () => '',
            );
            if (clienteId.isEmpty) continue;

            final clienteData = await cargarDatosCliente(clienteId);
            final nombre = clienteData?['username'] ?? 'Cliente';
            final fotoUrl =
                clienteData?['profileImageUrl'] ??
                'https://ui-avatars.com/api/?name=$nombre';

            final unreadCount = await _calcularMensajesNoLeidosParaEmpresa(
              chatId,
            );

            chats.add(
              ChatResumen(
                chatId: chatId,
                clienteId: clienteId,
                nombre: nombre,
                fotoUrl: fotoUrl,
                lastMessage: data['lastMessage'] ?? '',
                unreadCount: unreadCount,
                fijado: data['fijado'] ?? false,
              ),
            );
          }

          // Ordenar: primero fijados, luego no leídos, luego por fecha
          chats.sort((a, b) {
            if (a.fijado && !b.fijado) return -1;
            if (!a.fijado && b.fijado) return 1;
            if (a.unreadCount > 0 && b.unreadCount == 0) return -1;
            if (a.unreadCount == 0 && b.unreadCount > 0) return 1;
            return 0;
          });

          return chats;
        });
  }

  /// Escucha los últimos 30 mensajes de un chat
  static Stream<List<types.TextMessage>> escucharMensajes(String chatId) {
    return FirebaseFirestore.instance
        .collection(coleccionChats)
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return types.TextMessage(
              id: doc.id,
              author: types.User(id: data['authorId']),
              createdAt: data['createdAt'],
              text: data['text'],
            );
          }).toList();
        });
  }

  /// Envía un mensaje de texto a un chat
  static Future<void> enviarMensaje({
    required String chatId,
    required String authorId,
    required types.PartialText mensaje,
  }) async {
    if (mensaje.text.trim().isEmpty) return;

    final nuevoMensaje = {
      'authorId': authorId,
      'text': mensaje.text.trim(),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'readBy': [],
    };

    final chatRef = FirebaseFirestore.instance
        .collection(coleccionChats)
        .doc(chatId);

    try {
      await chatRef.collection('messages').add(nuevoMensaje);
      await chatRef.update({'lastMessage': mensaje.text.trim()});
    } catch (e) {
      debugPrint("❌ Error al enviar mensaje: $e");
    }
  }

  /// Elimina un mensaje de un chat
  static Future<void> eliminarMensaje({
    required String chatId,
    required String mensajeId,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;

      await firestore
          .collection(coleccionChats)
          .doc(chatId)
          .collection('messages')
          .doc(mensajeId)
          .delete();

      debugPrint("✅ Mensaje eliminado correctamente.");

      final mensajesSnapshot = await firestore
          .collection(coleccionChats)
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      String nuevoLastMessage = 'Se eliminó un mensaje';
      if (mensajesSnapshot.docs.isNotEmpty) {
        final ultimoMensaje = mensajesSnapshot.docs.first.data();
        nuevoLastMessage = ultimoMensaje['text'] ?? 'Mensaje';
      }

      await firestore.collection(coleccionChats).doc(chatId).update({
        'lastMessage': nuevoLastMessage,
      });
    } catch (e) {
      debugPrint("❌ Error al eliminar el mensaje y actualizar lastMessage: $e");
    }
  }

  /// Carga los datos del cliente (usuario visitante)
  static Future<Map<String, dynamic>?> cargarDatosCliente(String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      final cacheDoc = await userRef.get(
        const GetOptions(source: Source.cache),
      );
      final cacheData = cacheDoc.data();

      final networkDoc = await userRef.get(
        const GetOptions(source: Source.server),
      );
      final networkData = networkDoc.data();

      return networkData ?? cacheData;
    } catch (e) {
      debugPrint("❌ Error cargando datos cliente: $e");
      return null;
    }
  }

  /// Calcula mensajes no leídos desde la perspectiva de la empresa
  static Future<int> _calcularMensajesNoLeidosParaEmpresa(String chatId) async {
    final mensajesSnapshot = await FirebaseFirestore.instance
        .collection(coleccionChats)
        .doc(chatId)
        .collection('messages')
        .where('authorId', isNotEqualTo: empresaIdFija)
        .get();

    return mensajesSnapshot.docs
        .where(
          (msg) =>
              !(List<String>.from(msg['readBy'] ?? []).contains(empresaIdFija)),
        )
        .length;
  }
}
