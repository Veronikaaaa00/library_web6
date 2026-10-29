import 'package:flutter/widgets.dart';

abstract final class Breakpoints {
  /// Узкий экран: карточки вместо таблиц, нижняя навигация.
  static const narrow = 700.0;

  static bool isNarrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < narrow;

  static bool isWide(BuildContext context) => !isNarrow(context);
}
