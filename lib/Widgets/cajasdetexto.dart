import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? label; // Etiqueta arriba (opcional)
  final String? hintText; // Hint dentro
  final IconData? prefixIcon; // Icono al inicio (opcional)
  final bool obscureText; // Si es contraseña (oculta texto)
  final bool isNumeric; // Para teclado numérico
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final bool showCounter;
  final bool enabled;

  const CustomTextField({
    Key? key,
    this.enabled = true,
    required this.controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.isNumeric = false,
    this.maxLength,
    this.maxLines = 1,
    this.minLines = 1,
    this.onChanged,
    this.focusNode,
    this.showCounter = false,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isMultiline = widget.maxLines! > 1;

    return Theme(
      data: theme.copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: colorScheme.primary,
          cursorColor: colorScheme.onBackground,
          selectionHandleColor: colorScheme.primary,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 0),
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.isNumeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.multiline,
          obscureText: _obscureText,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          minLines: widget.minLines ?? 1,
          onChanged: widget.onChanged,
          focusNode: widget.focusNode,
          cursorColor: colorScheme.onBackground,
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 15.5,
            color: colorScheme.onBackground,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 15.5,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            alignLabelWithHint: isMultiline,
            hintText: widget.hintText,
            hintStyle: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 15.5,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
            prefixIcon: widget.prefixIcon != null && !isMultiline
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      widget.prefixIcon,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            counterText: widget.showCounter ? null : "",
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : const Color(0xFFD4D4D4),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.onBackground,
                width: 1.3,
              ),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Iconsax.eye : Iconsax.eye_slash,
                      color: colorScheme.onBackground,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

Widget buildDetalleFila(BuildContext context, String titulo, String valor) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: isDark ? Colors.grey.shade800 : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onBackground,
          ),
        ),
      ],
    ),
  );
}
