enum AppLanguage { ru, uk }

enum MatchMode {
  duel('1×1', 2),
  trio('1×1×1', 3),
  teams('2×2', 2);

  const MatchMode(this.label, this.sides);
  final String label;
  final int sides;
}

enum TiePolicy { split, carry }

class MatchRules {
  const MatchRules({
    this.targetScore = 1001,
    this.zeroPenalty = 100,
    this.boltThreshold = 3,
    this.boltPenalty = 100,
    this.tiePolicy = TiePolicy.carry,
    this.keepDealerOnCarry = true,
  });

  final int targetScore;
  final int zeroPenalty;
  final int boltThreshold;
  final int boltPenalty;
  final TiePolicy tiePolicy;
  final bool keepDealerOnCarry;

  MatchRules copyWith({
    int? targetScore,
    int? zeroPenalty,
    int? boltThreshold,
    int? boltPenalty,
    TiePolicy? tiePolicy,
    bool? keepDealerOnCarry,
  }) {
    return MatchRules(
      targetScore: targetScore ?? this.targetScore,
      zeroPenalty: zeroPenalty ?? this.zeroPenalty,
      boltThreshold: boltThreshold ?? this.boltThreshold,
      boltPenalty: boltPenalty ?? this.boltPenalty,
      tiePolicy: tiePolicy ?? this.tiePolicy,
      keepDealerOnCarry: keepDealerOnCarry ?? this.keepDealerOnCarry,
    );
  }

  Map<String, Object> toJson() => {
        'targetScore': targetScore,
        'zeroPenalty': zeroPenalty,
        'boltThreshold': boltThreshold,
        'boltPenalty': boltPenalty,
        'tiePolicy': tiePolicy.name,
        'keepDealerOnCarry': keepDealerOnCarry,
      };

  factory MatchRules.fromJson(Map<String, dynamic> json) {
    return MatchRules(
      targetScore: json['targetScore'] as int? ?? 1001,
      zeroPenalty: json['zeroPenalty'] as int? ?? 100,
      boltThreshold: json['boltThreshold'] as int? ?? 3,
      boltPenalty: json['boltPenalty'] as int? ?? 100,
      tiePolicy: TiePolicy.values.firstWhere(
        (value) => value.name == json['tiePolicy'],
        orElse: () => TiePolicy.carry,
      ),
      keepDealerOnCarry: json['keepDealerOnCarry'] as bool? ?? true,
    );
  }
}

class SideState {
  const SideState({
    required this.name,
    this.score = 0,
    this.bolts = 0,
  });

  final String name;
  final int score;
  final int bolts;

  SideState copyWith({String? name, int? score, int? bolts}) {
    return SideState(
      name: name ?? this.name,
      score: score ?? this.score,
      bolts: bolts ?? this.bolts,
    );
  }

  Map<String, Object> toJson() => {
        'name': name,
        'score': score,
        'bolts': bolts,
      };

  factory SideState.fromJson(Map<String, dynamic> json) {
    return SideState(
      name: json['name'] as String,
      score: json['score'] as int? ?? 0,
      bolts: json['bolts'] as int? ?? 0,
    );
  }
}

class DeclarationBonus {
  const DeclarationBonus(this.label, this.points);
  final String label;
  final int points;
}

const declarationBonuses = [
  DeclarationBonus('4× J', 200),
  DeclarationBonus('4× 9', 140),
  DeclarationBonus('4× A', 110),
  DeclarationBonus('4× 10', 100),
  DeclarationBonus('4× K', 40),
  DeclarationBonus('4× Q', 30),
];

class RoundEntry {
  const RoundEntry({
    required this.pool,
    required this.rawPoints,
    required this.deltas,
    required this.contractSide,
    required this.dealerSide,
    this.contractManuallySelected = false,
    required this.boltAdded,
    required this.carriedBefore,
    required this.carriedAfter,
    required this.createdAt,
  });

  final int pool;
  final List<int> rawPoints;
  final List<int> deltas;
  final int contractSide;
  final int dealerSide;
  final bool contractManuallySelected;
  final bool boltAdded;
  final int carriedBefore;
  final int carriedAfter;
  final DateTime createdAt;

  Map<String, Object> toJson() => {
        'pool': pool,
        'rawPoints': rawPoints,
        'deltas': deltas,
        'contractSide': contractSide,
        'dealerSide': dealerSide,
        'contractManuallySelected': contractManuallySelected,
        'boltAdded': boltAdded,
        'carriedBefore': carriedBefore,
        'carriedAfter': carriedAfter,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RoundEntry.fromJson(Map<String, dynamic> json) {
    return RoundEntry(
      pool: json['pool'] as int,
      rawPoints: List<int>.from(json['rawPoints'] as List),
      deltas: List<int>.from(json['deltas'] as List),
      contractSide: json['contractSide'] as int,
      dealerSide: json['dealerSide'] as int,
      contractManuallySelected:
          json['contractManuallySelected'] as bool? ?? false,
      boltAdded: json['boltAdded'] as bool? ?? false,
      carriedBefore: json['carriedBefore'] as int? ?? 0,
      carriedAfter: json['carriedAfter'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class MatchState {
  const MatchState({
    required this.mode,
    required this.rules,
    required this.sides,
    required this.rounds,
    this.dealerSide = 0,
    this.carriedPool = 0,
    this.winnerSide,
  });

  final MatchMode mode;
  final MatchRules rules;
  final List<SideState> sides;
  final List<RoundEntry> rounds;
  final int dealerSide;
  final int carriedPool;
  final int? winnerSide;

  MatchState copyWith({
    List<SideState>? sides,
    List<RoundEntry>? rounds,
    int? dealerSide,
    int? carriedPool,
    int? winnerSide,
    bool clearWinner = false,
  }) {
    return MatchState(
      mode: mode,
      rules: rules,
      sides: sides ?? this.sides,
      rounds: rounds ?? this.rounds,
      dealerSide: dealerSide ?? this.dealerSide,
      carriedPool: carriedPool ?? this.carriedPool,
      winnerSide: clearWinner ? null : winnerSide ?? this.winnerSide,
    );
  }

  Map<String, Object?> toJson() => {
        'mode': mode.name,
        'rules': rules.toJson(),
        'sides': sides.map((side) => side.toJson()).toList(),
        'rounds': rounds.map((round) => round.toJson()).toList(),
        'dealerSide': dealerSide,
        'carriedPool': carriedPool,
        'winnerSide': winnerSide,
      };

  factory MatchState.fromJson(Map<String, dynamic> json) {
    return MatchState(
      mode: MatchMode.values.byName(json['mode'] as String),
      rules: MatchRules.fromJson(json['rules'] as Map<String, dynamic>),
      sides: (json['sides'] as List)
          .map((item) => SideState.fromJson(item as Map<String, dynamic>))
          .toList(),
      rounds: (json['rounds'] as List)
          .map((item) => RoundEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      dealerSide: json['dealerSide'] as int? ?? 0,
      carriedPool: json['carriedPool'] as int? ?? 0,
      winnerSide: json['winnerSide'] as int?,
    );
  }
}
