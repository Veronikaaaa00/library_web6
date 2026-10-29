import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/author_list_notifier.dart';
import '../state/book_list_notifier.dart';
import '../state/genre_list_notifier.dart';
import '../state/network_status.dart';
import '../state/publisher_list_notifier.dart';
import '../state/reader_list_notifier.dart';

/// Баннер при потере связи: понятное сообщение и повтор без F5.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  Future<void> _retry(BuildContext context) async {
    final net = context.read<NetworkStatus>();
    net.markOnline();
    await Future.wait([
      context.read<BookListNotifier>().load(),
      context.read<AuthorListNotifier>().load(),
      context.read<GenreListNotifier>().load(),
      context.read<PublisherListNotifier>().load(),
      context.read<ReaderListNotifier>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final net = context.watch<NetworkStatus>();
    return SizedBox.expand(
      child: Column(
        children: [
          if (!net.isOnline)
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          net.message.isEmpty
                              ? 'Нет соединения с сервером'
                              : net.message,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _retry(context),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
