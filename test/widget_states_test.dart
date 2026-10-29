import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/core/permissions.dart';
import 'package:library_web/models/role.dart';
import 'package:library_web/state/load_status.dart';
import 'package:library_web/validation/validators.dart';
import 'package:library_web/widgets/load_state_body.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('показывает индикатор загрузки', (tester) async {
    await tester.pumpWidget(
      wrap(
        LoadStateBody(
          status: LoadStatus.loading,
          isEmpty: true,
          error: null,
          onRetry: () {},
          child: const Text('данные'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('данные'), findsNothing);
  });

  testWidgets('показывает сообщение при пустом результате', (tester) async {
    await tester.pumpWidget(
      wrap(
        LoadStateBody(
          status: LoadStatus.success,
          isEmpty: true,
          error: null,
          onRetry: () {},
          emptyTitle: 'Книг не найдено',
          child: const Text('данные'),
        ),
      ),
    );
    expect(find.text('Книг не найдено'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('ошибка с кнопкой повтора', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      wrap(
        LoadStateBody(
          status: LoadStatus.error,
          isEmpty: true,
          error: 'Сервер недоступен',
          onRetry: () => retried = true,
          child: const Text('данные'),
        ),
      ),
    );
    expect(find.text('Ошибка загрузки'), findsOneWidget);
    expect(find.text('Сервер недоступен'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    expect(retried, isTrue);
  });

  testWidgets('форма не проходит валидацию с пустым названием', (tester) async {
    final key = GlobalKey<FormState>();
    await tester.pumpWidget(
      wrap(
        Form(
          key: key,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (v) => Validators.required(v, label: 'Название'),
              ),
              FilledButton(
                onPressed: () => key.currentState?.validate(),
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    expect(find.text('Название обязательно'), findsOneWidget);
  });

  testWidgets('скрывает кнопку админа при роли читателя', (tester) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            final canManage = Permissions.canManageUsers(Role.reader);
            return Column(
              children: [
                const Text('Каталог'),
                if (canManage)
                  FilledButton(
                    onPressed: () {},
                    child: const Text('Пользователи'),
                  ),
              ],
            );
          },
        ),
      ),
    );
    expect(find.text('Каталог'), findsOneWidget);
    expect(find.text('Пользователи'), findsNothing);

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            final canManage = Permissions.canManageUsers(Role.admin);
            return Column(
              children: [
                const Text('Каталог'),
                if (canManage)
                  FilledButton(
                    onPressed: () {},
                    child: const Text('Пользователи'),
                  ),
              ],
            );
          },
        ),
      ),
    );
    expect(find.text('Пользователи'), findsOneWidget);
  });
}
