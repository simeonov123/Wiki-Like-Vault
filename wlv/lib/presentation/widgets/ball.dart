import 'package:flutter/material.dart';

class Ball {
  Offset pos, vel;
  final Color color;
  final IconData icon;
  final String label, heroTag;
  final int navIndex;
  bool isHeld;

  // Tracks last time (ms) when this ball triggered haptics
  int lastHapticMs;

  Ball({
    required this.pos,
    required this.vel,
    required this.color,
    required this.icon,
    required this.label,
    required this.navIndex,
    required this.heroTag,
    this.isHeld = false,
    this.lastHapticMs = 0, // default: never triggered
  });
}
