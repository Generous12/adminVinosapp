import 'package:app_bootsup/Vistadmin/vistaAdmin/Chats/Chats.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/inventario/inventario.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/pedidos/pedidos.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/perfiladmin.dart';
import 'package:app_bootsup/Widgets/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class MainScreenVinosAdmin extends StatefulWidget {
  final User? user;

  const MainScreenVinosAdmin({Key? key, this.user}) : super(key: key);

  @override
  State<MainScreenVinosAdmin> createState() => _MainScreenAdminState();
}

class _MainScreenAdminState extends State<MainScreenVinosAdmin> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

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

    _screens = [
      InventarioPage(),
      PedidosPage(),
      ChatClientesScreen(),
      PerfilPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _screens),

        bottomNavigationBar: SafeArea(
          child: CustomBottomNavBar(
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
