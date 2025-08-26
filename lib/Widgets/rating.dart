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
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              'Filtrar productos por',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 5),
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
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Icon(icon, color: const Color(0xFFFFAF00)),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(
            LucideIcons.chevronRight,
            color: isDark ? Colors.white : Colors.black,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
