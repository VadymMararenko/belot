import 'game_models.dart';

class RoundRequest {
  const RoundRequest({
    required this.pool,
    required this.points,
    required this.contractSide,
    this.contractManuallySelected = false,
    this.spareZeroContract = false,
  });

  final int pool;
  final List<int> points;
  final int contractSide;
  final bool contractManuallySelected;
  final bool spareZeroContract;
}

class RoundResult {
  const RoundResult({
    required this.state,
    required this.entry,
    required this.isTie,
  });

  final MatchState state;
  final RoundEntry entry;
  final bool isTie;
}

class ScoreEngine {
  const ScoreEngine();

  RoundResult apply(MatchState state, RoundRequest request) {
    if (state.winnerSide != null) {
      throw StateError('The match is already finished.');
    }
    if (request.pool < 0) {
      throw ArgumentError.value(request.pool, 'pool', 'Cannot be negative.');
    }
    if (request.points.length != state.sides.length) {
      throw ArgumentError('Point count must match side count.');
    }
    if (request.contractSide < 0 ||
        request.contractSide >= state.sides.length) {
      throw RangeError.index(
        request.contractSide,
        state.sides,
        'contractSide',
      );
    }
    if (request.points.any((points) => points < 0)) {
      throw ArgumentError('Points cannot be negative.');
    }
    if (request.points.fold(0, (sum, value) => sum + value) != request.pool) {
      throw ArgumentError('Round points must equal the selected pool.');
    }

    final highest = request.points.reduce((a, b) => a > b ? a : b);
    final leaders = <int>[
      for (var i = 0; i < request.points.length; i++)
        if (request.points[i] == highest) i,
    ];
    final isTie = leaders.length > 1;
    final deltas = List<int>.from(request.points);
    final updatedSides = List<SideState>.from(state.sides);
    var boltAdded = false;
    var carryAfter = 0;
    var nextDealer = (state.dealerSide + 1) % state.sides.length;
    final contractPoints = request.points[request.contractSide];
    final opponentBest = [
      for (var i = 0; i < request.points.length; i++)
        if (i != request.contractSide) request.points[i],
    ].reduce((a, b) => a > b ? a : b);
    final contractLost = contractPoints < opponentBest;

    if (isTie && state.rules.tiePolicy == TiePolicy.carry) {
      for (var i = 0; i < deltas.length; i++) {
        deltas[i] = 0;
      }
      carryAfter = state.carriedPool + request.pool;
      if (state.rules.keepDealerOnCarry) nextDealer = state.dealerSide;
    } else {
      final awardPool = request.pool + state.carriedPool;
      if (isTie) {
        final share = awardPool ~/ leaders.length;
        for (var i = 0; i < deltas.length; i++) {
          deltas[i] = leaders.contains(i) ? share : 0;
        }
      } else if (state.carriedPool > 0) {
        for (var i = 0; i < deltas.length; i++) {
          deltas[i] = i == leaders.single
              ? request.points[i] + state.carriedPool
              : request.points[i];
        }
      }

      if (contractLost && leaders.length == 1) {
        final winner = leaders.single;
        for (var i = 0; i < deltas.length; i++) {
          deltas[i] = i == winner ? awardPool : 0;
        }
      }
    }

    if (contractLost) {
      final currentBolts = updatedSides[request.contractSide].bolts;
      final isZero = contractPoints == 0;
      final spare = isZero &&
          currentBolts >= state.rules.boltThreshold &&
          request.spareZeroContract;

      if (!spare) {
        boltAdded = true;
        final nextBolts = currentBolts + 1;
        updatedSides[request.contractSide] =
            updatedSides[request.contractSide].copyWith(bolts: nextBolts);
        if (nextBolts >= state.rules.boltThreshold) {
          deltas[request.contractSide] -= state.rules.boltPenalty;
        }
      }
    }

    for (var i = 0; i < request.points.length; i++) {
      if (request.points[i] == 0) {
        deltas[i] -= state.rules.zeroPenalty;
      }
    }

    for (var i = 0; i < updatedSides.length; i++) {
      updatedSides[i] =
          updatedSides[i].copyWith(score: updatedSides[i].score + deltas[i]);
    }

    final winner = _resolveWinner(updatedSides, state.rules.targetScore);
    final entry = RoundEntry(
      pool: request.pool,
      rawPoints: List.unmodifiable(request.points),
      deltas: List.unmodifiable(deltas),
      contractSide: request.contractSide,
      dealerSide: state.dealerSide,
      contractManuallySelected: request.contractManuallySelected,
      boltAdded: boltAdded,
      carriedBefore: state.carriedPool,
      carriedAfter: carryAfter,
      createdAt: DateTime.now(),
    );

    return RoundResult(
      state: state.copyWith(
        sides: updatedSides,
        rounds: [...state.rounds, entry],
        dealerSide: nextDealer,
        carriedPool: carryAfter,
        winnerSide: winner,
        clearWinner: winner == null,
      ),
      entry: entry,
      isTie: isTie,
    );
  }

  int? _resolveWinner(List<SideState> sides, int target) {
    final eligible = <int>[
      for (var i = 0; i < sides.length; i++)
        if (sides[i].score >= target) i,
    ];
    if (eligible.isEmpty) return null;
    eligible.sort((a, b) => sides[b].score.compareTo(sides[a].score));
    return eligible.first;
  }
}
