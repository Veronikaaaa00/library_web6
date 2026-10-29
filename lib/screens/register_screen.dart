import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../state/auth_notifier.dart';
import '../validation/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _saving = false;
  String? _error;
  String? _passwordHint;

  @override
  void initState() {
    super.initState();
    _password.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() => _passwordHint = _passwordStrength(_password.text));
  }

  String? _passwordStrength(String value) {
    if (value.isEmpty) return null;
    final issues = <String>[];
    if (value.length < 8) issues.add('минимум 8 символов');
    if (!RegExp(r'\d').hasMatch(value)) issues.add('нужна цифра');
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\;/]').hasMatch(value)) {
      issues.add('нужен спецсимвол');
    }
    if (issues.isEmpty) return 'Пароль подходит';
    return 'Ещё: ${issues.join(', ')}';
  }

  String? _passwordValidator(String? value) {
    final base = Validators.required(value, label: 'Пароль');
    if (base != null) return base;
    final v = value!;
    if (v.length < 8) return 'Минимум 8 символов';
    if (!RegExp(r'\d').hasMatch(v)) return 'Добавьте хотя бы одну цифру';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\;/]').hasMatch(v)) {
      return 'Добавьте специальный символ';
    }
    return null;
  }

  @override
  void dispose() {
    _password.removeListener(_onPasswordChanged);
    _username.dispose();
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthNotifier>().register(
        username: _username.text.trim(),
        password: _password.text,
        email: _email.text.trim(),
        fullName: _fullName.text.trim(),
      );
      if (!mounted) return;
      context.go('/');
    } on ValidationException catch (e) {
      setState(
        () => _error = e.errors.values.join('; ').isEmpty
            ? e.message
            : e.errors.values.join('; '),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Ошибка регистрации: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hintColor = _passwordHint == 'Пароль подходит'
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.error;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      'Регистрация',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(
                        labelText: 'Логин',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => Validators.compose([
                        (x) => Validators.required(x, label: 'Логин'),
                        (x) => Validators.minLength(x, 3, label: 'Логин'),
                      ])(v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fullName,
                      decoration: const InputDecoration(
                        labelText: 'ФИО',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => Validators.required(v, label: 'ФИО'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        border: const OutlineInputBorder(),
                        helperText: _passwordHint,
                        helperStyle: TextStyle(color: hintColor),
                      ),
                      validator: _passwordValidator,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Зарегистрироваться'),
                    ),
                    TextButton(
                      onPressed: _saving ? null : () => context.go('/login'),
                      child: const Text('Уже есть аккаунт'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
