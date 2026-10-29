# library_web

Практическая работа 6: Адаптивная вёрстка, сборка, публикация и тестирование



## Запуск

```bash
flutter pub get
flutter run -d chrome --web-port=5556
```

## Примеры адресов

```text
/books?search=война&genreId=1&sort=year,desc&page=1&size=10
/authors?search=толстой&country=Россия&sort=lastName,asc&page=1
```

Для демонстрации состояния ошибки введите в поиск: `__error__`

## Проверки

```bash
flutter analyze
flutter test
flutter build web
```
