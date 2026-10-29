import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';

/// Применяет 422 к полям формы; 409 и прочие — через SnackBar.
/// Возвращает `false`, если сохранение не удалось.
Future<bool> handleFormApiError(
  BuildContext context, {
  required Object error,
  required void Function(Map<String, String> fieldErrors) onValidation,
}) async {
  if (error is ValidationException) {
    onValidation(error.errors);
    if (context.mounted && error.errors.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
    return false;
  }
  if (error is ConflictException) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
    return false;
  }
  if (error is ApiException) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
    return false;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Ошибка: $error')));
  }
  return false;
}
