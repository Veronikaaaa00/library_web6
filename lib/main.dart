import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/auth_token_store.dart';
import 'core/catalog_cache.dart';
import 'repositories/api_author_repository.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_publisher_repository.dart';
import 'repositories/api_reader_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/loan_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';
import 'repositories/user_repository.dart';
import 'router.dart';
import 'state/auth_notifier.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/network_status.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';
import 'widgets/inactivity_watcher.dart';
import 'widgets/offline_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  final tokens = AuthTokenStore();
  final network = NetworkStatus();

  AuthNotifier? authRef;
  final dio = buildDio(
    tokenStore: tokens,
    network: network,
    onRefresh: () async {
      final auth = authRef;
      if (auth == null) throw StateError('Auth not ready');
      await auth.refreshTokens();
    },
    onLogout: () async {
      await authRef?.logout();
    },
  );

  final authApi = AuthRepository(dio, tokens);
  final auth = AuthNotifier(prefs, authApi, tokens);
  authRef = auth;
  await auth.restore();

  final books = ApiBookRepository(dio);
  final authors = ApiAuthorRepository(dio);
  final genres = ApiGenreRepository(dio);
  final publishers = ApiPublisherRepository(dio);
  final readers = ApiReaderRepository(dio);
  final loans = LoanRepository(dio);
  final users = UserRepository(dio);
  final catalog = CatalogCache(
    authors: authors,
    genres: genres,
    publishers: publishers,
  );
  final router = buildRouter(auth);

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),
        Provider<AuthTokenStore>.value(value: tokens),
        ChangeNotifierProvider<NetworkStatus>.value(value: network),
        Provider<AuthRepository>.value(value: authApi),
        ChangeNotifierProvider<AuthNotifier>.value(value: auth),
        Provider<BookRepository>.value(value: books),
        Provider<AuthorRepository>.value(value: authors),
        Provider<GenreRepository>.value(value: genres),
        Provider<PublisherRepository>.value(value: publishers),
        Provider<ReaderRepository>.value(value: readers),
        Provider<LoanRepository>.value(value: loans),
        Provider<UserRepository>.value(value: users),
        Provider<CatalogCache>.value(value: catalog),
        ChangeNotifierProvider(create: (_) => BookListNotifier(books)..load()),
        ChangeNotifierProvider(
          create: (_) => AuthorListNotifier(authors)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => GenreListNotifier(genres)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => PublisherListNotifier(publishers)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReaderListNotifier(readers)..load(),
        ),
      ],
      child: LibraryApp(router: router),
    ),
  );
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    if (auth.isAuthenticated && auth.isSessionOverMaxDuration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AuthNotifier>().logout();
      });
    }

    return MaterialApp.router(
      title: 'Библиотека',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE91E8C)),
        useMaterial3: true,
      ),
      routerConfig: router,
      builder: (context, child) {
        final content = OfflineBanner(child: child ?? const SizedBox.shrink());
        if (!auth.isAuthenticated) {
          return content;
        }
        return InactivityWatcher(
          timeout: AuthNotifier.inactivityTimeout,
          warningBefore: AuthNotifier.inactivityWarning,
          onWarning: () {
            // Баннер с таймером рисует сам InactivityWatcher.
          },
          onTimeout: () {
            final messenger = ScaffoldMessenger.of(context);
            context.read<AuthNotifier>().logout().then((_) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Выход по неактивности')),
              );
            });
          },
          child: content,
        );
      },
    );
  }
}
