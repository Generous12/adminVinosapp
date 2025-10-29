import 'package:app_bootsup/VistaCliente/screePrincipal/compras.dart';
import 'package:app_bootsup/VistaCliente/screePrincipal/inicio.dart';
import 'package:app_bootsup/VistaCliente/screePrincipal/perfil.dart';
import 'package:app_bootsup/VistaCliente/screePrincipal/promo.dart';
import 'package:app_bootsup/Widgets/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainScreenVinosClientes extends StatefulWidget {
  final User? user;

  const MainScreenVinosClientes({Key? key, this.user}) : super(key: key);

  @override
  State<MainScreenVinosClientes> createState() => _MainScreenClienteState();
}

class _MainScreenClienteState extends State<MainScreenVinosClientes> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            InicioVinosC(),
            ComprasPageVinosC(),
            ReelsScreen(isVisible: _selectedIndex == 2),
            PerfilPageVinosC(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: CustomBottomNavBarCliente(
            currentIndex: _selectedIndex,
            user: widget.user,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
