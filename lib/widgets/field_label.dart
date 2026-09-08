import 'package:flutter/material.dart';

class FieldLabel extends StatelessWidget {
  final String text;
  final bool isRequired;

  const FieldLabel({
    super.key,
    required this.text,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool showStar = isRequired && !text.toLowerCase().contains('(optional)');

    return RichText(
      text: TextSpan(
        children: [
          if (showStar)
            const TextSpan(
              text: '* ',
              style: TextStyle(color: Colors.red),
            ),
          TextSpan(
            text: text,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
