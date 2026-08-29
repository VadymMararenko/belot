import 'package:flutter_test/flutter_test.dart';
import 'package:klabor_score/core/game_models.dart';
import 'package:klabor_score/core/score_engine.dart';

void main() {
  const engine = ScoreEngine();

  MatchState match({
    int firstScore = 0,
    int secondScore = 0,
    int firstBolts = 0,
    int secondBolts = 0,
    TiePolicy tiePolicy = TiePolicy.carry,
  }) {
    return MatchState(
      mode: MatchMode.teams,
      rules: MatchRules(tiePolicy: tiePolicy),
      sides: [
        SideState(name: 'Мы', score: firstScore, bolts: firstBolts),
        SideState(name: 'Они', score: secondScore, bolts: secondBolts),
      ],
      rounds: const [],
    );
  }

  test('normal round keeps actual points', () {
    final result = engine.apply(
      match(),
      const RoundRequest(pool: 162, points: [100, 62], contractSide: 0),
    );

    expect(result.state.sides[0].score, 100);
    expect(result.state.sides[1].score, 62);
    expect(result.state.sides[0].bolts, 0);
    expect(result.state.dealerSide, 1);
  });

  test('contract loss gives whole pool to opponent and adds bolt', () {
    final result = engine.apply(
      match(),
      const RoundRequest(pool: 182, points: [80, 102], contractSide: 0),
    );

    expect(result.state.sides[0].score, 0);
    expect(result.state.sides[1].score, 182);
    expect(result.state.sides[0].bolts, 1);
  });

  test('zero always applies minus 100 to non-contract side', () {
    final result = engine.apply(
      match(secondScore: 250),
      const RoundRequest(pool: 162, points: [162, 0], contractSide: 0),
    );

    expect(result.state.sides[0].score, 162);
    expect(result.state.sides[1].score, 150);
    expect(result.state.sides[1].bolts, 0);
  });

  test('fourth zero bolt without mercy costs 200', () {
    final result = engine.apply(
      match(firstScore: 500, firstBolts: 3),
      const RoundRequest(pool: 162, points: [0, 162], contractSide: 0),
    );

    expect(result.state.sides[0].score, 300);
    expect(result.state.sides[0].bolts, 4);
    expect(result.state.sides[1].score, 162);
  });

  test('mercy on zero keeps three bolts and costs only 100', () {
    final result = engine.apply(
      match(firstScore: 500, firstBolts: 3),
      const RoundRequest(
        pool: 162,
        points: [0, 162],
        contractSide: 0,
        spareZeroContract: true,
      ),
    );

    expect(result.state.sides[0].score, 400);
    expect(result.state.sides[0].bolts, 3);
  });

  test('tie carries pool and keeps dealer', () {
    final hanging = engine.apply(
      match(),
      const RoundRequest(pool: 162, points: [81, 81], contractSide: 0),
    );

    expect(hanging.state.carriedPool, 162);
    expect(hanging.state.dealerSide, 0);
    expect(hanging.state.sides[0].score, 0);
    expect(hanging.state.sides[1].score, 0);

    final resolved = engine.apply(
      hanging.state,
      const RoundRequest(pool: 162, points: [100, 62], contractSide: 0),
    );

    expect(resolved.state.sides[0].score, 262);
    expect(resolved.state.sides[1].score, 62);
    expect(resolved.state.carriedPool, 0);
  });

  test('split tie writes equal points immediately', () {
    final result = engine.apply(
      match(tiePolicy: TiePolicy.split),
      const RoundRequest(pool: 162, points: [81, 81], contractSide: 0),
    );

    expect(result.state.sides[0].score, 81);
    expect(result.state.sides[1].score, 81);
    expect(result.state.carriedPool, 0);
  });

  test('all game modes expose the expected number of sides', () {
    expect(MatchMode.duel.sides, 2);
    expect(MatchMode.trio.sides, 3);
    expect(MatchMode.teams.sides, 2);
    expect(
      MatchMode.values.map((mode) => mode.label),
      ['1×1', '1×1×1', '2×2'],
    );
  });

  test('declaration values match the game rules', () {
    expect(
      declarationBonuses.map((bonus) => (bonus.label, bonus.points)),
      [
        ('4× J', 200),
        ('4× 9', 140),
        ('4× A', 110),
        ('4× 10', 100),
        ('4× K', 40),
        ('4× Q', 30),
      ],
    );
  });

  test('third bolt has no separate penalty', () {
    final result = engine.apply(
      match(firstScore: 500, firstBolts: 2),
      const RoundRequest(pool: 162, points: [80, 82], contractSide: 0),
    );

    expect(result.state.sides[0].score, 500);
    expect(result.state.sides[0].bolts, 3);
    expect(result.state.sides[1].score, 162);
  });

  test('every bolt after the third has a 100 point penalty', () {
    final result = engine.apply(
      match(firstScore: 500, firstBolts: 4),
      const RoundRequest(pool: 162, points: [80, 82], contractSide: 0),
    );

    expect(result.state.sides[0].score, 400);
    expect(result.state.sides[0].bolts, 5);
    expect(result.state.sides[1].score, 162);
  });

  test('trio awards the whole pool to the best opponent', () {
    final trio = MatchState(
      mode: MatchMode.trio,
      rules: const MatchRules(),
      sides: const [
        SideState(name: 'A'),
        SideState(name: 'B'),
        SideState(name: 'C'),
      ],
      rounds: const [],
    );
    final result = engine.apply(
      trio,
      const RoundRequest(pool: 162, points: [50, 70, 42], contractSide: 0),
    );

    expect(result.state.sides.map((side) => side.score), [0, 162, 0]);
    expect(result.state.sides[0].bolts, 1);
  });

  test('trio tie carries points, penalizes zero, and keeps dealer', () {
    final trio = MatchState(
      mode: MatchMode.trio,
      rules: const MatchRules(),
      sides: const [
        SideState(name: 'A'),
        SideState(name: 'B'),
        SideState(name: 'C'),
      ],
      rounds: const [],
      dealerSide: 1,
    );
    final result = engine.apply(
      trio,
      const RoundRequest(pool: 162, points: [81, 81, 0], contractSide: 0),
    );

    expect(result.state.sides.map((side) => side.score), [0, 0, -100]);
    expect(result.state.carriedPool, 162);
    expect(result.state.dealerSide, 1);
  });

  test('contract side gets a bolt when two opponents tie above it', () {
    final trio = MatchState(
      mode: MatchMode.trio,
      rules: const MatchRules(),
      sides: const [
        SideState(name: 'A'),
        SideState(name: 'B'),
        SideState(name: 'C'),
      ],
      rounds: const [],
    );
    final result = engine.apply(
      trio,
      const RoundRequest(pool: 162, points: [40, 61, 61], contractSide: 0),
    );

    expect(result.state.sides[0].score, 0);
    expect(result.state.sides[0].bolts, 1);
    expect(result.state.carriedPool, 162);
  });

  test('winner is fixed in the round that reaches target score', () {
    final result = engine.apply(
      match(firstScore: 950),
      const RoundRequest(pool: 162, points: [100, 62], contractSide: 0),
    );

    expect(result.state.sides[0].score, 1050);
    expect(result.state.winnerSide, 0);
    expect(
      () => engine.apply(
        result.state,
        const RoundRequest(pool: 162, points: [100, 62], contractSide: 0),
      ),
      throwsStateError,
    );
  });

  test('manual pool value is accepted when entered points match it', () {
    final result = engine.apply(
      match(),
      const RoundRequest(pool: 200, points: [120, 80], contractSide: 0),
    );

    expect(result.entry.pool, 200);
    expect(result.state.sides.map((side) => side.score), [120, 80]);
  });

  test('round persistence keeps manual contract selection metadata', () {
    final result = engine.apply(
      match(),
      const RoundRequest(
        pool: 162,
        points: [100, 62],
        contractSide: 1,
        contractManuallySelected: true,
      ),
    );

    final restored = RoundEntry.fromJson(
      Map<String, dynamic>.from(result.entry.toJson()),
    );
    expect(restored.dealerSide, 0);
    expect(restored.contractSide, 1);
    expect(restored.contractManuallySelected, isTrue);

    final legacyJson = Map<String, dynamic>.from(result.entry.toJson())
      ..remove('contractManuallySelected');
    expect(
      RoundEntry.fromJson(legacyJson).contractManuallySelected,
      isFalse,
    );
  });

  test('ordinary rounds rotate dealer through every trio side', () {
    final trio = MatchState(
      mode: MatchMode.trio,
      rules: const MatchRules(),
      sides: const [
        SideState(name: 'A'),
        SideState(name: 'B'),
        SideState(name: 'C'),
      ],
      rounds: const [],
      dealerSide: 2,
    );

    final first = engine.apply(
      trio,
      const RoundRequest(pool: 162, points: [100, 40, 22], contractSide: 0),
    );
    final second = engine.apply(
      first.state,
      const RoundRequest(pool: 162, points: [100, 40, 22], contractSide: 0),
    );

    expect(first.state.dealerSide, 0);
    expect(second.state.dealerSide, 1);
  });
}
