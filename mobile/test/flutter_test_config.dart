import 'dart:async';

import 'package:finny_pet/widgets/pet_model.dart';

/// Общая настройка всех тестов: бесконечное «дыхание» питомца выключаем,
/// иначе `pumpAndSettle` не дождётся конца анимации.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PetModel.idleMotion = false;
  await testMain();
}
