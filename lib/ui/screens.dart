import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/app_strings.dart';
import '../core/game_models.dart';
import '../core/match_store.dart';
import '../core/score_engine.dart';
import 'app_motion.dart';
import 'app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});

  final MatchStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController entrance;
  bool entranceStarted = false;

  @override
  void initState() {
    super.initState();
    entrance = AnimationController(vsync: this, duration: AppMotion.large);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (entranceStarted) return;
    entranceStarted = true;
    if (AppMotion.disabled(context)) {
      entrance.value = 1;
    } else {
      entrance.forward();
    }
  }

  @override
  void dispose() {
    entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(widget.store.language);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final spacious = constraints.maxHeight >= 720;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          MotionReveal(
                            animation: _interval(0, 0.45),
                            child: _Brand(title: s.appName),
                          ),
                          SegmentedButton<AppLanguage>(
                            style: ButtonStyle(
                              animationDuration: AppMotion.duration(
                                context,
                                AppMotion.fast,
                              ),
                            ),
                            segments: const [
                              ButtonSegment(
                                value: AppLanguage.ru,
                                label: Text('Кацапский'),
                              ),
                              ButtonSegment(
                                value: AppLanguage.uk,
                                label: Text('Файна мова'),
                              ),
                            ],
                            selected: {widget.store.language},
                            onSelectionChanged: (value) {
                              widget.store.setLanguage(value.first);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: spacious ? 110 : 36),
                      MotionReveal(
                        animation: _interval(0.12, 0.65),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.t(
                                'Счёт без рекламы.\nТолько ваша игра.',
                                'Рахунок без реклами.\nТільки ваша гра.',
                              ),
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              s.t(
                                'Офлайн, с болтами, висячкой и вашими объявлениями.',
                                'Офлайн, з болтами, висячкою та вашими оголошеннями.',
                              ),
                              style: const TextStyle(
                                color: AppPalette.muted,
                                fontSize: 17,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      MotionReveal(
                        animation: _interval(0.3, 0.82),
                        child: PressableScale(
                          child: FilledButton.icon(
                            onPressed: () => _open(
                              context,
                              SetupScreen(store: widget.store),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(s.newMatch),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      MotionReveal(
                        animation: _interval(0.4, 0.9),
                        child: PressableScale(
                          enabled: widget.store.hasActiveMatch,
                          child: OutlinedButton.icon(
                            onPressed: widget.store.hasActiveMatch
                                ? () => _open(
                                      context,
                                      MatchScreen(store: widget.store),
                                    )
                                : null,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(s.continueMatch),
                          ),
                        ),
                      ),
                      SizedBox(height: spacious ? 80 : 32),
                      MotionReveal(
                        animation: _interval(0.55, 1),
                        child: const _PrivacyPill(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(appPageRoute(context, screen));
  }

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
        parent: entrance,
        curve: Interval(begin, end, curve: AppMotion.enter),
      );
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.store});
  final MatchStore store;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  MatchMode mode = MatchMode.teams;
  TiePolicy tiePolicy = TiePolicy.carry;
  int target = 1001;
  int dealerSide = 0;
  bool starting = false;
  final names = List.generate(3, (_) => TextEditingController());
  late final AnimationController entrance;
  bool entranceStarted = false;

  @override
  void initState() {
    super.initState();
    entrance = AnimationController(vsync: this, duration: AppMotion.large);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (entranceStarted) return;
    entranceStarted = true;
    if (AppMotion.disabled(context)) {
      entrance.value = 1;
    } else {
      entrance.forward();
    }
  }

  @override
  void dispose() {
    entrance.dispose();
    for (final controller in names) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(widget.store.language);
    final defaults = widget.store.language == AppLanguage.ru
        ? ['Мы', 'Они', 'Третий']
        : ['Ми', 'Вони', 'Третій'];

    return Scaffold(
      appBar: AppBar(title: Text(s.newMatch)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              MotionReveal(
                animation: _interval(0, 0.38),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(s.chooseMode),
                    Wrap(
                      spacing: 10,
                      children: MatchMode.values.map((item) {
                        return PressableScale(
                          child: ChoiceChip(
                            chipAnimationStyle: AppMotion.chipStyle(context),
                            label: Text(item.label),
                            selected: mode == item,
                            onSelected: (_) {
                              setState(() {
                                mode = item;
                                if (dealerSide >= mode.sides) dealerSide = 0;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              MotionReveal(
                animation: _interval(0.08, 0.48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(s.target),
                    PressableScale(
                      child: SegmentedButton<int>(
                        style: ButtonStyle(
                          animationDuration: AppMotion.duration(
                            context,
                            AppMotion.fast,
                          ),
                        ),
                        segments: const [
                          ButtonSegment(value: 501, label: Text('501')),
                          ButtonSegment(value: 1001, label: Text('1001')),
                          ButtonSegment(value: 1501, label: Text('1501')),
                        ],
                        selected: {target},
                        onSelectionChanged: (value) =>
                            setState(() => target = value.first),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              MotionReveal(
                animation: _interval(0.16, 0.58),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(s.teams),
                    for (var i = 0; i < 2; i++) _nameField(i, defaults),
                    AnimatedSwitcher(
                      key: const ValueKey('participant_count_switcher'),
                      duration: AppMotion.duration(context, AppMotion.standard),
                      switchInCurve: AppMotion.enter,
                      switchOutCurve: AppMotion.exit,
                      layoutBuilder: _verticalSwitcherLayout,
                      transitionBuilder: _sizeFadeTransition,
                      child: mode.sides == 3
                          ? KeyedSubtree(
                              key: const ValueKey('third_participant'),
                              child: _nameField(2, defaults),
                            )
                          : const SizedBox(
                              key: ValueKey('no_third_participant'),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              MotionReveal(
                animation: _interval(0.25, 0.68),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(s.firstDealer),
                    AnimatedSwitcher(
                      key: const ValueKey('dealer_count_switcher'),
                      duration: AppMotion.duration(context, AppMotion.standard),
                      switchInCurve: AppMotion.enter,
                      switchOutCurve: AppMotion.exit,
                      child: Wrap(
                        key: ValueKey('dealer_choices_${mode.sides}'),
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < mode.sides; i++)
                            PressableScale(
                              child: ChoiceChip(
                                key: ValueKey('initial_dealer_$i'),
                                chipAnimationStyle:
                                    AppMotion.chipStyle(context),
                                label: Text(
                                  names[i].text.trim().isEmpty
                                      ? defaults[i]
                                      : names[i].text.trim(),
                                ),
                                selected: dealerSide == i,
                                onSelected: (_) =>
                                    setState(() => dealerSide = i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              MotionReveal(
                animation: _interval(0.34, 0.8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(s.hanging),
                    PressableScale(
                      child: SegmentedButton<TiePolicy>(
                        style: ButtonStyle(
                          animationDuration: AppMotion.duration(
                            context,
                            AppMotion.fast,
                          ),
                        ),
                        segments: [
                          ButtonSegment(
                            value: TiePolicy.carry,
                            label: Text(s.t('Перенос', 'Перенесення')),
                          ),
                          ButtonSegment(
                            value: TiePolicy.split,
                            label: Text(s.t('Разделить', 'Розділити')),
                          ),
                        ],
                        selected: {tiePolicy},
                        onSelectionChanged: (value) {
                          setState(() => tiePolicy = value.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              MotionReveal(
                animation: _interval(0.48, 1),
                child: AnimatedOpacity(
                  opacity: starting ? 0.68 : 1,
                  duration: AppMotion.duration(context, AppMotion.fast),
                  child: PressableScale(
                    enabled: !starting,
                    child: FilledButton(
                      onPressed:
                          starting ? null : () => _start(context, defaults),
                      child: Text(s.start),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nameField(int index, List<String> defaults) {
    return Padding(
      key: ValueKey('participant_field_$index'),
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: names[index],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.person_outline_rounded),
          hintText: defaults[index],
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context, List<String> defaults) async {
    if (starting) return;
    setState(() => starting = true);
    final finalNames = [
      for (var i = 0; i < mode.sides; i++)
        names[i].text.trim().isEmpty ? defaults[i] : names[i].text.trim(),
    ];
    await widget.store.createMatch(
      mode: mode,
      rules: MatchRules(targetScore: target, tiePolicy: tiePolicy),
      names: finalNames,
      dealerSide: dealerSide,
    );
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      appPageRoute(context, MatchScreen(store: widget.store)),
    );
  }

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
        parent: entrance,
        curve: Interval(begin, end, curve: AppMotion.enter),
      );
}

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key, required this.store});
  final MatchStore store;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _boltFlight;
  late final List<GlobalKey> _cardAnchors;
  late final List<GlobalKey<_BoltIndicatorState>> _boltAnchors;
  late final List<int> _hiddenBolts;
  final Queue<_BoltVisualEvent> _boltQueue = Queue<_BoltVisualEvent>();
  OverlayEntry? _boltOverlay;
  _BoltVisualEvent? _currentBolt;
  bool _flightActive = false;
  bool _currentBoltCancelled = false;

  MatchStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    final sideCount = store.activeMatch?.sides.length ?? 0;
    _cardAnchors = List.generate(
      sideCount,
      (index) => GlobalKey(debugLabel: 'score_card_$index'),
    );
    _boltAnchors = List.generate(
      sideCount,
      (index) => GlobalKey<_BoltIndicatorState>(
        debugLabel: 'bolt_indicator_$index',
      ),
    );
    _hiddenBolts = List.filled(sideCount, 0);
    _boltFlight = AnimationController(
      vsync: this,
      duration: AppMotion.boltFlight,
    );
    store.addListener(_cancelInvalidBoltEvents);
  }

  @override
  void dispose() {
    store.removeListener(_cancelInvalidBoltEvents);
    _currentBoltCancelled = true;
    _boltQueue.clear();
    _removeBoltOverlay();
    _boltFlight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final match = store.activeMatch;
        final s = AppStrings(store.language);
        if (match == null) {
          return Scaffold(body: Center(child: Text(s.newMatch)));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('${match.mode.label} · ${match.rules.targetScore}'),
            actions: [
              IconButton(
                tooltip: s.history,
                onPressed: () => Navigator.of(context).push(
                  appPageRoute(context, HistoryScreen(store: store)),
                ),
                icon: const Icon(Icons.receipt_long_rounded),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                children: [
                  AnimatedSwitcher(
                    duration: AppMotion.duration(context, AppMotion.standard),
                    switchInCurve: AppMotion.enter,
                    switchOutCurve: AppMotion.exit,
                    layoutBuilder: _verticalSwitcherLayout,
                    transitionBuilder: _sizeFadeTransition,
                    child: match.carriedPool > 0
                        ? _CarryBanner(
                            key: ValueKey('carry_${match.carriedPool}'),
                            points: match.carriedPool,
                            strings: s,
                          )
                        : const SizedBox(key: ValueKey('no_carry')),
                  ),
                  for (var i = 0; i < match.sides.length; i++) ...[
                    _ScoreCard(
                      cardKey: _cardAnchors[i],
                      boltIndicatorKey: _boltAnchors[i],
                      animationKey: '$i',
                      side: match.sides[i],
                      displayedBolts: math.max(
                        0,
                        match.sides[i].bolts - _hiddenBolts[i],
                      ),
                      boltThreshold: match.rules.boltThreshold,
                      boltPenalty: match.rules.boltPenalty,
                      isDealer: match.dealerSide == i,
                      isWinner: match.winnerSide == i,
                      strings: s,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotion.standard),
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: match.winnerSide == null
                ? PressableScale(
                    key: const ValueKey('add_round_action'),
                    child: FloatingActionButton.extended(
                      onPressed: () => _openRoundSheet(context),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(s.addRound),
                    ),
                  )
                : PressableScale(
                    key: const ValueKey('winner_action'),
                    child: FloatingActionButton.extended(
                      backgroundColor: AppPalette.gold,
                      foregroundColor: Colors.black,
                      onPressed: () => _showWinner(context, match, s),
                      icon: const Icon(Icons.emoji_events_rounded),
                      label: Text(s.winner),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _openRoundSheet(BuildContext context) async {
    final result = await showModalBottomSheet<RoundResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppPalette.surface,
      sheetAnimationStyle: AppMotion.animationStyle(
        context,
        AppMotion.standard,
      ),
      builder: (_) => AddRoundSheet(store: store),
    );
    if (!mounted || result == null || !result.entry.boltAdded) return;
    _enqueueBolt(
      _BoltVisualEvent(
        side: result.entry.contractSide,
        boltNumber: result.state.sides[result.entry.contractSide].bolts,
      ),
    );
  }

  void _enqueueBolt(_BoltVisualEvent event) {
    if (event.side < 0 || event.side >= _hiddenBolts.length) return;
    setState(() => _hiddenBolts[event.side]++);
    _boltQueue.add(event);
    if (!_flightActive) unawaited(_playBoltQueue());
  }

  Future<void> _playBoltQueue() async {
    if (_flightActive) return;
    _flightActive = true;
    while (mounted && _boltQueue.isNotEmpty) {
      final event = _boltQueue.removeFirst();
      _currentBolt = event;
      _currentBoltCancelled = false;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) break;

      final completed = await _playBolt(event);
      if (!mounted) break;
      setState(() {
        _hiddenBolts[event.side] = math.max(
          0,
          _hiddenBolts[event.side] - 1,
        );
      });
      if (completed && _eventIsCurrent(event)) {
        final threshold =
            store.activeMatch?.rules.boltThreshold ?? event.boltNumber + 1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _boltAnchors[event.side].currentState?.pulse(
                  penalty: event.boltNumber >= threshold,
                );
          }
        });
      }
      _currentBolt = null;
    }
    _currentBolt = null;
    _flightActive = false;
  }

  Future<bool> _playBolt(_BoltVisualEvent event) async {
    final geometry = _resolveBoltGeometry(event.side);
    if (geometry == null) return false;
    final overlay = Overlay.of(context, rootOverlay: true);

    if (AppMotion.disabled(context)) {
      _boltOverlay = OverlayEntry(
        builder: (_) => _ReducedBoltAppearance(
          eventKey: ValueKey('flying_bolt_${event.side}'),
          center: geometry.end,
        ),
      );
      overlay.insert(_boltOverlay!);
      await Future<void>.delayed(AppMotion.reducedMotionHold);
      _removeBoltOverlay();
      return !_currentBoltCancelled && _eventIsCurrent(event);
    }

    _boltOverlay = OverlayEntry(
      builder: (_) => _BoltFlightOverlay(
        eventKey: ValueKey('flying_bolt_${event.side}'),
        animation: _boltFlight,
        geometry: geometry,
      ),
    );
    overlay.insert(_boltOverlay!);
    var completed = false;
    try {
      await _boltFlight.forward(from: 0).orCancel;
      completed = true;
    } on TickerCanceled {
      completed = false;
    } finally {
      _removeBoltOverlay();
    }
    return completed && !_currentBoltCancelled && _eventIsCurrent(event);
  }

  _BoltFlightGeometry? _resolveBoltGeometry(int side) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayRender = overlay.context.findRenderObject();
    if (overlayRender is! RenderBox || !overlayRender.hasSize) return null;

    final cardRender = _cardAnchors[side].currentContext?.findRenderObject();
    final targetRender =
        _boltAnchors[side].currentState?.landingContext?.findRenderObject() ??
            _boltAnchors[side].currentContext?.findRenderObject();

    Offset? inOverlay(RenderObject? render, Offset local) {
      if (render is! RenderBox || !render.hasSize) return null;
      return overlayRender.globalToLocal(render.localToGlobal(local));
    }

    final cardBox =
        cardRender is RenderBox && cardRender.hasSize ? cardRender : null;
    final targetBox =
        targetRender is RenderBox && targetRender.hasSize ? targetRender : null;
    final fallbackEnd = cardBox == null
        ? Offset(
            overlayRender.size.width * 0.5,
            overlayRender.size.height * 0.28,
          )
        : inOverlay(
            cardBox,
            Offset(cardBox.size.width * 0.2, cardBox.size.height * 0.84),
          )!;
    final end = targetBox == null
        ? fallbackEnd
        : inOverlay(targetBox, targetBox.size.center(Offset.zero))!;
    final start = cardBox == null
        ? end - Offset(0, overlayRender.size.height * 0.12)
        : inOverlay(
            cardBox,
            Offset(cardBox.size.width * 0.5, cardBox.size.height * 0.3),
          )!;
    final distance = (end - start).distance;
    final arcHeight = math.max(
      overlayRender.size.shortestSide * 0.1,
      distance * 0.22,
    );
    final control = Offset(
      (start.dx + end.dx) / 2,
      math.min(start.dy, end.dy) - arcHeight,
    );
    return _BoltFlightGeometry(start: start, control: control, end: end);
  }

  bool _eventIsCurrent(_BoltVisualEvent event) {
    final match = store.activeMatch;
    return match != null &&
        event.side < match.sides.length &&
        match.sides[event.side].bolts >= event.boltNumber;
  }

  void _cancelInvalidBoltEvents() {
    var queueChanged = false;
    _boltQueue.removeWhere((event) {
      final invalid = !_eventIsCurrent(event);
      if (invalid) {
        _hiddenBolts[event.side] = math.max(
          0,
          _hiddenBolts[event.side] - 1,
        );
        queueChanged = true;
      }
      return invalid;
    });

    final current = _currentBolt;
    if (current != null && !_eventIsCurrent(current)) {
      _currentBoltCancelled = true;
      _boltFlight.stop(canceled: true);
      _removeBoltOverlay();
    }
    if (queueChanged && mounted) setState(() {});
  }

  void _removeBoltOverlay() {
    final entry = _boltOverlay;
    _boltOverlay = null;
    entry?.remove();
  }

  Future<void> _showWinner(
    BuildContext context,
    MatchState match,
    AppStrings s,
  ) async {
    await showMotionDialog<void>(
      context: context,
      builder: (dialogContext) => _WinnerDialog(
        store: store,
        match: match,
        strings: s,
      ),
    );
  }
}

class _BoltVisualEvent {
  const _BoltVisualEvent({required this.side, required this.boltNumber});

  final int side;
  final int boltNumber;
}

class _BoltFlightGeometry {
  const _BoltFlightGeometry({
    required this.start,
    required this.control,
    required this.end,
  });

  final Offset start;
  final Offset control;
  final Offset end;

  Offset position(double progress) {
    final inverse = 1 - progress;
    return start * (inverse * inverse) +
        control * (2 * inverse * progress) +
        end * (progress * progress);
  }
}

class _BoltFlightOverlay extends StatelessWidget {
  const _BoltFlightOverlay({
    required this.eventKey,
    required this.animation,
    required this.geometry,
  });

  final Key eventKey;
  final Animation<double> animation;
  final _BoltFlightGeometry geometry;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final time = animation.value;
          final arrival = const Interval(
            0,
            0.2,
            curve: AppMotion.emphasizedEnter,
          ).transform(time);
          final settle = const Interval(
            0.2,
            0.34,
            curve: AppMotion.enter,
          ).transform(time);
          final flight = const Interval(
            0.34,
            0.9,
            curve: Curves.easeInOutCubic,
          ).transform(time);
          final fade = 1 - const Interval(0.92, 1).transform(time);
          final center = geometry.position(flight);
          final size = 92 + (21 - 92) * flight;
          final appearScale =
              time < 0.2 ? 0.42 + 0.66 * arrival : 1.08 + (1 - 1.08) * settle;
          final rotation = -0.08 + 0.22 * flight;
          final shadowOpacity = (0.38 * (1 - flight)).clamp(0.0, 1.0);

          return Stack(
            children: [
              Positioned(
                left: center.dx - size / 2,
                top: center.dy - size / 2,
                child: Transform.rotate(
                  angle: rotation,
                  child: Transform.scale(
                    scale: appearScale,
                    child: Opacity(
                      opacity: fade,
                      child: SizedBox(
                        key: eventKey,
                        width: size,
                        height: size,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: size * 0.62,
                              height: size * 0.62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: shadowOpacity,
                                    ),
                                    blurRadius: 18 * (1 - flight),
                                    spreadRadius: 3 * (1 - flight),
                                  ),
                                ],
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/icons/bolt-color-icon.svg',
                              width: size,
                              height: size,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReducedBoltAppearance extends StatelessWidget {
  const _ReducedBoltAppearance({
    required this.eventKey,
    required this.center,
  });

  final Key eventKey;
  final Offset center;

  @override
  Widget build(BuildContext context) {
    const size = 30.0;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: center.dx - size / 2,
            top: center.dy - size / 2,
            child: SizedBox(
              key: eventKey,
              width: size,
              height: size,
              child: SvgPicture.asset('assets/icons/bolt-color-icon.svg'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WinnerDialog extends StatefulWidget {
  const _WinnerDialog({
    required this.store,
    required this.match,
    required this.strings,
  });

  final MatchStore store;
  final MatchState match;
  final AppStrings strings;

  @override
  State<_WinnerDialog> createState() => _WinnerDialogState();
}

class _WinnerDialogState extends State<_WinnerDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController celebration;
  bool started = false;
  bool finishing = false;

  @override
  void initState() {
    super.initState();
    celebration = AnimationController(
      vsync: this,
      duration: AppMotion.celebration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    if (AppMotion.disabled(context)) {
      celebration.value = 1;
    } else {
      celebration.forward();
    }
  }

  @override
  void dispose() {
    celebration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winnerIndex = widget.match.winnerSide!;
    final winner = widget.match.sides[winnerIndex];
    final lastRound =
        widget.match.rounds.isEmpty ? null : widget.match.rounds.last;
    final previousScore = lastRound == null
        ? winner.score
        : winner.score - lastRound.deltas[winnerIndex];
    return Dialog(
      key: const ValueKey('winner_dialog'),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: _CelebrationBackdrop(animation: celebration),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  key: const ValueKey('winner_confetti'),
                  painter: _ConfettiPainter(celebration),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _interval(0, 0.46),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.65, end: 1).animate(
                        CurvedAnimation(
                          parent: celebration,
                          curve: const Interval(
                            0,
                            0.5,
                            curve: AppMotion.emphasizedEnter,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 68,
                        color: AppPalette.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  MotionReveal(
                    animation: _interval(0.12, 0.62),
                    child: Column(
                      children: [
                        Text(
                          '${widget.strings.winner}: ${winner.name}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        ScaleTransition(
                          scale: TweenSequence<double>([
                            TweenSequenceItem(
                              tween: Tween(begin: 0.9, end: 1.08),
                              weight: 65,
                            ),
                            TweenSequenceItem(
                              tween: Tween(begin: 1.08, end: 1),
                              weight: 35,
                            ),
                          ]).animate(_interval(0.24, 0.76)),
                          child: TweenAnimationBuilder<int>(
                            key: const ValueKey('winner_score'),
                            tween: IntTween(
                              begin: previousScore,
                              end: winner.score,
                            ),
                            duration: AppMotion.duration(
                              context,
                              AppMotion.celebration,
                            ),
                            curve: AppMotion.enter,
                            builder: (context, value, child) => Text(
                              '$value',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Column(
                    children: [
                      for (var i = 0; i < widget.match.sides.length; i++)
                        if (i != winnerIndex)
                          MotionReveal(
                            animation: _interval(
                              0.24 + i * 0.08,
                              math.min(0.78 + i * 0.08, 0.96),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(widget.match.sides[i].name),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${widget.match.sides[i].score}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  MotionReveal(
                    animation: _interval(0.62, 1),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PressableScale(
                          child: TextButton(
                            onPressed:
                                finishing ? null : () => Navigator.pop(context),
                            child: Text(widget.strings.cancel),
                          ),
                        ),
                        PressableScale(
                          enabled: !finishing,
                          child: FilledButton(
                            onPressed: finishing ? null : _finish,
                            child: Text(widget.strings.finish),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
        parent: celebration,
        curve: Interval(begin, end, curve: AppMotion.enter),
      );

  Future<void> _finish() async {
    if (finishing) return;
    setState(() => finishing = true);
    await widget.store.clearMatch();
    if (!mounted) return;
    Navigator.of(context)
      ..pop()
      ..pop();
  }
}

class _CelebrationBackdrop extends StatelessWidget {
  const _CelebrationBackdrop({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(animation.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.75),
              radius: 1.15,
              colors: [
                Color.lerp(
                  AppPalette.surface,
                  AppPalette.gold.withValues(alpha: 0.2),
                  progress,
                )!,
                AppPalette.surface,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static const colors = [
    AppPalette.gold,
    AppPalette.emerald,
    Color(0xFF6D6DAA),
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final time = animation.value;
    if (time >= 1) return;
    for (var i = 0; i < 22; i++) {
      final delay = (i % 6) * 0.035;
      final progress = ((time - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (progress <= 0 || progress >= 1) continue;
      final x = (((i * 41) % 101) / 100) * size.width;
      final drift = math.sin(progress * math.pi * 2 + i) * 12;
      final y = 18 + progress * size.height * 0.82;
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(
          alpha: (1 - progress).clamp(0.0, 1.0),
        );
      canvas.save();
      canvas.translate(x + drift, y);
      canvas.rotate(progress * math.pi * (i.isEven ? 2 : -2));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-2.5, -4, 5, 8),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => false;
}

class AddRoundSheet extends StatefulWidget {
  const AddRoundSheet({super.key, required this.store});
  final MatchStore store;

  @override
  State<AddRoundSheet> createState() => _AddRoundSheetState();
}

class _AddRoundSheetState extends State<AddRoundSheet> {
  int basePool = 162;
  late int contractSide;
  bool contractManuallySelected = false;
  int customBonus = 0;
  int? manualPool;
  final selectedBonuses = <int>{};
  final manualPoolController = TextEditingController();
  late List<TextEditingController> points;
  int? lastEditedPoint;
  bool submitting = false;
  String? error;

  int get pool {
    final manual = manualPool;
    if (manual != null) return manual;
    final declarations = selectedBonuses.fold(
        0, (sum, index) => sum + declarationBonuses[index].points);
    return basePool + declarations + customBonus;
  }

  bool get _hasSymmetricPair {
    final mode = widget.store.activeMatch!.mode;
    return mode == MatchMode.duel || mode == MatchMode.teams;
  }

  @override
  void initState() {
    super.initState();
    final match = widget.store.activeMatch!;
    contractSide = match.dealerSide;
    final count = match.sides.length;
    points = List.generate(count, (_) => TextEditingController());
  }

  @override
  void dispose() {
    manualPoolController.dispose();
    for (final controller in points) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _pointsTotalError {
    final s = AppStrings(widget.store.language);
    return s.t(
      'Сумма очков должна быть равна $pool.',
      'Сума очок має дорівнювати $pool.',
    );
  }

  void _onPointsChanged(int index) {
    lastEditedPoint = index;
    _calculateRemainder();
  }

  void _calculateRemainder() {
    if (_hasSymmetricPair) {
      _calculatePairRemainder();
      return;
    }

    final entered = points
        .take(points.length - 1)
        .map((controller) => int.tryParse(controller.text))
        .toList();
    final remainderController = points.last;
    if (entered.any((value) => value == null)) {
      remainderController.clear();
      return;
    }
    final enteredTotal = entered.whereType<int>().fold(0, (a, b) => a + b);
    remainderController.text =
        enteredTotal <= pool ? '${pool - enteredTotal}' : '';
    if (mounted && error != null) setState(() => error = null);
  }

  void _calculatePairRemainder() {
    final editedIndex = lastEditedPoint;
    if (editedIndex == null) return;

    final editedText = points[editedIndex].text;
    final remainderController = points[1 - editedIndex];
    if (editedText.isEmpty) {
      remainderController.clear();
      if (mounted && error != null) setState(() => error = null);
      return;
    }

    final entered = int.tryParse(editedText);
    if (entered == null || entered > pool) {
      remainderController.clear();
      if (mounted) setState(() => error = _pointsTotalError);
      return;
    }

    remainderController.text = '${pool - entered}';
    if (mounted && error != null) setState(() => error = null);
  }

  void _useCalculatedPool(VoidCallback change) {
    setState(() {
      change();
      manualPool = null;
      manualPoolController.clear();
    });
    _calculateRemainder();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.store.activeMatch!;
    final s = AppStrings(widget.store.language);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.addRound,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionLabel(s.totalPool),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [162, 182, 202, 212, 222, 232, 242, 252, 262]
                      .map(
                        (value) => PressableScale(
                          child: ChoiceChip(
                            chipAnimationStyle: AppMotion.chipStyle(context),
                            label: Text('$value'),
                            selected: manualPool == null && basePool == value,
                            onSelected: (_) {
                              _useCalculatedPool(() => basePool = value);
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: manualPoolController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: s.manualPool,
                    helperText: s.t(
                      'Заменяет выбранную сумму и объявления.',
                      'Замінює обрану суму та оголошення.',
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => manualPool = int.tryParse(value));
                    _calculateRemainder();
                  },
                ),
                const SizedBox(height: 22),
                _SectionLabel(s.declarations),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < declarationBonuses.length; i++)
                      PressableScale(
                        child: FilterChip(
                          chipAnimationStyle: AppMotion.chipStyle(context),
                          label: Text(
                            '${declarationBonuses[i].label}  +${declarationBonuses[i].points}',
                          ),
                          selected: selectedBonuses.contains(i),
                          onSelected: (selected) {
                            _useCalculatedPool(() {
                              if (selected) {
                                selectedBonuses.add(i);
                              } else {
                                selectedBonuses.remove(i);
                              }
                            });
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: s.customBonus,
                    prefixText: '+ ',
                  ),
                  onChanged: (value) {
                    _useCalculatedPool(
                      () => customBonus = int.tryParse(value) ?? 0,
                    );
                  },
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceRaised,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text(s.totalPool),
                      _AnimatedIntText(
                        key: const ValueKey('animated_round_pool'),
                        value: pool,
                        style: const TextStyle(
                          color: AppPalette.gold,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _SectionLabel(s.playingSide),
                SizedBox(
                  width: double.infinity,
                  child: PopupMenuButton<int>(
                    key: const ValueKey('playing_side_dropdown'),
                    initialValue: contractSide,
                    requestFocus: false,
                    position: PopupMenuPosition.under,
                    tooltip: s.playingSide,
                    borderRadius: BorderRadius.circular(16),
                    popUpAnimationStyle: AppMotion.animationStyle(
                      context,
                      AppMotion.standard,
                    ),
                    itemBuilder: (context) => [
                      for (var i = 0; i < match.sides.length; i++)
                        PopupMenuItem(
                          value: i,
                          child: Text(match.sides[i].name),
                        ),
                    ],
                    onSelected: (value) {
                      setState(() {
                        contractSide = value;
                        contractManuallySelected = value != match.dealerSide;
                      });
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                      ),
                      child: _AnimatedSelectionText(
                        value: contractSide,
                        text: match.sides[contractSide].name,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  s.t(
                    'По умолчанию играет сторона сдающего',
                    'За замовчуванням грає сторона того, хто здає',
                  ),
                  key: const ValueKey('playing_side_hint'),
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 22),
                _SectionLabel(s.points),
                for (var i = 0; i < match.sides.length; i++) ...[
                  TextField(
                    key: ValueKey('round_points_$i'),
                    controller: points[i],
                    readOnly: !_hasSymmetricPair && i == match.sides.length - 1,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: !_hasSymmetricPair &&
                              i == match.sides.length - 1
                          ? '${match.sides[i].name} · ${s.t('остаток', 'залишок')}'
                          : match.sides[i].name,
                      suffixText: i == contractSide ? s.plays : null,
                    ),
                    onChanged: (_) => _onPointsChanged(i),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  match.sides.length == 2
                      ? s.t(
                          'Введи одно значение — второе рассчитается автоматически.',
                          'Введи одне значення — друге розрахується автоматично.',
                        )
                      : s.t(
                          'Введи первые два значения — третье рассчитается автоматически.',
                          'Введи перші два значення — третє розрахується автоматично.',
                        ),
                  style: const TextStyle(color: AppPalette.muted),
                ),
                AnimatedSwitcher(
                  duration: AppMotion.duration(context, AppMotion.standard),
                  switchInCurve: AppMotion.enter,
                  switchOutCurve: AppMotion.exit,
                  layoutBuilder: _verticalSwitcherLayout,
                  transitionBuilder: _sizeFadeTransition,
                  child: error == null
                      ? const SizedBox(key: ValueKey('no_round_error'))
                      : Padding(
                          key: ValueKey(error),
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            error!,
                            style: const TextStyle(color: AppPalette.danger),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                PressableScale(
                  enabled: !submitting,
                  child: FilledButton(
                    key: const ValueKey('save_round'),
                    onPressed: submitting ? null : () => _submit(context, s),
                    child: Text(s.save),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, AppStrings s) async {
    if (submitting) return;
    setState(() => submitting = true);

    final values =
        points.map((controller) => int.tryParse(controller.text)).toList();
    if (values.any((value) => value == null) ||
        values.whereType<int>().fold(0, (sum, value) => sum + value) != pool) {
      setState(() {
        error = _pointsTotalError;
        submitting = false;
      });
      return;
    }

    var spare = false;
    final match = widget.store.activeMatch!;
    final requiresMercy = values[contractSide] == 0 &&
        match.sides[contractSide].bolts >= match.rules.boltThreshold;
    if (requiresMercy) {
      final choice = await showMotionDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const ValueKey('mercy_dialog'),
          title: Text(s.zeroPrompt),
          content: Text(
            s.t(
              'Пощадить: только −100. Не щадить: −100 за ноль, новый болт и ещё −100.',
              'Пощадити: лише −100. Не щадити: −100 за нуль, новий болт і ще −100.',
            ),
          ),
          actions: [
            PressableScale(
              child: TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(s.noSpare),
              ),
            ),
            PressableScale(
              child: FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(s.spare),
              ),
            ),
          ],
        ),
      );
      if (choice == null) {
        if (mounted) setState(() => submitting = false);
        return;
      }
      spare = choice;
    }

    final result = await widget.store.addRound(
      RoundRequest(
        pool: pool,
        points: values.cast<int>(),
        contractSide: contractSide,
        contractManuallySelected: contractManuallySelected,
        spareZeroContract: spare,
      ),
    );
    if (!context.mounted) return;
    Navigator.pop(context, result);
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.store});
  final MatchStore store;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController entrance;
  late List<RoundEntry> rounds;
  bool started = false;
  bool undoing = false;

  @override
  void initState() {
    super.initState();
    entrance = AnimationController(vsync: this, duration: AppMotion.large);
    rounds = List.of(widget.store.activeMatch!.rounds);
    widget.store.addListener(_syncRounds);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    if (AppMotion.disabled(context)) {
      entrance.value = 1;
    } else {
      entrance.forward();
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_syncRounds);
    entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.store.activeMatch!;
    final s = AppStrings(widget.store.language);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.history),
        actions: [
          if (rounds.isNotEmpty)
            PressableScale(
              enabled: !undoing,
              child: TextButton.icon(
                onPressed: undoing ? null : _undoLast,
                icon: const Icon(Icons.undo_rounded),
                label: Text(s.t('Отменить последнюю', 'Скасувати останню')),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotion.standard),
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            child: rounds.isEmpty
                ? Center(
                    key: const ValueKey('empty_history'),
                    child: Text(s.emptyHistory),
                  )
                : ListView.separated(
                    key: ValueKey('history_${rounds.length}'),
                    padding: const EdgeInsets.all(18),
                    itemCount: rounds.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final round = rounds[index];
                      final begin = math.min(index * 0.08, 0.45);
                      return MotionReveal(
                        key: ValueKey('history_round_$index'),
                        animation: CurvedAnimation(
                          parent: entrance,
                          curve: Interval(
                            begin,
                            math.min(begin + 0.5, 1),
                            curve: AppMotion.enter,
                          ),
                        ),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      s.t(
                                        'Раздача ${index + 1}',
                                        'Роздача ${index + 1}',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    Text(
                                      '${round.pool}',
                                      style: const TextStyle(
                                        color: AppPalette.gold,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  key: ValueKey(
                                    'history_round_contract_$index',
                                  ),
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      '${s.dealer}: ${match.sides[round.dealerSide].name}',
                                    ),
                                    Text(
                                      '${s.plays}: ${match.sides[round.contractSide].name}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  round.contractManuallySelected
                                      ? s.t(
                                          'Играющая сторона выбрана вручную',
                                          'Сторону, що грає, обрано вручну',
                                        )
                                      : s.t(
                                          'Играющая сторона определена по сдающему',
                                          'Сторону, що грає, визначено за тим, хто здає',
                                        ),
                                  style: const TextStyle(
                                    color: AppPalette.muted,
                                    fontSize: 12,
                                  ),
                                ),
                                if (round.boltAdded)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const _BoltIcon(),
                                        const SizedBox(width: 6),
                                        Text(
                                          s.t('Получен болт', 'Отримано болт'),
                                          style: const TextStyle(
                                            color: AppPalette.gold,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                for (var i = 0; i < match.sides.length; i++)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(match.sides[i].name),
                                        Text(
                                          _signed(round.deltas[i]),
                                          style: TextStyle(
                                            color: round.deltas[i] < 0
                                                ? AppPalette.danger
                                                : Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (round.carriedAfter > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${s.hanging}: ${round.carriedAfter}',
                                      style: const TextStyle(
                                          color: AppPalette.gold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _undoLast() async {
    if (undoing || rounds.isEmpty) return;
    setState(() => undoing = true);
    await widget.store.undoLastRound();
    if (!mounted) return;
    setState(() {
      rounds.removeLast();
      undoing = false;
    });
  }

  void _syncRounds() {
    if (!mounted || undoing) return;
    final updated = widget.store.activeMatch?.rounds;
    if (updated == null || updated.length == rounds.length) return;
    setState(() => rounds = List.of(updated));
  }

  static String _signed(int value) => value > 0 ? '+$value' : '$value';
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.cardKey,
    required this.boltIndicatorKey,
    required this.animationKey,
    required this.side,
    required this.displayedBolts,
    required this.boltThreshold,
    required this.boltPenalty,
    required this.isDealer,
    required this.isWinner,
    required this.strings,
  });

  final GlobalKey cardKey;
  final GlobalKey<_BoltIndicatorState> boltIndicatorKey;
  final String animationKey;
  final SideState side;
  final int displayedBolts;
  final int boltThreshold;
  final int boltPenalty;
  final bool isDealer;
  final bool isWinner;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: cardKey,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    side.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                AnimatedSwitcher(
                  duration: AppMotion.duration(context, AppMotion.fast),
                  switchInCurve: AppMotion.enter,
                  switchOutCurve: AppMotion.exit,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: isDealer
                      ? _StatusChip(
                          key: const ValueKey('dealer'),
                          label: strings.dealer,
                          color: AppPalette.gold,
                        )
                      : const SizedBox(key: ValueKey('not_dealer')),
                ),
                AnimatedSwitcher(
                  duration: AppMotion.duration(context, AppMotion.fast),
                  switchInCurve: AppMotion.enter,
                  switchOutCurve: AppMotion.exit,
                  child: isWinner
                      ? const Padding(
                          key: ValueKey('winner'),
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color: AppPalette.gold,
                          ),
                        )
                      : const SizedBox(key: ValueKey('not_winner')),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _AnimatedIntText(
              key: ValueKey('animated_score_$animationKey'),
              value: side.score,
              style: const TextStyle(
                fontSize: 58,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '${strings.bolts}: ',
                  style: const TextStyle(color: AppPalette.muted),
                ),
                Expanded(
                  child: _BoltIndicator(
                    key: boltIndicatorKey,
                    animationKey: animationKey,
                    bolts: displayedBolts,
                    threshold: boltThreshold,
                    penaltyPerBolt: boltPenalty,
                    strings: strings,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BoltIndicator extends StatefulWidget {
  const _BoltIndicator({
    super.key,
    required this.animationKey,
    required this.bolts,
    required this.threshold,
    required this.penaltyPerBolt,
    required this.strings,
  });

  final String animationKey;
  final int bolts;
  final int threshold;
  final int penaltyPerBolt;
  final AppStrings strings;

  @override
  State<_BoltIndicator> createState() => _BoltIndicatorState();
}

class _BoltIndicatorState extends State<_BoltIndicator>
    with SingleTickerProviderStateMixin {
  final _landingKey = GlobalKey(debugLabel: 'bolt_rule_landing');
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  bool _penaltyPulse = false;

  BuildContext? get landingContext => _landingKey.currentContext;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: AppMotion.boltPulse);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.2), weight: 42),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.94), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1), weight: 28),
    ]).animate(CurvedAnimation(parent: _pulse, curve: AppMotion.enter));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void pulse({required bool penalty}) {
    if (!mounted || AppMotion.disabled(context)) return;
    _penaltyPulse = penalty;
    _pulse.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final penaltyBolts = math.max(
      0,
      widget.bolts - widget.threshold + 1,
    );
    final cumulativePenalty = penaltyBolts * widget.penaltyPerBolt;
    final warning = widget.bolts == widget.threshold - 1;
    final status = penaltyBolts == 0
        ? '${widget.bolts}/${widget.threshold}'
        : widget.strings.boltPenaltySummary(
            widget.bolts,
            cumulativePenalty,
          );

    return AnimatedBuilder(
      key: ValueKey('bolt_indicator_${widget.animationKey}'),
      animation: _pulse,
      builder: (context, child) {
        final redPulse = _penaltyPulse
            ? math.sin(_pulse.value * math.pi).clamp(0.0, 1.0)
            : 0.0;
        return Transform.scale(
          scale: _scale.value,
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 34,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 225;
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (!compact) ...[
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: AppMotion.duration(
                            context,
                            AppMotion.standard,
                          ),
                          switchInCurve: AppMotion.enter,
                          switchOutCurve: AppMotion.exit,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.35),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: Text(
                            status,
                            key: ValueKey(
                              'bolts_${widget.animationKey}_${widget.bolts}',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: warning || penaltyBolts > 0
                                  ? AppPalette.danger
                                  : AppPalette.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _BoltRuleBadge(
                      key: _landingKey,
                      threshold: widget.threshold,
                      penalty: widget.penaltyPerBolt,
                      tooltip: widget.strings.boltPenaltyRule,
                      warning: warning,
                      pulse: redPulse,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BoltRuleBadge extends StatelessWidget {
  const _BoltRuleBadge({
    super.key,
    required this.threshold,
    required this.penalty,
    required this.tooltip,
    required this.warning,
    required this.pulse,
  });

  final int threshold;
  final int penalty;
  final String tooltip;
  final bool warning;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final borderColor = Color.lerp(
      warning ? AppPalette.danger : const Color(0xFF355347),
      AppPalette.danger,
      pulse,
    )!;
    final background = Color.lerp(
      AppPalette.surfaceRaised,
      AppPalette.danger.withValues(alpha: 0.24),
      pulse,
    )!;
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      child: Semantics(
        button: true,
        label: tooltip,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: warning || pulse > 0 ? 1.5 : 1,
            ),
            boxShadow: pulse == 0
                ? null
                : [
                    BoxShadow(
                      color: AppPalette.danger.withValues(alpha: pulse * 0.35),
                      blurRadius: 10 * pulse,
                      spreadRadius: 1.5 * pulse,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _BoltIcon(size: 16),
              const SizedBox(width: 3),
              _RuleValueBadge(
                text: '$threshold+',
                foreground: AppPalette.gold,
                background: AppPalette.gold.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 3),
              Transform.scale(
                scale: 1 + pulse * 0.16,
                child: _RuleValueBadge(
                  text: '−$penalty',
                  foreground: Colors.white,
                  background: AppPalette.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleValueBadge extends StatelessWidget {
  const _RuleValueBadge({
    required this.text,
    required this.foreground,
    required this.background,
  });

  final String text;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BoltIcon extends StatelessWidget {
  const _BoltIcon({this.size = 19});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/bolt-color-icon.svg',
      width: size,
      height: size,
    );
  }
}

class _CarryBanner extends StatelessWidget {
  const _CarryBanner({super.key, required this.points, required this.strings});
  final int points;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_bottom_rounded, color: AppPalette.gold),
          const SizedBox(width: 10),
          Text(
            '${strings.hanging}: ',
            style: const TextStyle(
              color: AppPalette.gold,
              fontWeight: FontWeight.w800,
            ),
          ),
          _AnimatedIntText(
            value: points,
            style: const TextStyle(
              color: AppPalette.gold,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppPalette.emerald,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.style_rounded, color: Colors.black),
        ),
        const SizedBox(width: 11),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _PrivacyPill extends StatelessWidget {
  const _PrivacyPill();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: AppPalette.muted,
            ),
            SizedBox(width: 6),
            Text(
              'OFFLINE · NO ADS · NO TRACKING',
              style: TextStyle(
                color: AppPalette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AnimatedSelectionText extends StatelessWidget {
  const _AnimatedSelectionText({required this.value, required this.text});

  final int value;
  final String text;

  @override
  Widget build(BuildContext context) {
    final currentKey = ValueKey('playing_side_value_$value');
    final current = Text(
      text,
      key: currentKey,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (AppMotion.disabled(context)) return current;

    return SizedBox(
      width: double.infinity,
      height: 24,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: AppMotion.standard,
          switchInCurve: AppMotion.enter,
          switchOutCurve: AppMotion.exit,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.centerLeft,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          transitionBuilder: (child, animation) {
            final incoming = child.key == currentKey;
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, incoming ? 0.7 : -0.7),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: current,
        ),
      ),
    );
  }
}

class _AnimatedIntText extends StatefulWidget {
  const _AnimatedIntText({
    super.key,
    required this.value,
    required this.style,
  });

  final int value;
  final TextStyle style;

  @override
  State<_AnimatedIntText> createState() => _AnimatedIntTextState();
}

class _AnimatedIntTextState extends State<_AnimatedIntText> {
  @override
  Widget build(BuildContext context) {
    if (AppMotion.disabled(context)) {
      return Text('${widget.value}', style: widget.style);
    }
    final currentKey = ValueKey(widget.value);
    return AnimatedSize(
      duration: AppMotion.standard,
      curve: AppMotion.enter,
      alignment: Alignment.centerLeft,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: AppMotion.duration(context, AppMotion.standard),
          switchInCurve: AppMotion.enter,
          switchOutCurve: AppMotion.exit,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.centerLeft,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          transitionBuilder: (child, animation) {
            final incoming = child.key == currentKey;
            final offset = Tween<Offset>(
              begin: Offset(0, incoming ? 0.9 : -0.9),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: Text(
            '${widget.value}',
            key: currentKey,
            style: widget.style,
          ),
        ),
      ),
    );
  }
}

Widget _verticalSwitcherLayout(
  Widget? currentChild,
  List<Widget> previousChildren,
) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ...previousChildren,
      if (currentChild != null) currentChild,
    ],
  );
}

Widget _sizeFadeTransition(Widget child, Animation<double> animation) {
  return FadeTransition(
    opacity: animation,
    child: SizeTransition(
      sizeFactor: animation,
      alignment: Alignment.topCenter,
      child: child,
    ),
  );
}
