import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EstadisticaService {
  Stream<Map<String, dynamic>> obtenerEstadisticasComprasStream() {
    return FirebaseFirestore.instance.collection('compras').snapshots().map((
      snapshot,
    ) {
      final Map<String, int> comprasPorDia = {};
      double totalIngresos = 0;
      double totalDescuentos = 0;
      double totalImpuestos = 0;
      double totalSubtotal = 0;
      int totalCompras = snapshot.docs.length;

      final Map<String, int> contadorProductos = {};
      final Map<String, int> contadorCategorias = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final usuarioId = data['usuarioId'];
        final fecha = (data['fecha'] as Timestamp?)?.toDate();
        final total = (data['total'] as num?)?.toDouble() ?? 0.0;
        final descuento = (data['descuento'] as num?)?.toDouble() ?? 0.0;
        final impuesto = (data['impuesto'] as num?)?.toDouble() ?? 0.0;
        final subtotal = (data['subtotal'] as num?)?.toDouble() ?? 0.0;
        final productos = data['productos'] as List<dynamic>? ?? [];

        if (usuarioId == null || fecha == null) continue;

        // Compras por día
        final dia = DateFormat('dd/MM').format(fecha);
        comprasPorDia[dia] = (comprasPorDia[dia] ?? 0) + 1;

        // Totales acumulados
        totalIngresos += total;
        totalDescuentos += descuento;
        totalImpuestos += impuesto;
        totalSubtotal += subtotal;

        // Conteo productos y categorías
        for (var producto in productos) {
          final nombre = producto['nombreProducto'] ?? 'Desconocido';
          final categoria = producto['categoria'] ?? 'Sin categoría';
          final cantidad = (producto['cantidad'] ?? 1) as int;

          contadorProductos[nombre] =
              (contadorProductos[nombre] ?? 0) + cantidad;
          contadorCategorias[categoria] =
              (contadorCategorias[categoria] ?? 0) + cantidad;
        }
      }

      // Ordenar
      final topProductos = Map.fromEntries(
        contadorProductos.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      );

      final topCategorias = Map.fromEntries(
        contadorCategorias.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      );

      return {
        'comprasPorDia': comprasPorDia,
        'ingresosTotales': totalIngresos,
        'descuentosTotales': totalDescuentos,
        'impuestosTotales': totalImpuestos,
        'subtotalPromedio': totalCompras > 0 ? totalSubtotal / totalCompras : 0,
        'totalCompras': totalCompras,
        'topProductos': topProductos,
        'topCategorias': topCategorias,
      };
    });
  }
}
