import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Один ролик питомца из `pet.json`.
class PetClip {
  final String file;
  final String poster;
  final int frameCount;
  final int frameMs;

  /// Кадры, где питомец почти в базовой позе: здесь можно переключить
  /// ролик без скачка.
  final Set<int> cuts;

  /// Движение головы по кадрам: (a, b, tx, ty) в долях кадра.
  /// Точка кадра 0 переходит в кадр i так:
  /// `x' = a*x - b*y + tx`, `y' = b*x + a*y + ty`.
  final List<List<double>>? track;

  const PetClip({
    required this.file,
    required this.poster,
    required this.frameCount,
    required this.frameMs,
    required this.cuts,
    this.track,
  });

  factory PetClip.fromJson(Map<String, dynamic> json) {
    final track = json['track'] as List<dynamic>?;
    return PetClip(
      file: json['file'] as String,
      poster: json['poster'] as String,
      frameCount: json['frameCount'] as int,
      frameMs: json['frameMs'] as int,
      cuts: {for (final c in json['cuts'] as List<dynamic>) c as int},
      track: track
          ?.map((row) => [
                for (final v in row as List<dynamic>) (v as num).toDouble(),
              ])
          .toList(),
    );
  }

  /// Преобразование головы в кадре [frame]; без трекинга — тождественное.
  List<double> headAt(int frame) {
    final t = track;
    if (t == null || t.isEmpty) return const [1, 0, 0, 0];
    return t[frame.clamp(0, t.length - 1)];
  }
}

/// Описание питомца: `assets/pets/<pet>/pet.json`.
class PetInfo {
  final Map<String, PetClip> clips;

  /// Рамка головы на кадре 0: x, y, ширина, высота в долях кадра.
  final Rect? head;

  const PetInfo({required this.clips, this.head});

  static Future<PetInfo> load(AssetBundle bundle, String basePath) async {
    final raw = await bundle.loadString('$basePath/pet.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final clips = (json['clips'] as Map<String, dynamic>).map(
      (name, clip) =>
          MapEntry(name, PetClip.fromJson(clip as Map<String, dynamic>)),
    );
    final h = json['head'] as List<dynamic>?;
    return PetInfo(
      clips: clips,
      head: h == null || h.length != 4
          ? null
          : Rect.fromLTWH(
              (h[0] as num).toDouble(),
              (h[1] as num).toDouble(),
              (h[2] as num).toDouble(),
              (h[3] as num).toDouble(),
            ),
    );
  }
}

/// Аксессуар поверх питомца (PNG с прозрачным фоном).
///
/// Все координаты — доли кадра 512×512 на кадре 0 (`idle_poster.png`):
/// - [anchor] — точка крепления на питомце;
/// - [pivot] — та же точка внутри картинки аксессуара
///   (0.5, 1 — середина нижнего края, подходит для шапок);
/// - [width] — ширина аксессуара.
/// С [followHead] аксессуар повторяет движение головы.
class Accessory {
  final String asset;
  final Offset anchor;
  final Offset pivot;
  final double width;
  final double rotationDeg;
  final bool followHead;

  const Accessory({
    required this.asset,
    required this.anchor,
    this.pivot = const Offset(0.5, 1),
    required this.width,
    this.rotationDeg = 0,
    this.followHead = true,
  });
}

/// Какой ролик играть. Переключение — в ближайшей точке склейки,
/// с `immediate: true` — сразу (возможен небольшой скачок).
class PetController extends ChangeNotifier {
  PetController({this.idleState = 'idle'}) : _loop = idleState;

  final String idleState;
  String _loop;
  String? _once;
  bool _immediate = false;

  /// Ролик, который крутится, когда разовый закончился.
  String get loopState => _loop;

  /// Какой ролик должен играть сейчас.
  String get wanted => _once ?? _loop;

  bool get immediate => _immediate;

  /// Крутить [state], пока не попросят другое.
  void loop(String state, {bool immediate = false}) {
    if (_loop == state && _once == null) return;
    _loop = state;
    _once = null;
    _immediate = immediate;
    notifyListeners();
  }

  /// Проиграть [state] один раз и вернуться к [loopState].
  void playOnce(String state, {bool immediate = false}) {
    _once = state;
    _immediate = immediate;
    notifyListeners();
  }

  void _finishOnce() {
    if (_once == null) return;
    _once = null;
    _immediate = false;
    notifyListeners();
  }
}

/// Анимированный питомец из `assets/pets/<pet>/`: ролики WebP, склейка
/// в точках `cuts`, аксессуары по трекингу головы. Пакеты не нужны.
///
/// Кадры декодируются по одному, в памяти лежит только текущий —
/// 3 ролика по 92 кадра 512×512 целиком заняли бы ~300 МБ.
class PetView extends StatefulWidget {
  final String basePath;
  final PetController controller;
  final List<Accessory> accessories;
  final VoidCallback? onTapHead;
  final VoidCallback? onTapBody;

  /// Что показать, пока грузится `pet.json` или если его нет.
  final Widget? placeholder;

  const PetView({
    super.key,
    required this.basePath,
    required this.controller,
    this.accessories = const [],
    this.onTapHead,
    this.onTapBody,
    this.placeholder,
  });

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final Map<String, ByteData> _bytes = {};

  PetInfo? _info;
  bool _failed = false;

  String? _state;
  ui.Codec? _codec;
  ui.Image? _image;
  int _frame = 0;
  Duration _last = Duration.zero;
  bool _decoding = false;
  int _generation = 0;

  bool get _calm => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onWanted);
    _load();
  }

  @override
  void didUpdateWidget(covariant PetView old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onWanted);
      widget.controller.addListener(_onWanted);
    }
    if (old.basePath != widget.basePath) _load();
  }

  @override
  void dispose() {
    _generation++;
    widget.controller.removeListener(_onWanted);
    _ticker.dispose();
    _codec?.dispose();
    _image?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final gen = ++_generation;
    _ticker.stop();
    _bytes.clear();
    _codec?.dispose();
    _codec = null;
    _image?.dispose();
    _image = null;
    _state = null;
    try {
      final info = await PetInfo.load(rootBundle, widget.basePath);
      if (!mounted || gen != _generation) return;
      setState(() {
        _info = info;
        _failed = false;
      });
      await _switchTo(widget.controller.wanted);
    } catch (e) {
      debugPrint('PetView: не загрузился ${widget.basePath}: $e');
      if (mounted && gen == _generation) setState(() => _failed = true);
    }
  }

  PetClip? _clip(String? state) => state == null ? null : _info?.clips[state];

  void _onWanted() {
    final c = widget.controller;
    if (c.wanted == _state) return;
    if (c.immediate || _codec == null || _calm) _switchTo(c.wanted);
    // Иначе переключимся в ближайшей точке склейки (_onTick).
  }

  Future<void> _switchTo(String state) async {
    final clip = _clip(state) ?? _clip(widget.controller.idleState);
    if (clip == null) return;
    final name = _clip(state) != null ? state : widget.controller.idleState;
    final gen = _generation;
    _state = name;
    _frame = 0;
    if (_calm) {
      // «Убрать анимации» в системе — только постер.
      _ticker.stop();
      _codec?.dispose();
      _codec = null;
      if (mounted) setState(() {});
      return;
    }
    try {
      final data = _bytes[name] ??=
          await rootBundle.load('${widget.basePath}/${clip.file}');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      ));
      if (!mounted || gen != _generation || _state != name) {
        codec.dispose();
        return;
      }
      _codec?.dispose();
      _codec = codec;
      await _decodeNext();
      _last = Duration.zero;
      if (!_ticker.isActive) _ticker.start();
    } catch (e) {
      debugPrint('PetView: ролик $name не проигрывается: $e');
    }
  }

  Future<void> _decodeNext() async {
    final codec = _codec;
    if (codec == null) return;
    _decoding = true;
    try {
      final frame = await codec.getNextFrame();
      if (!mounted || codec != _codec) {
        frame.image.dispose();
        return;
      }
      final old = _image;
      setState(() => _image = frame.image);
      old?.dispose();
    } finally {
      _decoding = false;
    }
  }

  void _onTick(Duration elapsed) {
    final clip = _clip(_state);
    if (clip == null || _decoding || _codec == null) return;
    if (elapsed - _last < Duration(milliseconds: clip.frameMs)) return;
    _last = elapsed;

    final next = _frame + 1;
    final wrapped = next >= clip.frameCount;
    final c = widget.controller;

    // Разовый ролик доиграл — назад к циклу.
    if (wrapped && _state != c.loopState && _state == c.wanted) {
      c._finishOnce();
      return; // _onWanted уже переключил или переключит на склейке
    }
    final nextFrame = wrapped ? 0 : next;
    if (c.wanted != _state && (wrapped || clip.cuts.contains(nextFrame))) {
      _switchTo(c.wanted);
      return;
    }
    _frame = nextFrame;
    _decodeNext();
  }

  Offset _mapHead(Offset p, List<double> m) =>
      Offset(m[0] * p.dx - m[1] * p.dy + m[2], m[1] * p.dx + m[0] * p.dy + m[3]);

  void _onTap(Offset local, double side) {
    final head = _info?.head;
    final clip = _clip(_state);
    if (head != null && clip != null && widget.onTapHead != null) {
      final m = clip.headAt(_frame);
      final c = _mapHead(head.center, m);
      final s = math.sqrt(m[0] * m[0] + m[1] * m[1]);
      final rect = Rect.fromCenter(
        center: Offset(c.dx * side, c.dy * side),
        width: head.width * side * s,
        height: head.height * side * s,
      );
      if (rect.contains(local)) {
        widget.onTapHead!();
        return;
      }
    }
    widget.onTapBody?.call();
  }

  @override
  Widget build(BuildContext context) {
    final clip = _clip(_state);
    if (_failed || _info == null || clip == null) {
      return widget.placeholder ?? const SizedBox.expand();
    }
    return LayoutBuilder(builder: (context, box) {
      final side = math.min(box.maxWidth, box.maxHeight);
      final m = clip.headAt(_frame);
      final image = _image;
      final body = image != null && _codec != null
          ? RawImage(image: image, width: side, height: side, fit: BoxFit.contain)
          : Image.asset(
              '${widget.basePath}/${clip.poster}',
              width: side,
              height: side,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: widget.onTapHead == null && widget.onTapBody == null
            ? null
            : (d) => _onTap(d.localPosition, side),
        child: SizedBox(
          width: side,
          height: side,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              body,
              for (final a in widget.accessories) _accessory(a, m, side),
            ],
          ),
        ),
      );
    });
  }

  Widget _accessory(Accessory a, List<double> m, double side) {
    final t = a.followHead ? m : const [1.0, 0.0, 0.0, 0.0];
    final p = _mapHead(a.anchor, t);
    final scale = math.sqrt(t[0] * t[0] + t[1] * t[1]);
    final angle = math.atan2(t[1], t[0]) + a.rotationDeg * math.pi / 180;
    return Positioned(
      left: p.dx * side,
      top: p.dy * side,
      child: FractionalTranslation(
        translation: Offset(-a.pivot.dx, -a.pivot.dy),
        child: Transform.rotate(
          angle: angle,
          alignment: Alignment(a.pivot.dx * 2 - 1, a.pivot.dy * 2 - 1),
          child: Image.asset(a.asset, width: a.width * side * scale),
        ),
      ),
    );
  }
}
