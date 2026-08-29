import 'game_models.dart';

class AppStrings {
  AppStrings(this.language);
  final AppLanguage language;

  String t(String ru, String uk) => language == AppLanguage.ru ? ru : uk;

  String get appName => t('Клабор: Счёт', 'Клабор: Рахунок');
  String get newMatch => t('Новая партия', 'Нова партія');
  String get continueMatch => t('Продолжить', 'Продовжити');
  String get history => t('История', 'Історія');
  String get settings => t('Правила', 'Правила');
  String get chooseMode => t('Выбери режим', 'Обери режим');
  String get next => t('Далее', 'Далі');
  String get teams => t('Участники', 'Учасники');
  String get firstDealer => t('Первым сдаёт', 'Першим здає');
  String get target => t('Счёт для победы', 'Рахунок для перемоги');
  String get start => t('Начать игру', 'Почати гру');
  String get addRound => t('Добавить раздачу', 'Додати роздачу');
  String get totalPool => t('Сумма раздачи', 'Сума роздачі');
  String get manualPool =>
      t('Ввести итоговую сумму вручную', 'Ввести підсумкову суму вручну');
  String get declarations => t('Объявления', 'Оголошення');
  String get customBonus => t('Свой бонус', 'Власний бонус');
  String get playingSide => t('Играющая сторона', 'Сторона, що грає');
  String get points => t('Очки', 'Очки');
  String get save => t('Записать', 'Записати');
  String get cancel => t('Отмена', 'Скасувати');
  String get dealer => t('Сдаёт', 'Здає');
  String get plays => t('Играет', 'Грає');
  String get bolts => t('Болты', 'Болти');
  String get boltPenaltyRule => t(
        'Третий и каждый последующий болт отнимает 100 очков.',
        'Третій і кожен наступний болт віднімає 100 очок.',
      );
  String boltPenaltySummary(int boltCount, int penalty) =>
      '${_boltCountLabel(boltCount)} · −$penalty';
  String get hanging => t('Висячка', 'Висячка');
  String get winner => t('Победитель', 'Переможець');
  String get finish => t('Завершить', 'Завершити');
  String get spare => t('Пощадить', 'Пощадити');
  String get noSpare => t('Не щадить', 'Не щадити');
  String get zeroPrompt => t(
        'У играющей стороны 0 очков и уже 3 болта.',
        'У сторони, що грає, 0 очок і вже 3 болти.',
      );
  String get emptyHistory => t('Раздач пока нет', 'Роздач поки немає');

  String _boltCountLabel(int count) {
    final lastTwo = count % 100;
    final last = count % 10;
    if (language == AppLanguage.ru) {
      if (last == 1 && lastTwo != 11) return '$count болт';
      if (last >= 2 && last <= 4 && (lastTwo < 12 || lastTwo > 14)) {
        return '$count болта';
      }
      return '$count болтов';
    }
    if (last == 1 && lastTwo != 11) return '$count болт';
    if (last >= 2 && last <= 4 && (lastTwo < 12 || lastTwo > 14)) {
      return '$count болти';
    }
    return '$count болтів';
  }
}
