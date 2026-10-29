import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/catalog_cache.dart';
import '../models/author.dart';
import '../repositories/author_repository.dart';
import '../state/author_list_notifier.dart';
import '../utils/form_api_errors.dart';
import '../validation/validators.dart';
import '../widgets/entity_form_scaffold.dart';

class AuthorFormScreen extends StatefulWidget {
  const AuthorFormScreen({super.key, this.id});

  final int? id;
  bool get isEditing => id != null;

  @override
  State<AuthorFormScreen> createState() => _AuthorFormScreenState();
}

class _AuthorFormScreenState extends State<AuthorFormScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _country = TextEditingController();
  final _birthYear = TextEditingController();
  final _bio = TextEditingController();
  Author? _existing;
  var _loading = true;
  final Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.isEditing) {
      _existing = await context.read<AuthorRepository>().findById(widget.id!);
      final a = _existing;
      if (a != null) {
        _firstName.text = a.firstName;
        _lastName.text = a.lastName;
        _country.text = a.country;
        _birthYear.text = '${a.birthYear}';
        _bio.text = a.bio ?? '';
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _save() async {
    setState(() => _serverErrors.clear());
    final repo = context.read<AuthorRepository>();
    final draft = Author(
      id: widget.id ?? 0,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      country: _country.text.trim(),
      birthYear: int.parse(_birthYear.text.trim()),
      bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
      deletedAt: _existing?.deletedAt,
    );
    try {
      if (widget.isEditing) {
        await repo.update(draft);
      } else {
        await repo.create(draft);
      }
    } catch (e) {
      if (!mounted) return false;
      return handleFormApiError(
        context,
        error: e,
        onValidation: (errors) => setState(() {
          _serverErrors
            ..clear()
            ..addAll(errors);
        }),
      );
    }
    if (!mounted) return false;
    context.read<CatalogCache>().invalidate();
    await context.read<AuthorListNotifier>().load();
    if (!mounted) return false;
    context.go('/authors');
    return true;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _country.dispose();
    _birthYear.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return EntityFormScaffold(
        title: widget.isEditing ? 'Изменить автора' : 'Новый автор',
        fields: const [],
        isLoading: true,
        onSubmit: () async => false,
      );
    }
    if (widget.isEditing && _existing == null) {
      return EntityFormScaffold(
        title: 'Автор не найден',
        fields: [
          FilledButton(
            onPressed: () => context.go('/authors'),
            child: const Text('К списку'),
          ),
        ],
        onSubmit: () async => false,
      );
    }

    return EntityFormScaffold(
      title: widget.isEditing ? 'Изменить автора' : 'Новый автор',
      submitLabel: widget.isEditing ? 'Сохранить' : 'Создать',
      onSubmit: _save,
      fields: [
        TextFormField(
          controller: _lastName,
          decoration: InputDecoration(
            labelText: 'Фамилия',
            border: const OutlineInputBorder(),
            errorText: _serverErrors['fullName'],
          ),
          validator: Validators.compose([
            (v) => _serverErrors['fullName'],
            (v) => Validators.required(v, label: 'Фамилия'),
            (v) => Validators.maxLength(v, 80, label: 'Фамилия'),
          ]),
        ),
        TextFormField(
          controller: _firstName,
          decoration: const InputDecoration(
            labelText: 'Имя',
            border: OutlineInputBorder(),
          ),
          validator: Validators.compose([
            (v) => Validators.required(v, label: 'Имя'),
            (v) => Validators.maxLength(v, 80, label: 'Имя'),
          ]),
        ),
        TextFormField(
          controller: _country,
          decoration: const InputDecoration(
            labelText: 'Страна',
            border: OutlineInputBorder(),
          ),
          validator: Validators.compose([
            (v) => Validators.required(v, label: 'Страна'),
            (v) => Validators.maxLength(v, 80, label: 'Страна'),
          ]),
        ),
        TextFormField(
          controller: _birthYear,
          decoration: InputDecoration(
            labelText: 'Год рождения',
            border: const OutlineInputBorder(),
            errorText: _serverErrors['birthYear'],
          ),
          keyboardType: TextInputType.number,
          validator: (v) =>
              _serverErrors['birthYear'] ??
              Validators.year(v, min: 1, max: DateTime.now().year),
        ),
        TextFormField(
          controller: _bio,
          decoration: const InputDecoration(
            labelText: 'Биография',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          validator: (v) => Validators.maxLength(v, 2000, label: 'Биография'),
        ),
      ],
    );
  }
}
