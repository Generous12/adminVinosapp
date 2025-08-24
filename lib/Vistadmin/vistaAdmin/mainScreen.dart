import 'package:app_bootsup/Vistadmin/vistaAdmin/Chats/Chats.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/inventario/inventario.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/pedidos/pedidos.dart';
import 'package:app_bootsup/Vistadmin/vistaAdmin/perfil.dart';
import 'package:app_bootsup/Widgets/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class MainScreenVinosAdmin extends StatefulWidget {
  final User? user;

  const MainScreenVinosAdmin({Key? key, this.user}) : super(key: key);

  @override
  State<MainScreenVinosAdmin> createState() => _MainScreenAdminState();
}

class _MainScreenAdminState extends State<MainScreenVinosAdmin> {
  int _selectedIndex = 0;
  bool _showBottomBar = true;

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
    _showBottomBar = true;
    _selectedIndex = 0;
    _screens = [
      InventarioPage(),
      PedidosPage(),
      ChatClientesScreen(),
      PerfilPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isPerfilPage = _selectedIndex == 3;

    return Scaffold(
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (!isPerfilPage && scrollNotification is UserScrollNotification) {
              final direction = scrollNotification.direction;
              if (direction == ScrollDirection.forward && !_showBottomBar) {
                setState(() => _showBottomBar = true);
              } else if (direction == ScrollDirection.reverse &&
                  _showBottomBar) {
                setState(() => _showBottomBar = false);
              }
            }
            return false;
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: CustomBottomNavBar(
          currentIndex: _selectedIndex,
          user: widget.user,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              if (index == 3) {
                _showBottomBar = true;
              }
            });
          },
        ),
      ),
    );
  }
}
