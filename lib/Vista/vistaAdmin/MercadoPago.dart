import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class MercadoPagoButton extends StatefulWidget {
  const MercadoPagoButton({super.key});

  @override
  State<MercadoPagoButton> createState() => _MercadoPagoButtonState();
}

class _MercadoPagoButtonState extends State<MercadoPagoButton> {
  bool _isLinked = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkIfLinked();
  }

  /// 🔹 Verifica en Firestore si ya está vinculado
  Future<void> _checkIfLinked() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('empresaVinos')
        .doc(uid)
        .get();
    setState(() {
      _isLinked = doc.exists;
      _loading = false;
    });
  }

  /// 🔹 Pide al backend el link OAuth con el UID
  Future<String> _getLoginUrl() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final response = await http.post(
      Uri.parse("https://adminvinosapp-production.up.railway.app/mp/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"uid": uid}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["url"];
    } else {
      throw Exception("Error obteniendo URL de login");
    }
  }

  /// 🔹 Abre el flujo en un navegador externo
  Future<void> _openExternalBrowser() async {
    final loginUrl = await _getLoginUrl();
    final uri = Uri.parse(loginUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // 🔹 Tras volver, revisamos si ya está vinculado
      await Future.delayed(const Duration(seconds: 3));
      _checkIfLinked();
    } else {
      throw Exception("No se pudo abrir el navegador");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: _isLinked ? Colors.green : Colors.deepPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        elevation: 6,
      ),
      icon: Icon(
        _isLinked ? Icons.check_circle : Icons.link,
        color: Colors.white,
      ),
      label: Text(
        _isLinked ? "Vinculado" : "Vincular con Mercado Pago",
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: _isLinked ? null : _openExternalBrowser,
    );
  }
}
