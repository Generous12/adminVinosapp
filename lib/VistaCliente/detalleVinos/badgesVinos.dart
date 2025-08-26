import 'package:app_bootsup/Modulo/crritoServiceV.dart';
import 'package:app_bootsup/VistaCliente/detalleVinos/carrito.dart';
import 'package:app_bootsup/Widgets/navegator.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class IconoCarritoConBadgeVinos extends StatefulWidget {
  final bool usarEstiloBoton;
  final double altura;
  final double iconSize;
  final Color fondoColor;
  final Color iconColor;
  final double borderRadius;

  const IconoCarritoConBadgeVinos({
    super.key,
    this.usarEstiloBoton = false,
    this.altura = 48.0,
    this.iconSize = 22.0,
    this.fondoColor = const Color.fromARGB(0, 0, 0, 0),
    this.iconColor = Colors.white,
    this.borderRadius = 8.0,
  });

  @override
  State<IconoCarritoConBadgeVinos> createState() =>
      _IconoCarritoConBadgeState();
}

class _IconoCarritoConBadgeState extends State<IconoCarritoConBadgeVinos> {
  @override
  Widget build(BuildContext context) {
    final carrito = Provider.of<CarritoServiceVinos>(context);
    int cantidadCarrito = carrito.obtenerCantidadTotal();

    Widget icono = IconButton(
      icon: Icon(Iconsax.bag, color: widget.iconColor, size: widget.iconSize),
      onPressed: () {
        navegarConSlideArriba(context, CarritoPageVinos());
      },
    );

    if (widget.usarEstiloBoton) {
      icono = Container(
        height: widget.altura,
        width: widget.altura,
        decoration: BoxDecoration(
          color: widget.fondoColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Center(child: icono),
      );
    }

    return badges.Badge(
      position: badges.BadgePosition.topEnd(top: -1, end: 28),
      showBadge: cantidadCarrito > 0,
      badgeContent: Text(
        '$cantidadCarrito',
        style: const TextStyle(color: Colors.white, fontSize: 8),
      ),
      badgeStyle: const badges.BadgeStyle(
        badgeColor: Color.fromARGB(255, 255, 0, 0),
      ),
      child: icono,
    );
  }
}
