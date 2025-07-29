// FloatingNavBalls
// Two draggable circles.  When tapped, the circle itself grows until it
// covers the entire screen; only THEN does the page body fade in.  Back
// navigation reverses the sequence.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/entries_list_page.dart';
import '../pages/journal_list_page.dart';
import '../pages/add_entry_page.dart';
import '../pages/add_journal_entry_page.dart';
import '../providers/entry_providers.dart';
import '../providers/journal_providers.dart';

const _ballSize = 120.0;
const _startSpeed = 160.0;
const _friction = 0.90;
const _stopCutoff = 8.0;
final _rand = Random();

class FloatingNavBalls extends StatefulWidget {
  const FloatingNavBalls({super.key});
  @override
  State<FloatingNavBalls> createState() => _FloatingNavBallsState();
}

class _Ball {
  Offset pos, vel;
  final Color color;
  final IconData icon;
  final String label, heroTag;
  final int navIndex;
  bool isHeld = false;
  _Ball({
    required this.pos,
    required this.vel,
    required this.color,
    required this.icon,
    required this.label,
    required this.navIndex,
    required this.heroTag,
  });
}

class _FloatingNavBallsState extends State<FloatingNavBalls>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _prev = Duration.zero;
  final _balls = <_Ball>[];

  /* ───────────────── lifecycle ───────────────── */
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
      _Ball(
        pos: rp(),
        vel: rv(),
        color: Colors.indigo,
        icon: Icons.list,
        label: 'Entries',
        navIndex: 1,
        heroTag: 'heroEntries',
      ),
      _Ball(
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

  /* ───────────────── physics tick ───────────────── */
  void _tick(Duration t) {
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

  /* ───────────────── drag helpers ───────────────── */
  _Ball? _dragBall;
  Offset? _start, _origin;
  void _onStart(DragStartDetails d, _Ball b) {
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

  void _onEnd(_) {
    _dragBall?..isHeld = false;
  }

  /* ───────────────── navigation ───────────────── */
  void _open(BuildContext ctx, _Ball b) => Navigator.push(
        ctx,
        PageRouteBuilder(
          opaque: false, // show growing circle
          transitionDuration: const Duration(milliseconds: 900),
          reverseTransitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => _DestinationPage(ball: b),
        ),
      );

  /* ───────────────── build ───────────────── */
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
              child: Hero(
                tag: b.heroTag,
                flightShuttleBuilder: (fc, anim, __, ___, ____) {
                  final sz = MediaQuery.of(fc).size;
                  final maxR =
                      sqrt(sz.width * sz.width + sz.height * sz.height) /
                          (_ballSize / 2);
                  return ScaleTransition(
                    scale: Tween<double>(begin: 1, end: maxR).animate(
                        CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
                    child: Container(
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: b.color),
                    ),
                  );
                },
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
          ),
      ]);
}

/* ───────────────── Destination page ───────────────── */
class _DestinationPage extends StatefulWidget {
  final _Ball ball;
  const _DestinationPage({required this.ball});
  @override
  State<_DestinationPage> createState() => _DestinationPageState();
}

class _DestinationPageState extends State<_DestinationPage> {
  bool _bodyVisible = false;
  PageRoute? _route;

  @override
  void initState() {
    super.initState();

    // Fade‑IN once the circle has finished expanding (~900 ms)
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _bodyVisible = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Attach exactly one listener so we can fade‑OUT immediately on pop
    if (_route == null) {
      final r = ModalRoute.of(context);
      if (r is PageRoute && r.animation != null) {
        _route = r;
        _route!.animation!.addStatusListener((status) {
          if (status == AnimationStatus.reverse && mounted) {
            setState(() => _bodyVisible = false); // hide body right away
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _route?.animation?.removeStatusListener((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.ball.navIndex == 1
        ? const EntriesListBody()
        : const JournalListBody();
    final fab =
        widget.ball.navIndex == 1 ? const _EntriesFab() : const _JournalFab();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: widget.ball.heroTag,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: widget.ball.color, // keep ball colour
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _bodyVisible ? 1 : 0,
            duration: const Duration(
                milliseconds: 430), // match the reverseTransitionDuration
            curve: Curves.easeOut, // smooth ease‑out
            child: body,
          ),
        ],
      ),
      floatingActionButton: _bodyVisible ? fab : null,
    );
  }
}

/* ───────────────── FABs ───────────────── */
class _EntriesFab extends ConsumerWidget {
  const _EntriesFab({super.key});
  @override
  Widget build(BuildContext ctx, WidgetRef ref) => FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
              ctx, MaterialPageRoute(builder: (_) => const AddEntryPage()));
          ref.invalidate(entriesFutureProvider);
        },
        child: const Icon(Icons.add),
      );
}

class _JournalFab extends ConsumerWidget {
  const _JournalFab({super.key});
  @override
  Widget build(BuildContext ctx, WidgetRef ref) => FloatingActionButton(
        onPressed: () async {
          await Navigator.push(ctx,
              MaterialPageRoute(builder: (_) => const AddJournalEntryPage()));
          ref.invalidate(journalsFutureProvider);
        },
        child: const Icon(Icons.add),
      );
}
