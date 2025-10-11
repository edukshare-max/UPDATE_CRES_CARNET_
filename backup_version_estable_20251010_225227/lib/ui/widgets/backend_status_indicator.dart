// lib/ui/widgets/backend_status_indicator.dart
import 'package:flutter/material.dart';
import '../../data/api_service.dart';

/// Widget que muestra el estado del backend (conectado/desconectado)
/// Útil para dar feedback visual durante cold starts
class BackendStatusIndicator extends StatefulWidget {
  final bool compact;
  const BackendStatusIndicator({super.key, this.compact = false});

  @override
  State<BackendStatusIndicator> createState() => _BackendStatusIndicatorState();
}

class _BackendStatusIndicatorState extends State<BackendStatusIndicator> {
  bool _isChecking = true;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    setState(() => _isChecking = true);
    final online = await ApiService.wakeUpBackend();
    if (mounted) {
      setState(() {
        _isChecking = false;
        _isOnline = online;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      // Versión compacta: solo un punto de color
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _isChecking
              ? Colors.orange
              : (_isOnline ? Colors.green : Colors.red),
          shape: BoxShape.circle,
        ),
      );
    }

    // Versión completa con texto
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isChecking
            ? Colors.orange.withValues(alpha: 0.1)
            : (_isOnline
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isChecking
              ? Colors.orange
              : (_isOnline ? Colors.green : Colors.red),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isChecking)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              _isOnline ? Icons.cloud_done : Icons.cloud_off,
              size: 16,
              color: _isOnline ? Colors.green : Colors.red,
            ),
          const SizedBox(width: 6),
          Text(
            _isChecking
                ? 'Conectando...'
                : (_isOnline ? 'Servidor listo' : 'Servidor inactivo'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _isChecking
                  ? Colors.orange[800]
                  : (_isOnline ? Colors.green[800] : Colors.red[800]),
            ),
          ),
          if (!_isOnline && !_isChecking) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: _checkBackend,
              child: const Icon(Icons.refresh, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
