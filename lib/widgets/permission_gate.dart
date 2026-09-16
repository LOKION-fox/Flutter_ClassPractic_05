import 'package:flutter/widgets.dart';

class PermissionGate extends StatelessWidget {
  final bool allowed;
  final Widget child;
  final Widget fallback;

  const PermissionGate({
    super.key,
    required this.allowed,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    return allowed ? child : fallback;
  }
}
