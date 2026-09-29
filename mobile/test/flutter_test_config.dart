import 'dart:async';

import 'package:finny_pet/widgets/pet_model.dart';

/// Общая настройка всех тестов: живые ролики питомца выключаем,
/// иначе `pumpAndSettle` не дождётся конца анимации.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PetModel.liveVideo = false;
  await testMain();
}
