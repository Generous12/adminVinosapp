import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MercadoPagoButton extends StatelessWidget {
  const MercadoPagoButton({super.key});

  Future<String> _getLoginUrl() async {
    // 🔹 Tu backend genera el link con /mp/login
    final response = await http.get(
      Uri.parse("https://adminvinosapp-production.up.railway.app/mp/login"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["url"];
    } else {
      throw Exception("Error obteniendo URL de login");
    }
  }

  void _openWebView(BuildContext context) async {
    final loginUrl = await _getLoginUrl();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewMercadoPago(url: loginUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        elevation: 6,
      ),
      icon: const Icon(Icons.link, color: Colors.white),
      label: const Text(
        "Vincular con Mercado Pago",
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: () => _openWebView(context),
    );
  }
}

class WebViewMercadoPago extends StatefulWidget {
  final String url;
  const WebViewMercadoPago({super.key, required this.url});

  @override
  State<WebViewMercadoPago> createState() => _WebViewMercadoPagoState();
}

class _WebViewMercadoPagoState extends State<WebViewMercadoPago> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            debugPrint("✅ Cargada: $url");
          },
          onNavigationRequest: (navReq) {
            // Captura la redirección de tu backend
            if (navReq.url.contains("/admin?status=success")) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Mercado Pago vinculado con éxito"),
                ),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: WebViewWidget(controller: _controller));
  }
}
