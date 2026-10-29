import 'package:go_router/go_router.dart';

import 'core/permissions.dart';
import 'models/role.dart';
import 'screens/author_detail_screen.dart';
import 'screens/author_form_screen.dart';
import 'screens/author_list_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/book_list_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/genre_detail_screen.dart';
import 'screens/genre_form_screen.dart';
import 'screens/genre_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/loan_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/publisher_detail_screen.dart';
import 'screens/publisher_form_screen.dart';
import 'screens/publisher_list_screen.dart';
import 'screens/reader_detail_screen.dart';
import 'screens/reader_form_screen.dart';
import 'screens/reader_list_screen.dart';
import 'screens/register_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/users_screen.dart';
import 'state/auth_notifier.dart';

GoRouter buildRouter(AuthNotifier auth) {
  String? requireRole(Role minimum) => auth.has(minimum) ? null : '/forbidden';

  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (loggedIn && isPublic) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/books',
        builder: (context, state) => const BookListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            redirect: (c, s) =>
                Permissions.canManageCatalog(auth.role) ? null : '/forbidden',
            builder: (context, state) => const BookFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            redirect: (c, s) =>
                Permissions.canManageCatalog(auth.role) ? null : '/forbidden',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              return BookFormScreen(id: id);
            },
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? -1;
              return BookDetailScreen(bookId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/authors',
        builder: (context, state) => const AuthorListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            redirect: (c, s) =>
                Permissions.canManageCatalog(auth.role) ? null : '/forbidden',
            builder: (context, state) => const AuthorFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            redirect: (c, s) =>
                Permissions.canManageCatalog(auth.role) ? null : '/forbidden',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              return AuthorFormScreen(id: id);
            },
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? -1;
              return AuthorDetailScreen(authorId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/genres',
        builder: (context, state) => const GenreListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            redirect: (c, s) =>
                Permissions.canManageCatalog(auth.role) ? null : '/forbidden',
            builder: (context, state) => const GenreFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            redirect: (c, s) =>
                Permissions.canManageCatalog(auth.role) ? null : '/forbidden',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              return GenreFormScreen(id: id);
            },
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? -1;
              return GenreDetailScreen(genreId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/publishers',
        builder: (context, state) => const PublisherListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            redirect: (c, s) =>
                Permissions.canManageCatalog(auth.role) ? null : '/forbidden',
            builder: (context, state) => const PublisherFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            redirect: (c, s) =>
                Permissions.canManageCatalog(auth.role) ? null : '/forbidden',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              return PublisherFormScreen(id: id);
            },
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? -1;
              return PublisherDetailScreen(publisherId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/readers',
        redirect: (c, s) => requireRole(Role.librarian),
        builder: (context, state) => const ReaderListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ReaderFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              return ReaderFormScreen(id: id);
            },
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? -1;
              return ReaderDetailScreen(readerId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/loans',
        builder: (context, state) => const LoanListScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        redirect: (c, s) => requireRole(Role.admin),
        builder: (context, state) => const UsersScreen(),
      ),
      GoRoute(
        path: '/admin/stats',
        redirect: (c, s) => requireRole(Role.admin),
        builder: (context, state) => const StatsScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
}
