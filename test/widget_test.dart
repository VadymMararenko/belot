import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klabor_score/core/app_strings.dart';
import 'package:klabor_score/core/game_models.dart';
import 'package:klabor_score/core/match_store.dart';
import 'package:klabor_score/core/score_engine.dart';
import 'package:klabor_score/main.dart';
import 'package:klabor_score/ui/app_motion.dart';
import 'package:klabor_score/ui/screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _roundPoints(int index) => find.byKey(ValueKey('round_points_$index'));

String _roundPointsText(WidgetTester tester, int index) =>
    tester.widget<TextField>(_roundPoints(index)).controller!.text;

Future<void> _pumpAddRoundSheet(
  WidgetTester tester,
  MatchStore store,
) async {
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      home: Scaffold(body: AddRoundSheet(store: store)),
    ),
  );
  await tester.pump();
}

Future<MatchStore> _pumpTwoSideRoundSheet(
  WidgetTester tester, {
  MatchMode mode = MatchMode.teams,
  int targetScore = 1001,
  int dealerSide = 0,
  TiePolicy tiePolicy = TiePolicy.carry,
}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final store = MatchStore(preferences);
  await store.createMatch(
    mode: mode,
    rules: MatchRules(targetScore: targetScore, tiePolicy: tiePolicy),
    names: mode == MatchMode.trio
        ? const ['Первый', 'Второй', 'Третий']
        : const ['Мы', 'Они'],
    dealerSide: dealerSide,
  );
  await _pumpAddRoundSheet(tester, store);
  return store;
}

Future<MatchStore> _pumpMatchScreen(
  WidgetTester tester, {
  MatchMode mode = MatchMode.teams,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final store = MatchStore(preferences);
  await store.createMatch(
    mode: mode,
    rules: const MatchRules(),
    names: mode == MatchMode.trio
        ? const ['Первый', 'Второй', 'Третий']
        : const ['Мы', 'Они'],
    dealerSide: 0,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: MatchScreen(store: store),
      ),
    ),
  );
  await tester.pump();
  return store;
}

Future<void> _submitBoltRound(WidgetTester tester, int contractSide) async {
  await tester.tap(find.byKey(const ValueKey('add_round_action')));
  await tester.pumpAndSettle();

  if (contractSide == 1) {
    await _selectPlayingSide(tester, 1);
  }
  await tester.enterText(
    _roundPoints(0),
    contractSide == 0 ? '80' : '82',
  );
  final save = find.byKey(const ValueKey('save_round'));
  await tester.ensureVisible(save);
  await tester.tap(save);

  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 25));
    if (find
        .byKey(ValueKey('flying_bolt_$contractSide'))
        .evaluate()
        .isNotEmpty) {
      return;
    }
  }
  fail('The bolt flight for side $contractSide did not start.');
}

Future<void> _selectPlayingSide(WidgetTester tester, int side) async {
  tester
      .widget<PopupMenuButton<int>>(
        find.byKey(const ValueKey('playing_side_dropdown')),
      )
      .onSelected!(side);
  await tester.pump();
}

Future<void> _saveTwoSideRound(
  WidgetTester tester, {
  String firstPoints = '100',
}) async {
  await tester.enterText(_roundPoints(0), firstPoints);
  await tester.pump();
  final save = find.byKey(const ValueKey('save_round'));
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home screen switches between Russian and Ukrainian', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = MatchStore(preferences);
    await store.restore();

    await tester.pumpWidget(KlaborApp(store: store));
    expect(find.text('Новая партия'), findsOneWidget);
    expect(find.text('Клабор: Счёт'), findsOneWidget);

    await store.setLanguage(AppLanguage.uk);
    await tester.pump();

    expect(find.text('Нова партія'), findsOneWidget);
    expect(find.text('Клабор: Рахунок'), findsOneWidget);
  });

  testWidgets('manual total drives automatic trio remainder', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = MatchStore(preferences);
    await store.createMatch(
      mode: MatchMode.trio,
      rules: const MatchRules(),
      names: const ['Первый', 'Второй', 'Третий'],
      dealerSide: 0,
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AddRoundSheet(store: store))),
    );

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(5));
    await tester.enterText(fields.at(0), '200');
    await tester.enterText(fields.at(2), '50');
    await tester.enterText(fields.at(3), '60');
    await tester.pump();

    final remainder = tester.widget<TextField>(fields.at(4));
    expect(remainder.readOnly, isTrue);
    expect(remainder.controller!.text, '90');
    expect(find.text('4× J  +200'), findsOneWidget);
    expect(find.text('4× 9  +140'), findsOneWidget);
    expect(find.text('4× A  +110'), findsOneWidget);
    expect(find.text('4× 10  +100'), findsOneWidget);
    expect(find.text('4× K  +40'), findsOneWidget);
    expect(find.text('4× Q  +30'), findsOneWidget);
  });

  group('two-side round points', () {
    testWidgets('1×1 is symmetric and keeps the selected match target', (
      tester,
    ) async {
      final store = await _pumpTwoSideRoundSheet(
        tester,
        mode: MatchMode.duel,
        targetScore: 1501,
      );

      await tester.enterText(_roundPoints(1), '100');
      await tester.pump();
      expect(_roundPointsText(tester, 0), '62');
      expect(_roundPointsText(tester, 1), '100');

      final save = find.byKey(const ValueKey('save_round'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(store.activeMatch!.rules.targetScore, 1501);
      expect(store.activeMatch!.rounds.single.rawPoints, [62, 100]);
    });

    testWidgets('calculates remainder when the left field is entered first', (
      tester,
    ) async {
      await _pumpTwoSideRoundSheet(tester);

      await tester.enterText(_roundPoints(0), '100');
      await tester.pump();

      expect(_roundPointsText(tester, 0), '100');
      expect(_roundPointsText(tester, 1), '62');
    });

    testWidgets('calculates remainder when the right field is entered first', (
      tester,
    ) async {
      await _pumpTwoSideRoundSheet(tester);

      await tester.enterText(_roundPoints(1), '100');
      await tester.pump();

      expect(_roundPointsText(tester, 0), '62');
      expect(_roundPointsText(tester, 1), '100');
    });

    testWidgets('editing the calculated field switches the source field', (
      tester,
    ) async {
      await _pumpTwoSideRoundSheet(tester);

      await tester.enterText(_roundPoints(0), '100');
      await tester.enterText(_roundPoints(1), '50');
      await tester.pump();

      expect(_roundPointsText(tester, 0), '112');
      expect(_roundPointsText(tester, 1), '50');
      expect(
        tester.widget<TextField>(_roundPoints(1)).controller!.selection,
        const TextSelection.collapsed(offset: 2),
      );
      expect(tester.binding.focusManager.primaryFocus, isNotNull);
    });

    testWidgets('supports zero and the full pool from either side', (
      tester,
    ) async {
      await _pumpTwoSideRoundSheet(tester);

      await tester.enterText(_roundPoints(0), '0');
      await tester.pump();
      expect(_roundPointsText(tester, 1), '162');

      await tester.enterText(_roundPoints(1), '162');
      await tester.pump();
      expect(_roundPointsText(tester, 0), '0');
    });

    testWidgets('rejects values over the pool and treats empty as empty', (
      tester,
    ) async {
      final store = await _pumpTwoSideRoundSheet(tester);

      await tester.enterText(_roundPoints(0), '163');
      await tester.pump();
      expect(_roundPointsText(tester, 1), isEmpty);
      expect(find.text('Сумма очков должна быть равна 162.'), findsOneWidget);

      final save = find.byKey(const ValueKey('save_round'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      expect(store.activeMatch!.rounds, isEmpty);

      await tester.enterText(_roundPoints(0), '');
      await tester.pump();
      expect(_roundPointsText(tester, 0), isEmpty);
      expect(_roundPointsText(tester, 1), isEmpty);
      expect(find.text('Сумма очков должна быть равна 162.'), findsNothing);

      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      expect(find.text('Сумма очков должна быть равна 162.'), findsOneWidget);
      expect(store.activeMatch!.rounds, isEmpty);
    });

    testWidgets('bank changes follow the last manually edited field', (
      tester,
    ) async {
      await _pumpTwoSideRoundSheet(tester);

      await tester.enterText(_roundPoints(1), '100');
      await tester.pump();
      expect(_roundPointsText(tester, 0), '62');

      final bonus = find.text('4× K  +40');
      await tester.ensureVisible(bonus);
      await tester.tap(bonus);
      await tester.pump();
      expect(_roundPointsText(tester, 0), '102');
      expect(_roundPointsText(tester, 1), '100');
    });

    testWidgets('rapid alternating edits do not loop or lose the last value', (
      tester,
    ) async {
      await _pumpTwoSideRoundSheet(tester);

      await tester.enterText(_roundPoints(0), '100');
      await tester.enterText(_roundPoints(1), '50');
      await tester.enterText(_roundPoints(0), '10');
      await tester.enterText(_roundPoints(1), '80');
      await tester.pump();

      expect(_roundPointsText(tester, 0), '82');
      expect(_roundPointsText(tester, 1), '80');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a rapid double tap saves only one round', (tester) async {
      final store = await _pumpTwoSideRoundSheet(tester);
      await tester.enterText(_roundPoints(0), '80');
      await tester.pump();

      final save = find.byKey(const ValueKey('save_round'));
      await tester.ensureVisible(save);
      final onPressed = tester.widget<FilledButton>(save).onPressed!;
      onPressed();
      onPressed();
      await tester.pumpAndSettle();

      expect(store.activeMatch!.rounds, hasLength(1));
      expect(store.activeMatch!.rounds.single.rawPoints, [80, 82]);
      expect(store.activeMatch!.sides[0].bolts, 1);
      expect(store.activeMatch!.dealerSide, 1);
      expect(store.activeMatch!.rounds.single.contractSide, 0);
      expect(
        store.activeMatch!.rounds.single.contractManuallySelected,
        isFalse,
      );
    });
  });

  group('playing side follows the dealer', () {
    testWidgets('first dealer Мы is selected automatically', (tester) async {
      await _pumpTwoSideRoundSheet(tester, dealerSide: 0);

      expect(
        find.byKey(const ValueKey('playing_side_value_0')),
        findsOneWidget,
      );
      expect(
        find.text('По умолчанию играет сторона сдающего'),
        findsOneWidget,
      );
    });

    testWidgets('first dealer Они is selected automatically', (tester) async {
      await _pumpTwoSideRoundSheet(tester, dealerSide: 1);

      expect(
        find.byKey(const ValueKey('playing_side_value_1')),
        findsOneWidget,
      );
    });

    testWidgets('successful round moves dealer and next automatic selection', (
      tester,
    ) async {
      final store = await _pumpTwoSideRoundSheet(tester, dealerSide: 0);
      await _saveTwoSideRound(tester);

      expect(store.activeMatch!.dealerSide, 1);
      expect(store.activeMatch!.rounds.single.contractSide, 0);
      expect(
        store.activeMatch!.rounds.single.contractManuallySelected,
        isFalse,
      );

      await _pumpAddRoundSheet(tester, store);
      expect(
        find.byKey(const ValueKey('playing_side_value_1')),
        findsOneWidget,
      );
    });

    testWidgets('manual override preserves input and does not change dealer', (
      tester,
    ) async {
      final store = await _pumpTwoSideRoundSheet(tester, dealerSide: 1);
      await tester.enterText(_roundPoints(0), '40');
      await tester.pump();
      final bonus = find.widgetWithText(FilterChip, '4× K  +40');
      await tester.ensureVisible(bonus);
      await tester.tap(bonus);
      await tester.pump();
      final focusBefore = tester.binding.focusManager.primaryFocus;

      await tester.tap(
        find.byKey(const ValueKey('playing_side_dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Мы').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(store.activeMatch!.dealerSide, 1);
      expect(_roundPointsText(tester, 0), '40');
      expect(_roundPointsText(tester, 1), '162');
      expect(tester.widget<FilterChip>(bonus).selected, isTrue);
      expect(tester.binding.focusManager.primaryFocus, same(focusBefore));
      final oldSide = find.byKey(const ValueKey('playing_side_value_1'));
      final newSide = find.byKey(const ValueKey('playing_side_value_0'));
      expect(oldSide, findsOneWidget);
      expect(newSide, findsOneWidget);
      expect(
        tester.getCenter(oldSide).dy,
        lessThan(tester.getCenter(newSide).dy),
      );
    });

    testWidgets('manual override is recorded and drives bolt calculation', (
      tester,
    ) async {
      final store = await _pumpTwoSideRoundSheet(tester, dealerSide: 1);
      await _selectPlayingSide(tester, 0);
      await tester.pumpAndSettle();
      await _saveTwoSideRound(tester, firstPoints: '40');

      final round = store.activeMatch!.rounds.single;
      expect(round.dealerSide, 1);
      expect(round.contractSide, 0);
      expect(round.contractManuallySelected, isTrue);
      expect(round.boltAdded, isTrue);
      expect(store.activeMatch!.sides[0].bolts, 1);
      expect(store.activeMatch!.sides[1].bolts, 0);

      final restored = MatchStore(await SharedPreferences.getInstance());
      await restored.restore();
      expect(
        restored.activeMatch!.rounds.single.contractManuallySelected,
        isTrue,
      );
      expect(restored.activeMatch!.rounds.single.contractSide, 0);

      await tester.pumpWidget(
        MaterialApp(key: UniqueKey(), home: HistoryScreen(store: restored)),
      );
      await tester.pump();
      expect(find.text('Сдаёт: Они'), findsOneWidget);
      expect(find.text('Играет: Мы'), findsOneWidget);
      expect(find.text('Играющая сторона выбрана вручную'), findsOneWidget);
      expect(find.text('Получен болт'), findsOneWidget);
    });

    testWidgets('validation error changes neither dealer nor selection', (
      tester,
    ) async {
      final store = await _pumpTwoSideRoundSheet(tester, dealerSide: 1);
      await _selectPlayingSide(tester, 0);
      await tester.enterText(_roundPoints(0), '163');
      final save = find.byKey(const ValueKey('save_round'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();

      expect(store.activeMatch!.rounds, isEmpty);
      expect(store.activeMatch!.dealerSide, 1);
      expect(
        find.byKey(const ValueKey('playing_side_value_0')),
        findsOneWidget,
      );
      expect(find.text('Сумма очков должна быть равна 162.'), findsOneWidget);
    });

    testWidgets('undo restores dealer used by the next round sheet', (
      tester,
    ) async {
      final store = await _pumpTwoSideRoundSheet(tester, dealerSide: 0);
      await _saveTwoSideRound(tester);
      expect(store.activeMatch!.dealerSide, 1);

      await store.undoLastRound();
      expect(store.activeMatch!.dealerSide, 0);
      await _pumpAddRoundSheet(tester, store);

      expect(store.activeMatch!.rounds, isEmpty);
      expect(
        find.byKey(const ValueKey('playing_side_value_0')),
        findsOneWidget,
      );
    });

    testWidgets('reload uses the persisted current dealer', (tester) async {
      final store = await _pumpTwoSideRoundSheet(tester, dealerSide: 0);
      await _saveTwoSideRound(tester);
      expect(store.activeMatch!.dealerSide, 1);

      final restored = MatchStore(await SharedPreferences.getInstance());
      await restored.restore();
      await _pumpAddRoundSheet(tester, restored);

      expect(restored.activeMatch!.dealerSide, 1);
      expect(
        find.byKey(const ValueKey('playing_side_value_1')),
        findsOneWidget,
      );
    });

    testWidgets('manual trio override resets to the next dealer', (
      tester,
    ) async {
      final store = await _pumpTwoSideRoundSheet(
        tester,
        mode: MatchMode.trio,
        dealerSide: 0,
      );
      await _selectPlayingSide(tester, 2);
      await tester.enterText(_roundPoints(0), '90');
      await tester.enterText(_roundPoints(1), '50');
      final save = find.byKey(const ValueKey('save_round'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(store.activeMatch!.rounds.single.contractSide, 2);
      expect(
        store.activeMatch!.rounds.single.contractManuallySelected,
        isTrue,
      );
      expect(store.activeMatch!.dealerSide, 1);

      await _pumpAddRoundSheet(tester, store);
      expect(
        find.byKey(const ValueKey('playing_side_value_1')),
        findsOneWidget,
      );
    });

    testWidgets('all match modes derive selection from their dealer', (
      tester,
    ) async {
      for (final scenario in const [
        (MatchMode.duel, 1),
        (MatchMode.teams, 1),
        (MatchMode.trio, 2),
      ]) {
        await _pumpTwoSideRoundSheet(
          tester,
          mode: scenario.$1,
          dealerSide: scenario.$2,
        );
        expect(
          find.byKey(ValueKey('playing_side_value_${scenario.$2}')),
          findsOneWidget,
          reason: scenario.$1.label,
        );
      }
    });

    testWidgets('carry keeps dealer and automatic selection aligned', (
      tester,
    ) async {
      final store = await _pumpTwoSideRoundSheet(tester, dealerSide: 1);
      await _saveTwoSideRound(tester, firstPoints: '81');

      expect(store.activeMatch!.carriedPool, 162);
      expect(store.activeMatch!.dealerSide, 1);
      await _pumpAddRoundSheet(tester, store);
      expect(
        find.byKey(const ValueKey('playing_side_value_1')),
        findsOneWidget,
      );
    });

    testWidgets('split tie follows the dealer after it actually changes', (
      tester,
    ) async {
      final store = await _pumpTwoSideRoundSheet(
        tester,
        dealerSide: 1,
        tiePolicy: TiePolicy.split,
      );
      await _saveTwoSideRound(tester, firstPoints: '81');

      expect(store.activeMatch!.carriedPool, 0);
      expect(store.activeMatch!.dealerSide, 0);
      await _pumpAddRoundSheet(tester, store);
      expect(
        find.byKey(const ValueKey('playing_side_value_0')),
        findsOneWidget,
      );
    });
  });

  group('interface motion', () {
    testWidgets('mode switch animates participant fields and preserves names', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = MatchStore(preferences);

      await tester.pumpWidget(MaterialApp(home: SetupScreen(store: store)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Анна');

      await tester.tap(find.text('1×1×1'));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('participant_field_2')),
        findsOneWidget,
      );
      expect(find.byType(FadeTransition), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(3));
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Анна',
      );

      await tester.tap(find.text('2×2'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('participant_field_2')),
        findsNothing,
      );
      expect(find.byType(TextField), findsNWidgets(2));
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Анна',
      );
    });

    testWidgets('score change moves the old value up and the new value in', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = MatchStore(preferences);
      await store.createMatch(
        mode: MatchMode.teams,
        rules: const MatchRules(),
        names: const ['Мы', 'Они'],
        dealerSide: 0,
      );
      await tester.pumpWidget(MaterialApp(home: MatchScreen(store: store)));

      final score = find.byKey(const ValueKey('animated_score_0'));
      expect(
        find.descendant(of: score, matching: find.byKey(const ValueKey(0))),
        findsOneWidget,
      );
      await store.addRound(
        const RoundRequest(
          pool: 162,
          points: [100, 62],
          contractSide: 0,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final oldValue = find.descendant(
        of: score,
        matching: find.byKey(const ValueKey(0)),
      );
      final newValue = find.descendant(
        of: score,
        matching: find.byKey(const ValueKey(100)),
      );
      expect(oldValue, findsOneWidget);
      expect(newValue, findsOneWidget);
      expect(
        tester.getCenter(oldValue).dy,
        lessThan(tester.getCenter(newValue).dy),
      );
      await tester.pumpAndSettle();
      expect(oldValue, findsNothing);
      expect(newValue, findsOneWidget);
    });

    testWidgets('a bolt awarded to the left side flies into its indicator', (
      tester,
    ) async {
      final store = await _pumpMatchScreen(tester);

      await _submitBoltRound(tester, 0);

      expect(store.activeMatch!.sides[0].bolts, 1);
      expect(
        find.byKey(const ValueKey('bolts_0_0')),
        findsOneWidget,
      );
      final flying = find.byKey(const ValueKey('flying_bolt_0'));
      final target = find.byKey(const ValueKey('bolt_indicator_0'));
      expect(flying, findsOneWidget);
      expect(target, findsOneWidget);

      await tester.pump(const Duration(milliseconds: 960));
      expect(
        (tester.getCenter(flying) - tester.getCenter(target)).distance,
        lessThan(1),
      );

      await tester.pumpAndSettle();
      expect(flying, findsNothing);
      expect(find.byKey(const ValueKey('bolts_0_1')), findsOneWidget);
      expect(store.activeMatch!.rounds, hasLength(1));
    });

    testWidgets('a bolt awarded to the right side uses its own indicator', (
      tester,
    ) async {
      final store = await _pumpMatchScreen(tester);

      await _submitBoltRound(tester, 1);

      expect(store.activeMatch!.sides[1].bolts, 1);
      expect(find.byKey(const ValueKey('flying_bolt_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('bolts_1_0')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('flying_bolt_1')), findsNothing);
      expect(find.byKey(const ValueKey('bolts_1_1')), findsOneWidget);
    });

    testWidgets('undo cancels an active flight and removes its bolt', (
      tester,
    ) async {
      final store = await _pumpMatchScreen(tester);
      await _submitBoltRound(tester, 0);
      expect(store.activeMatch!.sides[0].bolts, 1);
      expect(find.byKey(const ValueKey('flying_bolt_0')), findsOneWidget);

      await store.undoLastRound();
      await tester.pumpAndSettle();

      expect(store.activeMatch!.sides[0].bolts, 0);
      expect(store.activeMatch!.rounds, isEmpty);
      expect(find.byKey(const ValueKey('flying_bolt_0')), findsNothing);
      expect(find.byKey(const ValueKey('bolts_0_0')), findsOneWidget);
    });

    testWidgets('sequential bolt events are animated from a queue', (
      tester,
    ) async {
      final store = await _pumpMatchScreen(tester);
      await _submitBoltRound(tester, 0);

      await tester.tap(find.byKey(const ValueKey('add_round_action')));
      await tester.pump();
      await tester.pump(AppMotion.standard);
      await tester.enterText(_roundPoints(0), '82');
      final save = find.byKey(const ValueKey('save_round'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump(AppMotion.standard);
      await tester.pump();

      expect(store.activeMatch!.rounds, hasLength(2));
      expect(store.activeMatch!.rounds.last.contractSide, 1);
      expect(store.activeMatch!.sides[0].bolts, 1);
      expect(store.activeMatch!.sides[1].bolts, 1);
      expect(find.byKey(const ValueKey('flying_bolt_0')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 420));
      await tester.pump();
      expect(find.byKey(const ValueKey('flying_bolt_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('bolts_0_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('bolts_1_0')), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('flying_bolt_0')), findsNothing);
      expect(find.byKey(const ValueKey('flying_bolt_1')), findsNothing);
      expect(find.byKey(const ValueKey('bolts_0_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('bolts_1_1')), findsOneWidget);
    });

    testWidgets('trio flight resolves the third player anchors', (
      tester,
    ) async {
      final store = await _pumpMatchScreen(tester, mode: MatchMode.trio);
      await tester.tap(find.byKey(const ValueKey('add_round_action')));
      await tester.pumpAndSettle();
      await _selectPlayingSide(tester, 2);
      await tester.enterText(_roundPoints(0), '70');
      await tester.enterText(_roundPoints(1), '70');
      final save = find.byKey(const ValueKey('save_round'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 25));
        if (find.byKey(const ValueKey('flying_bolt_2')).evaluate().isNotEmpty) {
          break;
        }
      }

      expect(store.activeMatch!.sides[2].bolts, 1);
      expect(find.byKey(const ValueKey('flying_bolt_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('bolt_indicator_2')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('bolts_2_1')), findsOneWidget);
    });

    testWidgets('reduced motion shows a short bolt at the target', (
      tester,
    ) async {
      final store = await _pumpMatchScreen(tester, disableAnimations: true);
      await _submitBoltRound(tester, 0);
      final flying = find.byKey(const ValueKey('flying_bolt_0'));
      final target = find.byKey(const ValueKey('bolt_indicator_0'));

      expect(store.activeMatch!.sides[0].bolts, 1);
      expect(flying, findsOneWidget);
      expect(
        (tester.getCenter(flying) - tester.getCenter(target)).distance,
        lessThan(1),
      );

      await tester.pump(AppMotion.reducedMotionHold);
      await tester.pump();
      expect(flying, findsNothing);
      expect(find.byKey(const ValueKey('bolts_0_1')), findsOneWidget);
    });

    testWidgets('restored bolts do not replay their flight', (tester) async {
      final store = await _pumpMatchScreen(tester);
      await store.addRound(
        const RoundRequest(
          pool: 162,
          points: [80, 82],
          contractSide: 0,
        ),
      );
      final restored = MatchStore(await SharedPreferences.getInstance());
      await restored.restore();

      await tester.pumpWidget(MaterialApp(home: MatchScreen(store: restored)));
      await tester.pump();

      expect(restored.activeMatch!.sides[0].bolts, 1);
      expect(find.byKey(const ValueKey('flying_bolt_0')), findsNothing);
      expect(find.byKey(const ValueKey('bolts_0_1')), findsOneWidget);
    });

    testWidgets('history row appears and undo removes it with animation', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = MatchStore(preferences);
      await store.createMatch(
        mode: MatchMode.teams,
        rules: const MatchRules(),
        names: const ['Мы', 'Они'],
        dealerSide: 0,
      );
      await tester.pumpWidget(MaterialApp(home: HistoryScreen(store: store)));
      expect(find.text('Раздач пока нет'), findsOneWidget);

      await store.addRound(
        const RoundRequest(
          pool: 162,
          points: [100, 62],
          contractSide: 0,
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('history_round_0')), findsOneWidget);
      expect(find.text('Раздача 1'), findsOneWidget);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Отменить последнюю'));
      await tester.pumpAndSettle();
      expect(find.text('Раздач пока нет'), findsOneWidget);
      expect(store.activeMatch!.rounds, isEmpty);
    });

    testWidgets('confirmation dialog fades in and closes without an action', (
      tester,
    ) async {
      final store = await _pumpTwoSideRoundSheet(tester);
      final match = store.activeMatch!;
      store.activeMatch = match.copyWith(
        sides: [
          match.sides[0].copyWith(bolts: 3),
          match.sides[1],
        ],
      );
      await tester.enterText(_roundPoints(0), '0');
      final save = find.byKey(const ValueKey('save_round'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();

      expect(find.byKey(const ValueKey('mercy_dialog')), findsOneWidget);
      expect(find.byType(FadeTransition), findsWidgets);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mercy_dialog')), findsNothing);
      expect(store.activeMatch!.rounds, isEmpty);
    });

    testWidgets('winner dialog reveals results and finite confetti', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = MatchStore(preferences);
      await store.createMatch(
        mode: MatchMode.teams,
        rules: const MatchRules(targetScore: 100),
        names: const ['Мы', 'Они'],
        dealerSide: 0,
      );
      await store.addRound(
        const RoundRequest(
          pool: 162,
          points: [100, 62],
          contractSide: 0,
        ),
      );
      await tester.pumpWidget(MaterialApp(home: MatchScreen(store: store)));
      await tester.tap(find.byKey(const ValueKey('winner_action')));
      await tester.pump();

      expect(find.byKey(const ValueKey('winner_dialog')), findsOneWidget);
      expect(find.byKey(const ValueKey('winner_confetti')), findsOneWidget);
      expect(find.text('Победитель: Мы'), findsOneWidget);
      expect(find.text('Они'), findsWidgets);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);

      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('winner_dialog')), findsNothing);
    });

    testWidgets('disabled system animations settle immediately',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = MatchStore(preferences);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: SetupScreen(store: store),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widgetList<MotionReveal>(find.byType(MotionReveal))
            .every((widget) => widget.animation.value == 1),
        isTrue,
      );

      await tester.tap(find.text('1×1×1'));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('participant_field_2')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<AnimatedSwitcher>(
              find.byKey(const ValueKey('participant_count_switcher')),
            )
            .every((widget) => widget.duration == Duration.zero),
        isTrue,
      );
    });

    testWidgets('animated layouts handle large text on a narrow screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = MatchStore(preferences);
      await store.createMatch(
        mode: MatchMode.trio,
        rules: const MatchRules(),
        names: const ['Первый', 'Второй', 'Третий'],
        dealerSide: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.6),
            ),
            child: MatchScreen(store: store),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('setup saves the selected first dealer by participant name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = MatchStore(preferences);

    expect(AppStrings(AppLanguage.ru).firstDealer, 'Первым сдаёт');
    expect(AppStrings(AppLanguage.uk).firstDealer, 'Першим здає');

    await tester.pumpWidget(
      MaterialApp(home: SetupScreen(store: store)),
    );

    expect(find.text('Первым сдаёт'), findsOneWidget);
    expect(find.byKey(const ValueKey('initial_dealer_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('initial_dealer_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('initial_dealer_2')), findsNothing);
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('initial_dealer_0')),
          )
          .selected,
      isTrue,
    );

    await tester.tap(find.text('1×1×1'));
    await tester.pump();
    expect(find.byKey(const ValueKey('initial_dealer_2')), findsOneWidget);

    final nameFields = find.byType(TextField);
    await tester.enterText(nameFields.at(0), 'Анна');
    await tester.enterText(nameFields.at(1), 'Богдан');
    await tester.enterText(nameFields.at(2), 'София');
    await tester.pump();

    final thirdDealer = find.byKey(const ValueKey('initial_dealer_2'));
    expect(
      (tester.widget<ChoiceChip>(thirdDealer).label as Text).data,
      'София',
    );
    await tester.tap(thirdDealer);
    await tester.pump();
    expect(tester.widget<ChoiceChip>(thirdDealer).selected, isTrue);

    final startButton = find.text('Начать игру');
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(store.activeMatch!.dealerSide, 2);
    expect(
      store.activeMatch!.sides.map((side) => side.name),
      ['Анна', 'Богдан', 'София'],
    );

    final restoredStore = MatchStore(preferences);
    await restoredStore.restore();
    expect(restoredStore.activeMatch!.dealerSide, 2);
  });

  testWidgets('core screens adapt without overflow when window is resized', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = MatchStore(preferences);
    await store.restore();

    for (final size in const [
      Size(320, 480),
      Size(600, 400),
      Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(KlaborApp(store: store));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'HomeScreen at $size');
    }

    tester.view.physicalSize = const Size(320, 480);
    await tester.pumpWidget(
      MaterialApp(home: SetupScreen(store: store)),
    );
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'SetupScreen at 320×480');

    await store.createMatch(
      mode: MatchMode.trio,
      rules: const MatchRules(),
      names: const ['Первый', 'Второй', 'Третий'],
      dealerSide: 0,
    );
    await tester.pumpWidget(
      MaterialApp(home: MatchScreen(store: store)),
    );
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'MatchScreen at 320×480');

    await store.addRound(
      const RoundRequest(
        pool: 162,
        points: [100, 40, 22],
        contractSide: 0,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(store: store)),
    );
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'HistoryScreen at 320×480');

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AddRoundSheet(store: store))),
    );
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'AddRoundSheet at 320×480');
  });
}
