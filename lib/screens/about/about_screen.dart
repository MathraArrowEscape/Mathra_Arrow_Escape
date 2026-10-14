import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/audio_haptic_helper.dart';
import '../../core/constants.dart';

/// About screen for Mathra Arrow Escape.
/// - 3D tilting badge (auto sway + drag to rotate)
/// - Falling snow, rain and lightning effects, each with its own toggle button
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  static const String developerName = 'Denuwan Akash';
  static const String developerNameSi = 'දෙනුවන් ආකාශ්';
  static const String version = 'v1.0.12';

  final _rng = Random();
  late final Ticker _ticker;
  final _WeatherState _weather = _WeatherState();

  bool _snow = true;
  bool _rain = false;
  bool _lightning = false;
  bool _arrows = true;
  bool _sparks = false;
  bool _meteors = false;
  bool _teddy = true;
  bool _hearts = false;
  bool _party = false;
  bool _confetti = false;

  // 3D drag rotation
  double _dragX = 0; // rotation around Y axis (radians)
  double _dragY = 0; // rotation around X axis (radians)
  bool _dragging = false;
  double _time = 0;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _weather.seed(_rng);
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _time += dt;
    final size = MediaQuery.sizeOf(context);
    _weather.update(
      dt,
      size,
      _rng,
      snow: _snow,
      rain: _rain,
      lightning: _lightning,
      arrows: _arrows,
      sparks: _sparks,
      meteors: _meteors,
      teddy: _teddy,
      hearts: _hearts,
      party: _party,
      confetti: _confetti,
    );

    // Spring the drag rotation back to centre when released.
    if (!_dragging) {
      _dragX *= pow(0.04, dt).toDouble();
      _dragY *= pow(0.04, dt).toDouble();
    }
    // Rebuild only the 3D badge via notifier.
    _badgeTick.value++;
  }

  final ValueNotifier<int> _badgeTick = ValueNotifier<int>(0);

  @override
  void dispose() {
    _ticker.dispose();
    _badgeTick.dispose();
    _weather.dispose();
    super.dispose();
  }

  void _toggle(String which) {
    AudioHapticHelper.playClick();
    setState(() {
      switch (which) {
        case 'snow':
          _snow = !_snow;
          break;
        case 'rain':
          _rain = !_rain;
          break;
        case 'arrows':
          _arrows = !_arrows;
          break;
        case 'sparks':
          _sparks = !_sparks;
          break;
        case 'teddy':
          _teddy = !_teddy;
          break;
        case 'hearts':
          _hearts = !_hearts;
          break;
        case 'party':
          _party = !_party;
          break;
        case 'confetti':
          _confetti = !_confetti;
          break;
        case 'meteors':
          _meteors = !_meteors;
          break;
        case 'lightning':
          _lightning = !_lightning;
          if (_lightning) _weather.triggerStrikeSoon();
          break;
      }
    });
  }

  void _allOn(bool on) {
    AudioHapticHelper.playClick();
    setState(() {
      _snow = on;
      _rain = on;
      _lightning = on;
      _arrows = on;
      _sparks = on;
      _meteors = on;
      _teddy = on;
      _hearts = on;
      _party = on;
      _confetti = on;
      if (on) _weather.triggerStrikeSoon();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stormy = _rain || _lightning;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient (gets darker/stormier with rain + lightning)
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: stormy
                    ? const [Color(0xFF05070F), Color(0xFF0B1226), Color(0xFF020409)]
                    : const [Color(0xFF0A1330), Color(0xFF0E1E4A), Color(0xFF040814)],
              ),
            ),
          ),

          // Weather layer
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _WeatherPainter(_weather),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                _TopBar(onBack: () => Navigator.pop(context)),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _build3DBadge(),
                        const SizedBox(height: 18),
                        _buildTitle(),
                        const SizedBox(height: 16),
                        _buildAboutCard(),
                        const SizedBox(height: 16),
                        _buildDeveloperCard(),
                        const SizedBox(height: 20),
                        _buildEffectButtons(),
                        const SizedBox(height: 14),
                        Text(
                          '${AppConstants.appName}  $version',
                          style: const TextStyle(
                            color: Color(0xFF6C7BA8),
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lightning screen flash on top of everything
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _FlashPainter(_weather)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- 3D badge

  Widget _build3DBadge() {
    final size = MediaQuery.sizeOf(context).width * 0.68;
    return GestureDetector(
      onPanStart: (_) => _dragging = true,
      onPanUpdate: (d) {
        _dragX = (_dragX + d.delta.dx * 0.012).clamp(-0.9, 0.9);
        _dragY = (_dragY - d.delta.dy * 0.012).clamp(-0.6, 0.6);
      },
      onPanEnd: (_) => _dragging = false,
      onPanCancel: () => _dragging = false,
      child: ValueListenableBuilder<int>(
        valueListenable: _badgeTick,
        builder: (context, _, child) {
          final swayY = sin(_time * 0.9) * 0.28;
          final swayX = cos(_time * 0.7) * 0.10;
          final bob = sin(_time * 1.6) * 8;
          final matrix = Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(swayY + _dragX)
            ..rotateX(swayX + _dragY);
          final shadowScale = 1 - (bob / 60);

          return SizedBox(
            width: size,
            height: size + 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // ground glow / shadow
                Positioned(
                  bottom: 0,
                  child: Transform.scale(
                    scaleX: shadowScale,
                    child: Container(
                      width: size * 0.6,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2A7BFF).withValues(alpha: 0.55),
                            blurRadius: 30,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12 + bob,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: matrix,
                    child: child,
                  ),
                ),
              ],
            ),
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A7BFF).withValues(alpha: 0.6),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/mathra_badge.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 700.ms).scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
          duration: 800.ms,
        );
  }

  // ------------------------------------------------------------------- title

  Widget _buildTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [Color(0xFFFFE259), Color(0xFFFFA400)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(rect),
          child: const Text(
            'MATHRA',
            style: TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
              height: 1,
              shadows: [Shadow(color: Color(0xAAFFA400), blurRadius: 18)],
            ),
          ),
        ),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [Color(0xFF7DF9FF), Color(0xFF2A7BFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(rect),
          child: const Text(
            'ARROW ESCAPE',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
              height: 1.1,
              shadows: [Shadow(color: Color(0xAA2A7BFF), blurRadius: 18)],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 250.ms, duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  // ------------------------------------------------------------- about cards

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A3D).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF3D8BFF).withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A7BFF).withValues(alpha: 0.25),
            blurRadius: 22,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAboutCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.info_rounded, color: Color(0xFFFFC83D), size: 20),
              SizedBox(width: 8),
              Text(
                'ABOUT THE GAME',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Mathra Arrow Escape is a slick, satisfying arrow puzzle. Every '
            'arrow points a direction, and your job is to slide each one off '
            'the board without crashing into another. Think a few moves '
            'ahead, clear the path, and escape!\n\n'
            'Race through hand-crafted style levels, take on boss and god '
            'stages, chill in Zen mode, beat the clock in Time Attack, or '
            'challenge your friends on the exact same puzzle in Multiplayer.\n\n'
            'Slide. Solve. Escape.',
            style: TextStyle(
              color: Color(0xFFC9D6F5),
              fontSize: 15,
              height: 1.45,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildDeveloperCard() {
    return _glassCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFFE259), Color(0xFFFFA400)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.code_rounded, color: Color(0xFF14204A), size: 30),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEVELOPED BY',
                  style: TextStyle(
                    color: Color(0xFF7F92C9),
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  developerName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                // BebasNeue has no Sinhala glyphs, so use the system font here.
                Text(
                  developerNameSi,
                  style: TextStyle(
                    fontFamily: null,
                    color: Color(0xFFFFC83D),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 550.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  // --------------------------------------------------------- effect buttons

  Widget _buildEffectButtons() {
    return Column(
      children: [
        const Text(
          'WEATHER EFFECTS',
          style: TextStyle(
            color: Color(0xFF9FB2E8),
            fontSize: 13,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _EffectButton(
                label: 'SNOW',
                icon: Icons.ac_unit_rounded,
                color: const Color(0xFF9BE7FF),
                active: _snow,
                onTap: () => _toggle('snow'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EffectButton(
                label: 'RAIN',
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF4DA3FF),
                active: _rain,
                onTap: () => _toggle('rain'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EffectButton(
                label: 'LIGHTNING',
                icon: Icons.bolt_rounded,
                color: const Color(0xFFFFE259),
                active: _lightning,
                onTap: () => _toggle('lightning'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _EffectButton(
                label: 'ARROWS',
                icon: Icons.north_east_rounded,
                color: const Color(0xFF00E5FF),
                active: _arrows,
                onTap: () => _toggle('arrows'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EffectButton(
                label: 'SPARKS',
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFFFFC83D),
                active: _sparks,
                onTap: () => _toggle('sparks'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EffectButton(
                label: 'METEORS',
                icon: Icons.nightlight_round,
                color: const Color(0xFFFF7A59),
                active: _meteors,
                onTap: () => _toggle('meteors'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _EffectButton(
                label: 'TEDDY',
                emoji: '🧸',
                icon: Icons.pets_rounded,
                color: const Color(0xFFFFB085),
                active: _teddy,
                onTap: () => _toggle('teddy'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EffectButton(
                label: 'HEARTS',
                emoji: '💖',
                icon: Icons.favorite_rounded,
                color: const Color(0xFFFF6B9D),
                active: _hearts,
                onTap: () => _toggle('hearts'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EffectButton(
                label: 'PARTY',
                emoji: '🎉',
                icon: Icons.celebration_rounded,
                color: const Color(0xFFB5F36B),
                active: _party,
                onTap: () => _toggle('party'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _EffectButton(
                label: 'CONFETTI',
                emoji: '🎊',
                icon: Icons.confirmation_number_rounded,
                color: const Color(0xFFFF8AE2),
                active: _confetti,
                onTap: () => _toggle('confetti'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EffectButton(
                label: 'ALL ON',
                icon: Icons.thunderstorm_rounded,
                color: const Color(0xFFB388FF),
                active: _snow && _rain && _lightning && _arrows && _sparks && _meteors && _teddy && _hearts && _party && _confetti,
                onTap: () => _allOn(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EffectButton(
                label: 'ALL OFF',
                icon: Icons.wb_sunny_rounded,
                color: const Color(0xFFFFB74D),
                active: !_snow && !_rain && !_lightning && !_arrows && !_sparks && !_meteors && !_teddy && !_hearts && !_party && !_confetti,
                onTap: () => _allOn(false),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 700.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }
}

// ======================================================================= UI

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AudioHapticHelper.playClick();
              onBack();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0E1A3D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF3D8BFF).withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'ABOUT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _EffectButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? emoji;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _EffectButton({
    required this.label,
    this.emoji,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.22)
              : const Color(0xFF0E1A3D).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? color : const Color(0xFF3A4A7A),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: active ? color.withValues(alpha: 0.45) : Colors.transparent,
              blurRadius: 14,
            ),
          ],
        ),
        child: Column(
          children: [
            emoji != null
                ? Opacity(
                    opacity: active ? 1 : 0.5,
                    child: Text(emoji!, style: const TextStyle(fontSize: 22)),
                  )
                : Icon(icon,
                    color: active ? color : const Color(0xFF6C7BA8), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF8D9CC8),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              active ? 'ON' : 'OFF',
              style: TextStyle(
                color: active ? color : const Color(0xFF5A6890),
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================== WEATHER

class _Flake {
  double x, y, r, speed, phase, drift;
  _Flake(this.x, this.y, this.r, this.speed, this.phase, this.drift);
}

class _Drop {
  double x, y, len, speed;
  _Drop(this.x, this.y, this.len, this.speed);
}

class _FloatArrow {
  double x, y, size, speed, phase;
  _FloatArrow(this.x, this.y, this.size, this.speed, this.phase);
}

class _Spark {
  double x, y, r, speed, phase, twinkle;
  _Spark(this.x, this.y, this.r, this.speed, this.phase, this.twinkle);
}

class _Meteor {
  double x, y, vx, vy, life;
  _Meteor(this.x, this.y, this.vx, this.vy, this.life);
}

class _EmojiP {
  double x, y, size, speed, phase, rot = 0;
  String e;
  _EmojiP(this.e, this.x, this.y, this.size, this.speed, this.phase);
}

class _Confetti {
  double x, y, w, h, speed, phase;
  Color c;
  _Confetti(this.x, this.y, this.w, this.h, this.speed, this.phase, this.c);
}

class _Bolt {
  final List<Offset> main;
  final List<List<Offset>> branches;
  double life; // 1 -> 0
  _Bolt(this.main, this.branches, this.life);
}

/// Holds all particle state and acts as the repaint [Listenable].
class _WeatherState extends ChangeNotifier {
  static const int flakeCount = 90;
  static const int dropCount = 130;

  final List<_Flake> flakes = [];
  final List<_Drop> drops = [];
  final List<_Bolt> bolts = [];
  final List<_FloatArrow> arrows = [];
  final List<_Spark> sparks = [];
  final List<_Meteor> meteors = [];
  double arrowAlpha = 0, sparkAlpha = 0, meteorAlpha = 0;
  double _nextMeteor = 1.0;
  final List<_EmojiP> teddies = [];
  final List<_EmojiP> heartsList = [];
  final List<_EmojiP> partyList = [];
  final List<_Confetti> confettiList = [];
  double teddyAlpha = 0, heartAlpha = 0, partyAlpha = 0, confettiAlpha = 0;

  double snowAlpha = 1, rainAlpha = 0;
  double flash = 0; // 0..1 screen flash intensity
  double _nextStrike = 1.5;
  double _clock = 0;
  bool _seeded = false;

  void seed(Random rng) {
    _seeded = false;
  }

  void _ensureSeeded(Size s, Random rng) {
    if (_seeded || s.isEmpty) return;
    _seeded = true;
    for (int i = 0; i < flakeCount; i++) {
      flakes.add(_Flake(
        rng.nextDouble() * s.width,
        rng.nextDouble() * s.height,
        1.2 + rng.nextDouble() * 3.2,
        25 + rng.nextDouble() * 55,
        rng.nextDouble() * pi * 2,
        10 + rng.nextDouble() * 22,
      ));
    }
    const heartEmojis = ['💖', '💗', '💙', '💛', '💜'];
    const partyEmojis = ['🎉', '⭐', '🔥', '🌈', '🎈', '✨', '🏆', '👑', '🎮', '🚀'];
    const confettiColors = [
      Color(0xFFFF4D6D),
      Color(0xFFFFD166),
      Color(0xFF06D6A0),
      Color(0xFF4DA3FF),
      Color(0xFFB388FF),
      Color(0xFFFF8AE2),
    ];
    for (int i = 0; i < 16; i++) {
      teddies.add(_EmojiP('🧸', rng.nextDouble() * s.width,
          rng.nextDouble() * s.height, 26 + rng.nextDouble() * 22,
          28 + rng.nextDouble() * 42, rng.nextDouble() * pi * 2));
    }
    for (int i = 0; i < 18; i++) {
      heartsList.add(_EmojiP(heartEmojis[rng.nextInt(heartEmojis.length)],
          rng.nextDouble() * s.width, rng.nextDouble() * s.height,
          18 + rng.nextDouble() * 18, 30 + rng.nextDouble() * 45,
          rng.nextDouble() * pi * 2));
    }
    for (int i = 0; i < 22; i++) {
      partyList.add(_EmojiP(partyEmojis[rng.nextInt(partyEmojis.length)],
          rng.nextDouble() * s.width, rng.nextDouble() * s.height,
          20 + rng.nextDouble() * 20, 35 + rng.nextDouble() * 55,
          rng.nextDouble() * pi * 2));
    }
    for (int i = 0; i < 70; i++) {
      confettiList.add(_Confetti(
          rng.nextDouble() * s.width, rng.nextDouble() * s.height,
          5 + rng.nextDouble() * 6, 8 + rng.nextDouble() * 8,
          60 + rng.nextDouble() * 120, rng.nextDouble() * pi * 2,
          confettiColors[rng.nextInt(confettiColors.length)]));
    }
    for (int i = 0; i < 14; i++) {
      arrows.add(_FloatArrow(
        rng.nextDouble() * s.width,
        rng.nextDouble() * s.height,
        10 + rng.nextDouble() * 16,
        18 + rng.nextDouble() * 38,
        rng.nextDouble() * pi * 2,
      ));
    }
    for (int i = 0; i < 50; i++) {
      sparks.add(_Spark(
        rng.nextDouble() * s.width,
        rng.nextDouble() * s.height,
        1 + rng.nextDouble() * 2.2,
        8 + rng.nextDouble() * 22,
        rng.nextDouble() * pi * 2,
        1.5 + rng.nextDouble() * 3,
      ));
    }
    for (int i = 0; i < dropCount; i++) {
      drops.add(_Drop(
        rng.nextDouble() * s.width,
        rng.nextDouble() * s.height,
        14 + rng.nextDouble() * 22,
        520 + rng.nextDouble() * 380,
      ));
    }
  }

  void triggerStrikeSoon() => _nextStrike = 0.25;

  void update(
    double dt,
    Size s,
    Random rng, {
    required bool snow,
    required bool rain,
    required bool lightning,
    required bool arrows,
    required bool sparks,
    required bool meteors,
    required bool teddy,
    required bool hearts,
    required bool party,
    required bool confetti,
  }) {
    _ensureSeeded(s, rng);
    _clock += dt;

    // fade layers in/out smoothly
    snowAlpha += ((snow ? 1 : 0) - snowAlpha) * min(1, dt * 4);
    rainAlpha += ((rain ? 1 : 0) - rainAlpha) * min(1, dt * 4);

    arrowAlpha += ((arrows ? 1 : 0) - arrowAlpha) * min(1, dt * 4);
    sparkAlpha += ((sparks ? 1 : 0) - sparkAlpha) * min(1, dt * 4);
    meteorAlpha += ((meteors ? 1 : 0) - meteorAlpha) * min(1, dt * 4);

    teddyAlpha += ((teddy ? 1 : 0) - teddyAlpha) * min(1, dt * 4);
    heartAlpha += ((hearts ? 1 : 0) - heartAlpha) * min(1, dt * 4);
    partyAlpha += ((party ? 1 : 0) - partyAlpha) * min(1, dt * 4);
    confettiAlpha += ((confetti ? 1 : 0) - confettiAlpha) * min(1, dt * 4);

    if (teddyAlpha > 0.01) {
      for (final t in teddies) {
        t.y += t.speed * dt; // teddies fall
        t.x += sin(_clock * 0.8 + t.phase) * 16 * dt;
        t.rot = sin(_clock * 1.3 + t.phase) * 0.5;
        if (t.y > s.height + 40) {
          t.y = -40;
          t.x = rng.nextDouble() * s.width;
        }
      }
    }
    if (heartAlpha > 0.01) {
      for (final h in heartsList) {
        h.y -= h.speed * dt; // hearts float up
        h.x += sin(_clock + h.phase) * 14 * dt;
        h.rot = sin(_clock * 1.6 + h.phase) * 0.35;
        if (h.y < -40) {
          h.y = s.height + 40;
          h.x = rng.nextDouble() * s.width;
        }
      }
    }
    if (partyAlpha > 0.01) {
      for (final p in partyList) {
        p.y += p.speed * dt;
        p.x += sin(_clock * 0.9 + p.phase) * 18 * dt;
        p.rot += dt * (0.6 + (p.phase % 1.5));
        if (p.y > s.height + 40) {
          p.y = -40;
          p.x = rng.nextDouble() * s.width;
        }
      }
    }
    if (confettiAlpha > 0.01) {
      for (final c in confettiList) {
        c.y += c.speed * dt;
        c.x += sin(_clock * 1.4 + c.phase) * 24 * dt;
        if (c.y > s.height + 20) {
          c.y = -20;
          c.x = rng.nextDouble() * s.width;
        }
      }
    }

    if (arrowAlpha > 0.01) {
      for (final a in this.arrows) {
        a.y -= a.speed * dt;
        a.x += sin(_clock * 0.7 + a.phase) * 10 * dt;
        if (a.y < -30) {
          a.y = s.height + 30;
          a.x = rng.nextDouble() * s.width;
        }
      }
    }
    if (sparkAlpha > 0.01) {
      for (final sp in this.sparks) {
        sp.y -= sp.speed * dt;
        sp.x += sin(_clock + sp.phase) * 8 * dt;
        if (sp.y < -6) {
          sp.y = s.height + 6;
          sp.x = rng.nextDouble() * s.width;
        }
      }
    }
    if (meteors) {
      _nextMeteor -= dt;
      if (_nextMeteor <= 0) {
        _nextMeteor = 0.8 + rng.nextDouble() * 2.2;
        this.meteors.add(_Meteor(
          s.width * (0.3 + rng.nextDouble() * 0.9),
          -10,
          -(260 + rng.nextDouble() * 200),
          300 + rng.nextDouble() * 220,
          1,
        ));
      }
    }
    for (final m in this.meteors) {
      m.x += m.vx * dt;
      m.y += m.vy * dt;
      m.life -= dt * 0.7;
    }
    this.meteors.removeWhere((m) => m.life <= 0 || m.y > s.height + 40);

    if (snowAlpha > 0.01) {
      for (final f in flakes) {
        f.y += f.speed * dt;
        f.x += sin(_clock * 0.9 + f.phase) * f.drift * dt;
        if (f.y > s.height + 6) {
          f.y = -6;
          f.x = rng.nextDouble() * s.width;
        }
        if (f.x < -6) f.x = s.width + 6;
        if (f.x > s.width + 6) f.x = -6;
      }
    }

    if (rainAlpha > 0.01) {
      for (final d in drops) {
        d.y += d.speed * dt;
        d.x -= d.speed * 0.18 * dt; // slanted fall
        if (d.y > s.height + d.len || d.x < -20) {
          d.y = -d.len;
          d.x = rng.nextDouble() * (s.width + 80);
        }
      }
    }

    // lightning
    if (lightning) {
      _nextStrike -= dt;
      if (_nextStrike <= 0) {
        _strike(s, rng);
        _nextStrike = 1.8 + rng.nextDouble() * 4.2;
      }
    }
    for (final b in bolts) {
      b.life -= dt * 2.6;
    }
    bolts.removeWhere((b) => b.life <= 0);
    flash = max(0, flash - dt * 3.2);

    notifyListeners();
  }

  void _strike(Size s, Random rng) {
    final startX = s.width * (0.15 + rng.nextDouble() * 0.7);
    final endY = s.height * (0.45 + rng.nextDouble() * 0.4);
    final main = <Offset>[Offset(startX, 0)];
    var x = startX, y = 0.0;
    final branches = <List<Offset>>[];
    while (y < endY) {
      y += 24 + rng.nextDouble() * 38;
      x += (rng.nextDouble() - 0.5) * 70;
      main.add(Offset(x, y));
      if (rng.nextDouble() < 0.28) {
        final br = <Offset>[Offset(x, y)];
        var bx = x, by = y;
        final dir = rng.nextBool() ? 1 : -1;
        for (int i = 0; i < 3 + rng.nextInt(3); i++) {
          bx += dir * (14 + rng.nextDouble() * 26);
          by += 14 + rng.nextDouble() * 26;
          br.add(Offset(bx, by));
        }
        branches.add(br);
      }
    }
    bolts.add(_Bolt(main, branches, 1));
    flash = 0.75 + rng.nextDouble() * 0.25;
  }
}

class _WeatherPainter extends CustomPainter {
  final _WeatherState w;
  static final Map<String, TextPainter> _cache = {};
  _WeatherPainter(this.w) : super(repaint: w);

  @override
  void paint(Canvas canvas, Size size) {
    // ---- confetti
    if (w.confettiAlpha > 0.01) {
      final p = Paint();
      for (final c in w.confettiList) {
        final flip = (sin(w._clock * 3 + c.phase)).abs();
        p.color = c.c.withValues(alpha: 0.9 * w.confettiAlpha);
        canvas.save();
        canvas.translate(c.x, c.y);
        canvas.rotate(w._clock * 1.2 + c.phase);
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: c.w, height: max(1.5, c.h * flip)),
          p,
        );
        canvas.restore();
      }
    }

    // ---- emoji layers
    void emojiLayer(List<_EmojiP> list, double alpha) {
      if (alpha <= 0.01) return;
      for (final e in list) {
        final tp = _cache.putIfAbsent(
          e.e,
          () => TextPainter(
            text: TextSpan(text: e.e, style: const TextStyle(fontSize: 32)),
            textDirection: TextDirection.ltr,
          )..layout(),
        );
        canvas.save();
        canvas.translate(e.x, e.y);
        canvas.rotate(e.rot);
        canvas.scale(e.size / 32 * alpha);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }

    emojiLayer(w.partyList, w.partyAlpha);
    emojiLayer(w.teddies, w.teddyAlpha);
    emojiLayer(w.heartsList, w.heartAlpha);

    // ---- floating glowing arrows (game theme)
    if (w.arrowAlpha > 0.01) {
      final fill = Paint();
      final glow = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      for (final a in w.arrows) {
        final c = const Color(0xFF00E5FF).withValues(alpha: 0.35 * w.arrowAlpha);
        fill.color = c;
        glow.color = c.withValues(alpha: 0.25 * w.arrowAlpha);
        final path = Path()
          ..moveTo(a.x, a.y - a.size)
          ..lineTo(a.x + a.size * 0.6, a.y)
          ..lineTo(a.x + a.size * 0.2, a.y)
          ..lineTo(a.x + a.size * 0.2, a.y + a.size * 0.9)
          ..lineTo(a.x - a.size * 0.2, a.y + a.size * 0.9)
          ..lineTo(a.x - a.size * 0.2, a.y)
          ..lineTo(a.x - a.size * 0.6, a.y)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
      }
    }

    // ---- golden sparks
    if (w.sparkAlpha > 0.01) {
      final p = Paint();
      final g = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      for (final sp in w.sparks) {
        final tw = 0.5 + 0.5 * sin(w._clock * sp.twinkle + sp.phase);
        p.color = const Color(0xFFFFE08A).withValues(alpha: tw * w.sparkAlpha);
        g.color = const Color(0xFFFFA400).withValues(alpha: 0.5 * tw * w.sparkAlpha);
        canvas.drawCircle(Offset(sp.x, sp.y), sp.r * 2.4, g);
        canvas.drawCircle(Offset(sp.x, sp.y), sp.r, p);
      }
    }

    // ---- meteors
    if (w.meteorAlpha > 0.01) {
      for (final m in w.meteors) {
        final tail = Offset(m.x - m.vx * 0.18, m.y - m.vy * 0.18);
        final head = Offset(m.x, m.y);
        final shader = LinearGradient(
          colors: [
            const Color(0x00FF7A59),
            const Color(0xFFFFD6A5).withValues(alpha: m.life.clamp(0.0, 1.0)),
          ],
        ).createShader(Rect.fromPoints(tail, head));
        canvas.drawLine(
          tail,
          head,
          Paint()
            ..shader = shader
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(head, 2.6,
            Paint()..color = Colors.white.withValues(alpha: m.life.clamp(0.0, 1.0)));
      }
    }

    // ---- rain
    if (w.rainAlpha > 0.01) {
      final p = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.4
        ..color = const Color(0xFF9CC8FF).withValues(alpha: 0.5 * w.rainAlpha);
      for (final d in w.drops) {
        canvas.drawLine(
          Offset(d.x, d.y),
          Offset(d.x + d.len * 0.18, d.y - d.len),
          p,
        );
      }
    }

    // ---- snow
    if (w.snowAlpha > 0.01) {
      final glow = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      final core = Paint();
      for (final f in w.flakes) {
        final a = (0.55 + (f.r / 4.4) * 0.45) * w.snowAlpha;
        glow.color = Colors.white.withValues(alpha: a * 0.45);
        core.color = Colors.white.withValues(alpha: a);
        canvas.drawCircle(Offset(f.x, f.y), f.r * 1.6, glow);
        canvas.drawCircle(Offset(f.x, f.y), f.r, core);
      }
    }

    // ---- lightning bolts
    for (final b in w.bolts) {
      final a = b.life.clamp(0.0, 1.0);
      final flicker = (sin(b.life * 40) > -0.3) ? 1.0 : 0.45;
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 9
        ..color = const Color(0xFF7FB2FF).withValues(alpha: 0.55 * a * flicker)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      final corePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.6
        ..color = Colors.white.withValues(alpha: a * flicker);

      Path toPath(List<Offset> pts) {
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final o in pts.skip(1)) {
          path.lineTo(o.dx, o.dy);
        }
        return path;
      }

      final mainPath = toPath(b.main);
      canvas.drawPath(mainPath, glowPaint);
      canvas.drawPath(mainPath, corePaint);
      for (final br in b.branches) {
        final bp = toPath(br);
        canvas.drawPath(bp, glowPaint..strokeWidth = 5);
        canvas.drawPath(bp, corePaint..strokeWidth = 1.4);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter old) => false;
}

/// Full-screen white/blue flash when lightning strikes.
class _FlashPainter extends CustomPainter {
  final _WeatherState w;
  _FlashPainter(this.w) : super(repaint: w);

  @override
  void paint(Canvas canvas, Size size) {
    if (w.flash <= 0.01) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = const Color(0xFFBFD8FF).withValues(alpha: 0.28 * w.flash),
    );
  }

  @override
  bool shouldRepaint(covariant _FlashPainter old) => false;
}
