// floating_nav_balls.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../widgets/ball.dart';              // ← new public Ball class
import '../pages/destination_page.dart';    // ← new public DestinationPage

/* ───────── constants ───────── */
const _ballSize   = 120.0;
const _startSpeed = 160.0;
const _friction   = 0.90;
const _stopCutoff = 8.0;
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
  final _balls = <Ball>[];                 // ✅ Ball (public)

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
    _balls.addAll([
      Ball(
        pos: rp(),
        vel: rv(),
        color: Colors.indigo,
        icon: Icons.list,
        label: 'Entries',
        navIndex: 1,
        heroTag: 'heroEntries',
      ),
      Ball(
        pos: rp(),
        vel: rv(),
        color: Colors.teal,
        icon: Icons.book,
        label: 'Journal',
        navIndex: 2,
        heroTag: 'heroJournal',
      ),
    ]);
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
        b.pos += b.vel * dt;
        b.vel *= pow(_friction, dt).toDouble();
        if (b.vel.distance < _stopCutoff) b.vel = Offset.zero;

        if (b.pos.dx <= 0 && b.vel.dx < 0 || b.pos.dx >= maxX && b.vel.dx > 0)
          b.vel = Offset(-b.vel.dx, b.vel.dy);
        if (b.pos.dy <= 0 && b.vel.dy < 0 || b.pos.dy >= maxY && b.vel.dy > 0)
          b.vel = Offset(b.vel.dx, -b.vel.dy);

        b.pos = Offset(b.pos.dx.clamp(0, maxX), b.pos.dy.clamp(0, maxY));
      }
    });
  }

  /* ───────── drag helpers ───────── */
  Ball? _dragBall;
  Offset? _start, _origin;

  void _onStart(DragStartDetails d, Ball b) {
    _dragBall = b..isHeld = true;
    _start = d.globalPosition;
    _origin = b.pos;
    b.vel = Offset.zero;
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_dragBall == null) return;
    setState(() => _dragBall!.pos = _origin! + (d.globalPosition - _start!));
    _dragBall!.vel = d.delta * 60;
  }

  void _onEnd(_) => _dragBall?..isHeld = false;

/* ─────────── navigation ─────────── */
  void _open(BuildContext ctx, Ball tapped) {
    // 1. Freeze EVERY ball
    setState(() {
      for (final b in _balls) {
        b.vel = Offset.zero;
      }
    });

    // 2. Stop the ticker so no phantom time passes
    _ticker.stop();

    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => DestinationPage(ball: tapped)),
    ).then((_) {
      if (!mounted) return;

      // 3. Reset time marker and restart physics (all vels are 0, so nothing moves)
      _prev = Duration.zero;
      _ticker.start();
    });
  }




  /* ───────── build ───────── */
  @override
  Widget build(BuildContext context) => Stack(children: [
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
            width:  _ballSize,
            height: _ballSize,
            decoration: BoxDecoration(shape: BoxShape.circle, color: b.color),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(b.icon, color: Colors.white, size: 36),
                const SizedBox(height: 4),
                Text(b.label, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
  ]);
}
