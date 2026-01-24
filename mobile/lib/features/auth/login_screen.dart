import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/errors/app_error.dart';
// Server selection removed for production
import 'login_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isFormValid = false;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  bool _submittedOnce = false;

  
  @override
  void initState() {
    super.initState();

    void listen() => _recomputeFormValidity();

    _identifierController.addListener(listen);
    _passwordController.addListener(listen);

    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputeFormValidity());
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();

    _identifierFocus.dispose();
    _passwordFocus.dispose();

    super.dispose();
  }

  void _recomputeFormValidity() {
    // Do not trigger Form validators until user tried to submit at least once.
    // Otherwise fields show "required" errors immediately on first render.
    final isValid = _submittedOnce
        ? (_formKey.currentState?.validate() ?? _validateLocally())
        : _validateLocally();

    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  bool _validateLocally() {
    return _validateIdentifier(_identifierController.text) == null &&
        _validatePassword(_passwordController.text) == null;
  }

  String? _validateIdentifier(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Обязательное поле';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Обязательное поле';
    if (v.length < 6) return 'Минимум 6 символов';
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _submittedOnce = true;
      _autoValidateMode = AutovalidateMode.onUserInteraction;
    });

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      _recomputeFormValidity();
      return;
    }

    final controller = ref.read(loginControllerProvider.notifier);

    try {
      await controller.login(
        LoginRequest(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (!mounted) return;
      FocusScope.of(context).unfocus();

      // Do not force a route here.
      // After token+me are loaded, GoRouter redirect will deterministically
      // send the user to /church, /tasks or /superadmin.
      context.go(AppRoutes.splash);
    } on AppError catch (e) {
      if (!mounted) return;
      final message = (e.message.isNotEmpty)
          ? e.message
          : 'Ошибка сети. Проверь подключение и адрес сервера.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка сети. Проверь подключение и адрес сервера.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;

    final canSubmit = _isFormValid && !isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Вход',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Введи email или логин и пароль',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    autovalidateMode: _autoValidateMode,
                    onChanged: _recomputeFormValidity,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _identifierController,
                          focusNode: _identifierFocus,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email или логин',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateIdentifier,
                          enabled: !isLoading,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_passwordFocus),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          textInputAction: TextInputAction.done,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Пароль',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validatePassword,
                          enabled: !isLoading,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: canSubmit ? _submit : null,
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Войти'),
                          ),
                        ),
                        const SizedBox(height: 12),
                                                Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Нет аккаунта?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.go(AppRoutes.register),
                              child: const Text('ЗАРЕГИСТРИРОВАТЬСЯ'),
                            ),
                          ],
                        ),
                      ],
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
