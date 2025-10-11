import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;
  
  const Background({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: child,
    );
  }
}
