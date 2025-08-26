import 'package:app_bootsup/Modulo/inventarioService.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'dart:ui' as ui;

class CategoriaSelector extends StatefulWidget {
  final Function(String) onCategoriaSelected;

  const CategoriaSelector({super.key, required this.onCategoriaSelected});

  @override
  State<CategoriaSelector> createState() => _CategoriaSelectorState();
}

class _CategoriaSelectorState extends State<CategoriaSelector> {
  String? selectedCategoria;

  final List<Map<String, dynamic>> categorias = [
    {'label': 'General', 'icon': LucideIcons.shapes}, // ícono de categoría
    {'label': 'Vino Tinto', 'icon': LucideIcons.wine}, // ícono de vino
    {'label': 'Vino Blanco', 'icon': LucideIcons.wine}, // ícono de vino
    {'label': 'Pisco Quebranta', 'icon': LucideIcons.martini},
    {'label': 'Pisco Acholado', 'icon': LucideIcons.martini},
    {'label': 'Pisco Italia', 'icon': LucideIcons.martini},
    {'label': 'Pisco Mosto Verde', 'icon': LucideIcons.martini},
  ];

  @override
  void initState() {
    super.initState();
    selectedCategoria = 'General';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCategoriaSelected(selectedCategoria!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        itemCount: categorias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 5),
        itemBuilder: (context, index) {
          final categoria = categorias[index]['label'];
          final icon = categorias[index]['icon'];
          final isSelected = selectedCategoria == categoria;

          final selectedColor = isDark ? const Color(0xFFA30000) : Colors.black;
          final backgroundColor = isSelected
              ? selectedColor
              : (isDark ? Colors.grey.shade900 : Colors.grey.shade200);
          final textColor = isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87);

          return GestureDetector(
            onTap: () async {
              setState(() {
                selectedCategoria = categoria;
              });

              if (categoria == 'General') {
                await InventarioService().listarProductos();
              } else {
                await InventarioService().listarProductosPorCategoria(
                  categoria,
                );
              }

              widget.onCategoriaSelected(categoria);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? selectedColor
                      : (isDark ? Colors.white12 : Colors.black26),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: selectedColor.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 17, color: textColor),
                  const SizedBox(width: 6),
                  Text(
                    categoria,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ImageRatioSelector extends StatefulWidget {
  final Function(double, double) onRatioSelected;
  final bool isDisabled;

  const ImageRatioSelector({
    super.key,
    required this.onRatioSelected,
    required this.isDisabled,
  });

  @override
  State<ImageRatioSelector> createState() => _ImageRatioSelectorState();
}

class _ImageRatioSelectorState extends State<ImageRatioSelector> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _ratios = [
    {
      'label': '1x1',
      'desc': 'Cuadrado',
      'ratio': [1.0, 1.0],
    },
    {
      'label': '3x4',
      'desc': 'Vertical clásico',
      'ratio': [3.0, 4.0],
    },
    {
      'label': '4x5',
      'desc': 'Retrato',
      'ratio': [4.0, 5.0],
    },
  ];
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark ? Colors.white : Colors.black;
    final backgroundHighlight = isDark
        ? Colors.grey.shade800
        : const Color.fromARGB(100, 255, 98, 98);
    final chipSelectedColor = isDark ? Colors.white : Colors.black;
    final chipUnselectedColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SizedBox(
        height: 110,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final buttonWidth = constraints.maxWidth / _ratios.length;

            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Fondo animado
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  left: _selectedIndex * buttonWidth,
                  top: 0,
                  width: buttonWidth,
                  height: 110,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 1.2),
                      color: backgroundHighlight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                // Botones
                Row(
                  children: List.generate(_ratios.length, (index) {
                    final isSelected = _selectedIndex == index;
                    final ratio = _ratios[index]['ratio'];
                    final label = _ratios[index]['label'];
                    final double ratioHeight = 52;
                    final double ratioWidth =
                        ratioHeight * (ratio[0] / ratio[1]);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!widget.isDisabled) {
                            setState(() => _selectedIndex = index);
                            widget.onRatioSelected(ratio[0], ratio[1]);
                          }
                        },
                        child: Container(
                          height: 110,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: ratioWidth,
                                height: ratioHeight,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? chipSelectedColor
                                      : chipUnselectedColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _ratios[index]['desc'],
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PedidoFiltroSelector extends StatefulWidget {
  final Function(String) onFiltroSelected;

  const PedidoFiltroSelector({Key? key, required this.onFiltroSelected})
    : super(key: key);

  @override
  State<PedidoFiltroSelector> createState() => PedidoFiltroSelectorState();
}

class PedidoFiltroSelectorState extends State<PedidoFiltroSelector> {
  String? filtroSeleccionado;

  final List<Map<String, dynamic>> filtros = [
    {'label': 'No atendido', 'icon': Iconsax.warning_2},
    {'label': 'Recibidos', 'icon': Iconsax.receipt},
    {'label': 'Preparación', 'icon': Iconsax.box},
    {'label': 'Enviado', 'icon': Iconsax.truck_fast},
  ];

  @override
  void initState() {
    super.initState();
    filtroSeleccionado = 'No atendido';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFiltroSelected(filtroSeleccionado!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filtros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filtro = filtros[index]['label'];
          final icon = filtros[index]['icon'];
          final isSelected = filtroSeleccionado == filtro;

          final selectedColor = isDark ? const Color(0xFFA30000) : Colors.black;
          final backgroundColor = isSelected
              ? selectedColor
              : (isDark ? Colors.grey.shade900 : Colors.grey.shade200);
          final textColor = isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87);

          return GestureDetector(
            onTap: () {
              setState(() {
                filtroSeleccionado = filtro;
              });
              widget.onFiltroSelected(filtro);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? selectedColor
                      : (isDark ? Colors.white12 : Colors.black26),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: textColor),
                  const SizedBox(width: 6),
                  Text(
                    filtro,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChatFiltroSelector extends StatefulWidget {
  final Function(String) onFiltroSelected;

  const ChatFiltroSelector({super.key, required this.onFiltroSelected});

  @override
  State<ChatFiltroSelector> createState() => _ChatFiltroSelectorState();
}

class _ChatFiltroSelectorState extends State<ChatFiltroSelector> {
  String? filtroSeleccionado;

  final List<Map<String, dynamic>> filtros = [
    {'label': 'Todos', 'icon': Iconsax.message},
    {'label': 'No leídos', 'icon': Iconsax.sms},
    {'label': 'Leídos', 'icon': Iconsax.tick_circle},
  ];

  @override
  void initState() {
    super.initState();
    filtroSeleccionado = 'Todos';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFiltroSelected(filtroSeleccionado!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filtros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filtro = filtros[index]['label'];
          final icon = filtros[index]['icon'];
          final isSelected = filtroSeleccionado == filtro;

          final selectedColor = isDark ? const Color(0xFFA30000) : Colors.black;
          final backgroundColor = isSelected
              ? selectedColor
              : (isDark ? Colors.grey.shade900 : Colors.grey.shade200);
          final textColor = isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87);

          return GestureDetector(
            onTap: () {
              setState(() {
                filtroSeleccionado = filtro;
              });
              widget.onFiltroSelected(filtro);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? selectedColor
                      : (isDark ? Colors.white12 : Colors.black26),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: textColor),
                  const SizedBox(width: 6),
                  Text(
                    filtro,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CategoriaSelectorVinos extends StatefulWidget {
  final Function(String) onCategoriaSelected;

  const CategoriaSelectorVinos({super.key, required this.onCategoriaSelected});

  @override
  State<CategoriaSelectorVinos> createState() => _CategoriaSelectorStateV();
}

class _CategoriaSelectorStateV extends State<CategoriaSelectorVinos> {
  String? selectedCategoria;
  final List<Map<String, dynamic>> categorias = [
    {'label': 'General', 'icon': LucideIcons.shapes}, // ícono de categoría
    {'label': 'Vino Tinto', 'icon': LucideIcons.wine}, // ícono de vino
    {'label': 'Vino Blanco', 'icon': LucideIcons.wine}, // ícono de vino
    {'label': 'Pisco Quebranta', 'icon': LucideIcons.martini},
    {'label': 'Pisco Acholado', 'icon': LucideIcons.martini},
    {'label': 'Pisco Italia', 'icon': LucideIcons.martini},
    {'label': 'Pisco Mosto Verde', 'icon': LucideIcons.martini},
  ];

  @override
  void initState() {
    super.initState();
    selectedCategoria = 'General';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onCategoriaSelected(selectedCategoria!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categorias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final categoria = categorias[index]['label'];
          final icon = categorias[index]['icon'];
          final isSelected = selectedCategoria == categoria;

          final backgroundColor = isSelected
              ? (isDark ? const Color(0xFFA30000) : Colors.black)
              : (isDark ? Colors.grey.shade900 : const Color(0xFFFAFAFA));
          final textColor = isSelected
              ? (isDark ? Colors.black : Colors.white)
              : (isDark ? Colors.white70 : Colors.black);

          return GestureDetector(
            onTap: () async {
              setState(() {
                selectedCategoria = categoria;
              });

              if (categoria == 'General') {
                await InventarioService().listarProductos();
              } else {
                await InventarioService().listarProductosPorCategoria(
                  categoria,
                );
              }

              widget.onCategoriaSelected(categoria);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : Colors.black.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: textColor),
                  const SizedBox(width: 6),
                  Text(
                    categoria,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CantidadSelectorHorizontal extends StatelessWidget {
  final int cantidadSeleccionada;
  final ValueChanged<int> onSeleccionar;

  const CantidadSelectorHorizontal({
    super.key,
    required this.cantidadSeleccionada,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(10, (index) {
            final numero = index + 1;
            final bool seleccionado = cantidadSeleccionada == numero;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: InkWell(
                onTap: () => onSeleccionar(numero),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: seleccionado
                        ? colorScheme.primary
                        : colorScheme.surface,
                    border: Border.all(
                      color: seleccionado
                          ? colorScheme.primary.withOpacity(0.8)
                          : colorScheme.outlineVariant,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$numero',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: seleccionado
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class SeguimientoEnvio extends StatelessWidget {
  final String estado;

  SeguimientoEnvio({required this.estado});

  final List<String> estados = [
    'No atendido',
    'Recibidos',
    'Preparación',
    'Enviado',
  ];

  final List<IconData> iconos = [
    Icons.inbox,
    Icons.download_done,
    Icons.kitchen,
    Icons.local_shipping,
  ];

  int _estadoToIndex(String estado) {
    return estados.indexWhere((e) => e.toLowerCase() == estado.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final index = _estadoToIndex(estado);
    return SizedBox(
      height: 90,
      child: Row(
        children: List.generate(estados.length * 2 - 1, (i) {
          final isTile = i.isEven;
          final idx = i ~/ 2;

          if (isTile) {
            final isActive = idx <= index;
            return Expanded(
              flex: 1,
              child: TimelineTile(
                axis: TimelineAxis.horizontal,
                alignment: TimelineAlign.center,
                isFirst: idx == 0,
                isLast: idx == estados.length - 1,
                beforeLineStyle: LineStyle(
                  color: isActive
                      ? const ui.Color(0xFFA30000) //aqui era orange
                      : Colors.grey.shade300,
                  thickness: 4,
                ),
                afterLineStyle: LineStyle(
                  color: idx < index
                      ? const Color(0xFFA30000) //aqui era orange
                      : Colors.grey.shade300,
                  thickness: 4,
                ),
                indicatorStyle: IndicatorStyle(
                  width: 30,
                  height: 30,
                  indicatorXY: 0.5,
                  color: isActive
                      ? const ui.Color(0xFFA30000) //aqui era orange
                      : Colors.grey.shade300,
                  iconStyle: IconStyle(
                    iconData: iconos[idx],
                    color: Colors.white,
                  ),
                ),
                startChild: idx == 0 ? Container() : null,
                endChild: idx == estados.length - 1 ? Container() : null,
              ),
            );
          } else {
            return const SizedBox(width: 4);
          }
        }),
      ),
    );
  }
}

//estado
Color colorEstado(String estado) {
  switch (estado) {
    case 'Recibidos':
      return const Color.fromARGB(255, 0, 145, 255);
    case 'Preparación':
      return Colors.orange;
    case 'Enviado':
      return Colors.green;
    default:
      return Colors.grey;
  }
}
