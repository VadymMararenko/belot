import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_models.dart';
import 'score_engine.dart';

class MatchStore extends ChangeNotifier {
  MatchStore(this._preferences);

  static const _matchKey = 'active_match_v1';
  static const _languageKey = 'language_v1';

  final SharedPreferences _preferences;
  final _engine = const ScoreEngine();

  MatchState? activeMatch;
  AppLanguage language = AppLanguage.ru;

  bool get hasActiveMatch => activeMatch != null;

  Future<void> restore() async {
    language = AppLanguage.values.firstWhere(
      (value) => value.name == _preferences.getString(_languageKey),
      orElse: () => AppLanguage.ru,
    );
    final encoded = _preferences.getString(_matchKey);
    if (encoded != null) {
      activeMatch =
          MatchState.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
    }
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    language = value;
    await _preferences.setString(_languageKey, value.name);
    notifyListeners();
  }

  Future<void> createMatch({
    required MatchMode mode,
    required MatchRules rules,
    required List<String> names,
    required int dealerSide,
  }) async {
    if (names.length != mode.sides) {
      throw ArgumentError('Name count must match side count.');
    }
    if (dealerSide < 0 || dealerSide >= mode.sides) {
      throw RangeError.index(dealerSide, names, 'dealerSide');
    }
    activeMatch = MatchState(
      mode: mode,
      rules: rules,
      sides: names.map((name) => SideState(name: name)).toList(),
      rounds: const [],
      dealerSide: dealerSide,
    );
    await _persist();
    notifyListeners();
  }

  Future<RoundResult> addRound(RoundRequest request) async {
    final current = activeMatch;
    if (current == null) throw StateError('No active match.');
    final result = _engine.apply(current, request);
    activeMatch = result.state;
    await _persist();
    notifyListeners();
    return result;
  }

  Future<void> undoLastRound() async {
    final current = activeMatch;
    if (current == null || current.rounds.isEmpty) return;
    final removed = current.rounds.last;
    final restoredSides = <SideState>[];
    for (var i = 0; i < current.sides.length; i++) {
      final side = current.sides[i];
      restoredSides.add(
        side.copyWith(
          score: side.score - removed.deltas[i],
          bolts: removed.boltAdded && i == removed.contractSide
              ? side.bolts - 1
              : side.bolts,
        ),
      );
    }
    activeMatch = current.copyWith(
      sides: restoredSides,
      rounds: current.rounds.sublist(0, current.rounds.length - 1),
      dealerSide: removed.dealerSide,
      carriedPool: removed.carriedBefore,
      clearWinner: true,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> clearMatch() async {
    activeMatch = null;
    await _preferences.remove(_matchKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    final current = activeMatch;
    if (current != null) {
      await _preferences.setString(_matchKey, jsonEncode(current.toJson()));
    }
  }
}
