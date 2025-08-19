// floating_nav_balls.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart'; // HapticFeedback

import '../widgets/ball.dart';
import '../pages/destination_page.dart';

/* ───────── constants ───────── */
const _ballSize   = 120.0;
const _startSpeed = 160.0;
const _friction   = 0.90;
const _stopCutoff = 8.0;

// Throw velocity tuning (for better feel on iOS too)
const _maxThrowSpeed = 1600.0;  // clamp crazy flings (px/s)
const _minThrowSpeed = 80.0;    // avoid "dead" throws

// Haptics tuning
const _hapticSpeedMin = 120.0;  // min speed (px/s) to buzz
const _hapticCooldown = 140;    // ms between buzzes per ball

final _rand = Random();

/* ───────── widget ───────── */
class FloatingNavBalls extends StatefulWidget {
  const FloatingNavBalls({super.key});
  @override
  State<FloatingNavBalls> createState() => _FloatingNavBallsState();
}

class _FloatingNavBallsState extends State<FloatingNavBalls>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _prev = Duration.zero;
  final _balls = <Ball>[];

  /* ───────── lifecycle ───────── */
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_balls.isEmpty) _spawn();
  }

  void _spawn() {
    final size = MediaQuery.of(context).size;
    Offset rp() => Offset(
          _rand.nextDouble() * (size.width - _ballSize),
          _rand.nextDouble() * (size.height - _ballSize - 100),
        );
    Offset rv() => Offset(
          (_rand.nextBool() ? 1 : -1) * _startSpeed,
          (_rand.nextBool() ? 1 : -1) * _startSpeed,
        );
    _balls.add(
      Ball(
        pos: rp(),
        vel: rv(),
        color: Colors.indigo,
        icon: Icons.list,
        label: 'Entries',
        navIndex: 1,
        heroTag: 'heroEntries',
      ),
    );
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /* ───────── physics tick ───────── */
  void _tick(Duration t) {
    // Skip the very first tick after we just restarted the ticker
    if (_prev == Duration.zero) {
      _prev = t;
      return;
    }

    final dt = (t - _prev).inMicroseconds / 1e6;
    _prev = t;
    if (dt == 0) return;

    final size = MediaQuery.of(context).size;
    final maxX = size.width - _ballSize;
    final maxY = size.height - _ballSize - 24;

    setState(() {
      for (final b in _balls) {
        if (b.isHeld) continue;

        // Integrate
        b.pos += b.vel * dt;
        b.vel *= pow(_friction, dt).toDouble();
        if (b.vel.distance < _stopCutoff) b.vel = Offset.zero;

        // Edge collisions
        bool bounced = false;
        if ((b.pos.dx <= 0 && b.vel.dx < 0) || (b.pos.dx >= maxX && b.vel.dx > 0)) {
          b.vel = Offset(-b.vel.dx, b.vel.dy);
          bounced = true;
        }
        if ((b.pos.dy <= 0 && b.vel.dy < 0) || (b.pos.dy >= maxY && b.vel.dy > 0)) {
          b.vel = Offset(b.vel.dx, -b.vel.dy);
          bounced = true;
        }

        // Clamp to bounds
        b.pos = Offset(b.pos.dx.clamp(0, maxX), b.pos.dy.clamp(0, maxY));

        // Haptics on meaningful bounce, rate-limited per ball
        if (bounced) {
          final nowMs = t.inMilliseconds;
          final since = nowMs - b.lastHapticMs;
          final impactSpeed = b.vel.distance;
          if (impactSpeed >= _hapticSpeedMin && since >= _hapticCooldown) {
            if (impactSpeed > _hapticSpeedMin * 1.8) {
              HapticFeedback.mediumImpact();
            } else {
              HapticFeedback.lightImpact();
            }
            b.lastHapticMs = nowMs;
          }
        }
      }
    });
  }

  /* ───────── drag helpers ───────── */
  Ball? _dragBall;
  Offset? _start, _origin;

  // For velocity smoothing while dragging (backup if end velocity is tiny)
  Offset? _lastUpdatePos;
  int _lastUpdateMs = 0;

  void _onStart(DragStartDetails d, Ball b) {
    _dragBall = b..isHeld = true;
    _start = d.globalPosition;
    _origin = b.pos;
    b.vel = Offset.zero;

    _lastUpdatePos = d.globalPosition;
    _lastUpdateMs = DateTime.now().millisecondsSinceEpoch;
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_dragBall == null) return;

    // Move with finger
    setState(() => _dragBall!.pos = _origin! + (d.globalPosition - _start!));

    // Smooth, frame-rate independent velocity estimate during drag
    final now = DateTime.now().millisecondsSinceEpoch;
    final dtMs = (now - _lastUpdateMs).clamp(1, 1000); // avoid /0 and spikes
    final delta = d.globalPosition - (_lastUpdatePos ?? d.globalPosition);
    final pxPerSec = Offset(
      delta.dx * 1000 / dtMs,
      delta.dy * 1000 / dtMs,
    );
    _dragBall!.vel = pxPerSec; // provisional velocity while dragging

    _lastUpdatePos = d.globalPosition;
    _lastUpdateMs = now;
  }

  void _onEnd(DragEndDetails d) {
    if (_dragBall == null) return;

    // Prefer Flutter's velocity tracker
    var v = d.velocity.pixelsPerSecond;

    // If Flutter reports almost zero, fall back to our last estimate
    if (v.distance < _minThrowSpeed && _dragBall!.vel.distance >= _minThrowSpeed) {
      v = _dragBall!.vel;
    }

    // Clamp to sensible range so objects don't fly away on 120Hz devices
    double clamp(double x) => x.clamp(-_maxThrowSpeed, _maxThrowSpeed).toDouble();
    _dragBall!.vel = Offset(clamp(v.dx), clamp(v.dy));

    _dragBall!.isHeld = false;
    _dragBall = null;
    _lastUpdatePos = null;
  }

  /* ───────── navigation ───────── */
  void _open(BuildContext ctx, Ball tapped) {
    // Freeze and stop time
    setState(() {
      for (final b in _balls) {
        b.vel = Offset.zero;
      }
    });
    _ticker.stop();

    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => DestinationPage(ball: tapped)),
    ).then((_) {
      if (!mounted) return;
      _prev = Duration.zero;
      _ticker.start();
    });
  }

  /* ───────── build ───────── */
  @override
  Widget build(BuildContext context) => Stack(
        children: [
          for (final b in _balls)
            Positioned(
              left: b.pos.dx,
              top: b.pos.dy,
              child: GestureDetector(
                onPanStart: (d) => _onStart(d, b),
                onPanUpdate: _onUpdate,
                onPanEnd: _onEnd,
                onTap: () => _open(context, b),
                child: Container(
                  width: _ballSize,
                  height: _ballSize,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: b.color),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(b.icon, color: Colors.white, size: 36),
                      const SizedBox(height: 4),
                      Text(b.label,
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
}
