import 'package:app_bootsup/VistaCliente/screePrincipal/compras.dart';
import 'package:app_bootsup/VistaCliente/screePrincipal/inicio.dart';
import 'package:app_bootsup/VistaCliente/screePrincipal/perfil.dart';
import 'package:app_bootsup/VistaCliente/screePrincipal/promo.dart';
import 'package:app_bootsup/Widgets/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';

class MainScreenVinos extends StatefulWidget {
  final User? user;

  const MainScreenVinos({Key? key, this.user}) : super(key: key);

  @override
  State<MainScreenVinos> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreenVinos> {
  int _selectedIndex = 0;
  bool _showBottomBar = true;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _showBottomBar = true;
    _selectedIndex = 0;
    _screens = [
      InicioVinosC(),
      ComprasPageVinosC(),
      BuscarPageVinosC(),
      PerfilPageVinosC(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isPerfilPage = _selectedIndex == 3;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (!isPerfilPage && scrollNotification is UserScrollNotification) {
            final direction = scrollNotification.direction;
            if (direction == ScrollDirection.forward && !_showBottomBar) {
              setState(() => _showBottomBar = true);
            } else if (direction == ScrollDirection.reverse && _showBottomBar) {
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
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _showBottomBar ? kBottomNavigationBarHeight : 0,
        child: Wrap(
          children: [
            CustomBottomNavBarCliente(
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
          ],
        ),
      ),
    );
  }
}
