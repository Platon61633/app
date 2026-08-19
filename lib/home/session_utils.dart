import 'package:flutter/material.dart';

import '../auth/signin.dart';
import '../services/auth_service.dart';

/// Сессия истекла или недействительна: чистим сохранённые данные и
/// возвращаем пользователя на экран входа.
///
/// Используется везде, где ответ сервера может прийти с 401 (загрузка
/// заказов, отправка заказа из корзины).
Future<void> redirectToSignIn(BuildContext context) async {
  await AuthService.clear();
  if (!context.mounted) {
    return;
  }
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const SignInPage()),
    (route) => false,
  );
}
