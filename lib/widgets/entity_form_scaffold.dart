import 'package:flutter/material.dart';

import 'app_scaffold.dart';

/// Общая оболочка формы: PopScope, отправка, единая разметка полей.
class EntityFormScaffold extends StatefulWidget {
  const EntityFormScaffold({
    super.key,
    required this.title,
    required this.fields,
    required this.onSubmit,
    this.submitLabel = 'Сохранить',
    this.isLoading = false,
  });

  final String title;
  final List<Widget> fields;
  final Future<bool> Function() onSubmit;
  final String submitLabel;
  final bool isLoading;

  @override
  State<EntityFormScaffold> createState() => _EntityFormScaffoldState();
}

class _EntityFormScaffoldState extends State<EntityFormScaffold> {
  final _formKey = GlobalKey<FormState>();
  var _dirty = false;
  var _saving = false;

  void markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final ok = await widget.onSubmit();
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _dirty = false;
    });
    // Повторная проверка — чтобы ошибки уникальности из onSubmit
    // попали в validator и отобразились под полем.
    if (!ok) {
      _formKey.currentState?.validate();
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(maxWidth: 420),
        title: const Text('Несохранённые изменения'),
        content: const Text(
          'Уйти с формы? Внесённые изменения будут потеряны.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Уйти'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || widget.isLoading;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmLeave();
        if (leave && context.mounted) {
          setState(() => _dirty = false);
          Navigator.of(context).maybePop();
        }
      },
      child: AppScaffold(
        title: widget.title,
        body: busy && widget.fields.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                onChanged: markDirty,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        ...widget.fields.map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: f,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: busy ? null : _submit,
                            icon: busy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(widget.submitLabel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
