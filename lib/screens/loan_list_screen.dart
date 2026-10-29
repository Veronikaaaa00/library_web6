import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/permissions.dart';
import '../models/loan.dart';
import '../models/role.dart';
import '../repositories/loan_repository.dart';
import '../state/auth_notifier.dart';
import '../widgets/app_scaffold.dart';

class LoanListScreen extends StatefulWidget {
  const LoanListScreen({super.key});

  @override
  State<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends State<LoanListScreen> {
  late Future<List<Loan>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Loan>> _load() async {
    final auth = context.read<AuthNotifier>();
    final repo = context.read<LoanRepository>();
    final page = await repo.find(
      size: 50,
      readerId: auth.role == Role.reader ? auth.user?.readerId : null,
    );
    return page.items;
  }

  Future<void> _renew(Loan loan) async {
    try {
      await context.read<LoanRepository>().renewLoan(loan.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Срок выдачи продлён на 14 дней')),
      );
      setState(() => _future = _load());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _return(Loan loan) async {
    try {
      await context.read<LoanRepository>().returnLoan(loan.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Выдача закрыта')));
      setState(() => _future = _load());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final canManage = Permissions.canManageLoans(auth.role);

    return AppScaffold(
      title: auth.role == Role.reader ? 'Мои выдачи' : 'Выдачи',
      body: FutureBuilder<List<Loan>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('Выдач нет'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final loan = items[index];
              return ListTile(
                title: Text(loan.bookTitle ?? 'Книга #${loan.bookId}'),
                subtitle: Text(
                  '${loan.readerName ?? 'Читатель'} · '
                  'до ${_fmt(loan.dueAt)} · ${loan.status}',
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    if (loan.isActive && Permissions.canRenewOwnLoan(auth.role))
                      TextButton(
                        onPressed: () => _renew(loan),
                        child: const Text('Продлить'),
                      ),
                    if (loan.isActive && canManage)
                      TextButton(
                        onPressed: () => _return(loan),
                        child: const Text('Вернуть'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
