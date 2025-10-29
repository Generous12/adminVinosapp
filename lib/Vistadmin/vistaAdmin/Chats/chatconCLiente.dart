import 'package:app_bootsup/Modulo/chatsService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:iconsax/iconsax.dart';

class ContactoEmpresaScreen extends StatefulWidget {
  final String userIdVisitante;
  final DateTime? fechaPedido;
  final String? estadoPedido;
  final double? totalPedido;

  const ContactoEmpresaScreen({
    Key? key,
    required this.userIdVisitante,
    this.fechaPedido,
    this.estadoPedido,
    this.totalPedido,
  }) : super(key: key);

  @override
  State<ContactoEmpresaScreen> createState() => _ContactoEmpresaScreenState();
}

class _ContactoEmpresaScreenState extends State<ContactoEmpresaScreen> {
  final List<types.Message> _mensajes = [];
  bool _isLoading = true;
  String? _chatId;
  late types.User _usuarioEmpresa;
  String? clienteNombre;
  String? clienteFoto;
  final _controller = TextEditingController();
  final Color azulOscuro = const Color(0xFF142143);
  final Color naranja = const Color(0xFFA30000);

  @override
  void initState() {
    super.initState();
    // Empresa única
    _usuarioEmpresa = types.User(id: ChatServiceEmpresaVinos.empresaIdFija);
    _inicializarChat();
  }

  Future<void> _inicializarChat() async {
    setState(() => _isLoading = true);
    _chatId = await ChatServiceEmpresaVinos.obtenerChatConCliente(
      widget.userIdVisitante,
    );

    if (_chatId == null) {
      debugPrint(
        '⚠️ No se encontró chat con el cliente ${widget.userIdVisitante}',
      );
      return;
    }

    ChatServiceEmpresaVinos.escucharMensajes(_chatId!).listen((mensajes) {
      if (!mounted) return;
      setState(() {
        _mensajes
          ..clear()
          ..addAll(mensajes);
      });
    });

    final datosCliente = await ChatServiceEmpresaVinos.cargarDatosCliente(
      widget.userIdVisitante,
    );

    if (datosCliente != null && mounted) {
      setState(() {
        clienteNombre = datosCliente['username'] ?? 'Cliente';
        clienteFoto =
            datosCliente['profileImageUrl'] ??
            'https://ui-avatars.com/api/?name=${clienteNombre ?? "Cliente"}';
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _enviarMensaje(types.PartialText mensaje) async {
    if (_chatId == null) return;

    await ChatServiceEmpresaVinos.enviarMensaje(
      chatId: _chatId!,
      authorId: _usuarioEmpresa.id,
      mensaje: mensaje,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          titleSpacing: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 48,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: Icon(
              Iconsax.arrow_left,
              color: theme.iconTheme.color,
              size: 25,
            ),
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
          ),
          title: Row(
            children: [
              if (clienteFoto != null)
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(clienteFoto!),
                  backgroundColor: Colors.transparent,
                ),
              const SizedBox(width: 10),
              if (clienteNombre != null)
                Expanded(
                  child: Text(
                    clienteNombre!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _chatId == null
            ? const Center(child: Text('No se encontró chat con este cliente'))
            : Column(
                children: [
                  Expanded(
                    child: Chat(
                      messages: List<types.Message>.from(_mensajes),
                      onSendPressed: _enviarMensaje,
                      user: _usuarioEmpresa,
                      showUserAvatars: false,
                      showUserNames: false,
                      theme: DefaultChatTheme(
                        inputBackgroundColor: const Color.fromARGB(
                          255,
                          15,
                          116,
                          89,
                        ),
                        primaryColor: azulOscuro,
                        secondaryColor: naranja,
                        backgroundColor: theme.scaffoldBackgroundColor,
                        sentMessageBodyTextStyle: const TextStyle(
                          color: Colors.white,
                        ),
                        receivedMessageBodyTextStyle: const TextStyle(
                          color: Colors.white,
                        ),
                        inputTextColor: Colors.black,
                        inputTextCursorColor: naranja,
                      ),
                      customBottomWidget: buildCustomInput(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget buildCustomInput() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Theme(
        data: theme.copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: colorScheme.primary.withOpacity(0.5),
            cursorColor: colorScheme.onBackground,
            selectionHandleColor: colorScheme.primary,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                shadowColor: Colors.black12,
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  minLines: 1,
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 17,
                    color: colorScheme.onBackground,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF1F1F1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText: "Escribe un mensaje...",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        color: theme.iconTheme.color?.withOpacity(0.6),
                      ),
                      onPressed: () {
                        // Acción para adjuntar archivos
                      },
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Iconsax.send_2,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      onPressed: () {
                        final text = _controller.text.trim();
                        if (text.isNotEmpty) {
                          _enviarMensaje(types.PartialText(text: text));
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
