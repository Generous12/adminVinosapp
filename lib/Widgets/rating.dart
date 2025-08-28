import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lucide_icons/lucide_icons.dart';

Widget ratingResumen(
  String productoId, {
  Axis direction = Axis.horizontal,
  bool mostrarTexto = true,
  double itemSize = 18.0,
}) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('VinosPiscosProductos')
        .doc(productoId)
        .collection('comentarios')
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const SizedBox.shrink();
      }

      final comentarios = snapshot.data!.docs;

      // Calcular promedio
      double total = 0.0;
      for (var doc in comentarios) {
        final data = doc.data() as Map<String, dynamic>;
        final rating = (data['rating'] ?? 0.0) as num;
        total += rating.toDouble();
      }

      final promedio = comentarios.isEmpty ? 0.0 : total / comentarios.length;

      final isDark = Theme.of(context).brightness == Brightness.dark;

      final ratingBar = RatingBarIndicator(
        rating: promedio,
        itemBuilder: (context, _) =>
            Icon(Iconsax.star, color: const Color(0xFFA30000)),
        itemCount: 5,
        itemSize: itemSize,
        direction: direction,
        unratedColor: Theme.of(context).iconTheme.color?.withOpacity(0.3),
      );

      final ratingText = Text(
        promedio.toStringAsFixed(1),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: itemSize - 3,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      );

      if (direction == Axis.horizontal) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ratingBar,
            if (mostrarTexto) const SizedBox(width: 8),
            if (mostrarTexto) ratingText,
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mostrarTexto) ratingText,
            if (mostrarTexto) const SizedBox(height: 6),
            ratingBar,
          ],
        );
      }
    },
  );
}

class FiltrosAdicionalesSheet extends StatelessWidget {
  final void Function(String criterio) onFiltroSeleccionado;

  const FiltrosAdicionalesSheet({
    super.key,
    required this.onFiltroSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111111) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de sheet
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtrar productos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Icon(
                  LucideIcons.slidersHorizontal,
                  color: const Color(0xFFA30000),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filtros
            _buildFiltroTile(
              context: context,
              icon: LucideIcons.messageCircle,
              label: 'Más comentados',
              onTap: () => onFiltroSeleccionado('comentarios'),
            ),
            _buildFiltroTile(
              context: context,
              icon: LucideIcons.clock,
              label: 'Más recientes',
              onTap: () => onFiltroSeleccionado('recientes'),
            ),
            _buildFiltroTile(
              context: context,
              icon: LucideIcons.arrowDown,
              label: 'Precio: menor a mayor',
              onTap: () => onFiltroSeleccionado('precioMenor'),
            ),
            _buildFiltroTile(
              context: context,
              icon: LucideIcons.arrowUp,
              label: 'Precio: mayor a menor',
              onTap: () => onFiltroSeleccionado('precioMayor'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          splashColor: const Color(0xFFA30000).withOpacity(0.15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDark ? const Color(0xFF1C1C1C) : Colors.grey[100],
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFA30000), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
