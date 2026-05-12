import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../providers/game_provider.dart';
import 'package:provider/provider.dart';

class NumpadWidget extends StatelessWidget {
  const NumpadWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(context, [7, 8, 9]),
        const SizedBox(height: 8),
        _buildRow(context, [4, 5, 6]),
        const SizedBox(height: 8),
        _buildRow(context, [1, 2, 3]),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildZeroKey(context),
            const SizedBox(width: 8),
            _buildBackspace(context),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<int> digits) {
    return Row(
      children: digits.map((d) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: d != digits.last ? 8 : 0),
            child: _NumKey(digit: d),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildZeroKey(BuildContext context) {
    return Expanded(
      flex: 2,
      child: _NumKey(digit: 0),
    );
  }

  Widget _buildBackspace(BuildContext context) {
    return Expanded(
      flex: 1,
      child: _BackspaceKey(),
    );
  }
}

class _NumKey extends StatefulWidget {
  final int digit;
  const _NumKey({required this.digit});

  @override
  State<_NumKey> createState() => _NumKeyState();
}

class _NumKeyState extends State<_NumKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        context.read<GameProvider>().inputDigit(widget.digit);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 72,
        decoration: BoxDecoration(
          color: _pressed ? AppTheme.numpadPressed : AppTheme.numpadBg,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.digit.toString(),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _BackspaceKey extends StatefulWidget {
  @override
  State<_BackspaceKey> createState() => _BackspaceKeyState();
}

class _BackspaceKeyState extends State<_BackspaceKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        context.read<GameProvider>().backspace();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 72,
        decoration: BoxDecoration(
          color: _pressed ? AppTheme.numpadPressed : AppTheme.numpadBg,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.backspace_outlined,
          color: AppTheme.textSecondary,
          size: 24,
        ),
      ),
    );
  }
}
