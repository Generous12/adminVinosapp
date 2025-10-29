import 'package:flutter/material.dart';

class LoadingOverlayButton extends StatefulWidget {
  final Future<void> Function() onPressedLogic;
  final String text;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? foregroundColor;
  final Color? color;

  const LoadingOverlayButton({
    Key? key,
    required this.onPressedLogic,
    this.icon,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.foregroundColor,
    this.color,
  }) : super(key: key);

  @override
  State<LoadingOverlayButton> createState() => _LoadingOverlayButtonState();
}

class _LoadingOverlayButtonState extends State<LoadingOverlayButton> {
  bool isLoading = false;

  Future<void> _handlePressed() async {
    setState(() => isLoading = true);
    await widget.onPressedLogic();
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final backgroundColor =
        widget.color ??
        widget.backgroundColor ??
        (isDark ? const Color(0xFF2D2D2D) : Colors.black);

    final textColor =
        widget.foregroundColor ??
        widget.textColor ??
        (isDark ? Colors.white : Colors.white);

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: isLoading,
          child: Opacity(
            opacity: isLoading ? 0.5 : 1,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handlePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                elevation: 0.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
                minimumSize: const Size(double.infinity, 50.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: textColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: TextStyle(fontSize: 20, color: textColor),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isLoading)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 76, 76, 76),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class MenuOption {
  final String title;
  final String? description;
  final IconData? icon;
  final List<MenuSubOption>? subOptions;
  final VoidCallback? onTap;

  MenuOption({
    required this.title,
    this.description,
    this.icon,
    this.subOptions,
    this.onTap,
  });
}

class MenuSubOption {
  final String title;
  final IconData? icon;
  final VoidCallback onTap;

  MenuSubOption({required this.title, this.icon, required this.onTap});
}

class FullWidthMenuTile extends StatefulWidget {
  final MenuOption option;

  const FullWidthMenuTile({super.key, required this.option});

  @override
  State<FullWidthMenuTile> createState() => _FullWidthMenuTileState();
}

class _FullWidthMenuTileState extends State<FullWidthMenuTile> {
  bool _expanded = false;

  void _handleTap() {
    if (widget.option.subOptions != null &&
        widget.option.subOptions!.isNotEmpty) {
      setState(() {
        _expanded = !_expanded;
      });
    } else {
      widget.option.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _handleTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 20),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(0),
            ),
            child: Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.option.icon ?? Icons.tune,
                    color: const Color(0xFFA30000),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.option.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (widget.option.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            widget.option.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.option.subOptions != null &&
                    widget.option.subOptions!.isNotEmpty)
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.iconTheme.color?.withOpacity(0.6),
                  ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            children:
                widget.option.subOptions?.map((sub) {
                  return GestureDetector(
                    onTap: () {
                      sub.onTap();
                      setState(() => _expanded = false);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 56,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(
                          0.5,
                        ),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (sub.icon != null) ...[
                            Icon(
                              sub.icon,
                              size: 18,
                              color: theme.colorScheme.primary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            sub.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList() ??
                [],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class FullWidthActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const FullWidthActionButton({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
