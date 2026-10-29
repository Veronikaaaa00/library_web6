import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/validation/validators.dart';

void main() {
  group('обязательное поле', () {
    test('пустая строка отклоняется', () {
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
      expect(Validators.required(null), isNotNull);
    });

    test('непустая строка принимается', () {
      expect(Validators.required('Война и мир'), isNull);
    });
  });

  group('email и isbn', () {
    test('email', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('bad'), isNotNull);
      expect(Validators.email('a@b.ru'), isNull);
    });

    test('isbn', () {
      expect(Validators.isbn('9785170901231'), isNull);
      expect(Validators.isbn('123'), isNotNull);
    });
  });

  group('числа и год', () {
    test('положительные числа', () {
      expect(Validators.positiveInt('0', label: 'x'), isNotNull);
      expect(Validators.positiveInt('3', label: 'x'), isNull);
      expect(Validators.nonNegativeInt('0', label: 'x'), isNull);
    });

    test('год издания', () {
      expect(Validators.year(''), isNotNull);
      expect(Validators.year('1999'), isNull);
      expect(Validators.year('20'), isNotNull);
    });
  });

  test('compose останавливается на первой ошибке', () {
    final v = Validators.compose([
      (s) => Validators.required(s, label: 'Название'),
      (s) => Validators.minLength(s, 2, label: 'Название'),
    ]);
    expect(v(''), contains('обязательно'));
    expect(v('A'), contains('минимум'));
    expect(v('Ab'), isNull);
  });
}
