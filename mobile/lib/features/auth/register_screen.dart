import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/errors/app_error.dart';
import 'auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _ageFocus = FocusNode();
  final _cityFocus = FocusNode();

  bool _isFormValid = false;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  @override
  void initState() {
    super.initState();

    void listen() => _recomputeFormValidity();

    _emailController.addListener(listen);
    _passwordController.addListener(listen);
    _firstNameController.addListener(listen);
    _lastNameController.addListener(listen);
    _ageController.addListener(listen);
    _cityController.addListener(listen);

    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputeFormValidity());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _cityController.dispose();

    _emailFocus.dispose();
    _passwordFocus.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _ageFocus.dispose();
    _cityFocus.dispose();

    super.dispose();
  }

  void _recomputeFormValidity() {
    final isValid = _formKey.currentState?.validate() ?? _validateLocally();
    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  bool _validateLocally() {
    return _validateEmail(_emailController.text) == null &&
        _validatePassword(_passwordController.text) == null &&
        _validateNameLike(_firstNameController.text) == null &&
        _validateNameLike(_lastNameController.text) == null &&
        _validateAge(_ageController.text) == null &&
        _validateNameLike(_cityController.text) == null;
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Обязательное поле';
    if (!_emailRegex.hasMatch(v)) return 'Некорректный email';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Обязательное поле';
    if (v.length < 6) return 'Минимум 6 символов';
    return null;
  }

  String? _validateNameLike(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Обязательное поле';
    if (v.length < 2) return 'Минимум 2 символа';
    return null;
  }

  String? _validateAge(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Обязательное поле';
    final age = int.tryParse(v);
    if (age == null) return 'Введите число';
    if (age < 6 || age > 30) return 'Возраст: 6–30';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      _recomputeFormValidity();
      return;
    }

    final controller = ref.read(registerControllerProvider.notifier);

    try {
      await controller.register(
        RegisterRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          city: _cityController.text.trim(),
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
    final registerState = ref.watch(registerControllerProvider);
    final isLoading = registerState.isLoading;

    final canSubmit = _isFormValid && !isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
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
                    'Регистрация',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Заполни данные, чтобы начать',
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
                          controller: _emailController,
                          focusNode: _emailFocus,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateEmail,
                          enabled: !isLoading,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_passwordFocus),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          textInputAction: TextInputAction.next,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Пароль',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validatePassword,
                          enabled: !isLoading,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_firstNameFocus),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _firstNameController,
                          focusNode: _firstNameFocus,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Имя',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateNameLike,
                          enabled: !isLoading,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_lastNameFocus),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastNameController,
                          focusNode: _lastNameFocus,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Фамилия',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateNameLike,
                          enabled: !isLoading,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_ageFocus),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ageController,
                          focusNode: _ageFocus,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Возраст',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateAge,
                          enabled: !isLoading,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_cityFocus),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cityController,
                          focusNode: _cityFocus,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Город',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateNameLike,
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
                                : const Text('Продолжить'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Уже зарегистрированы?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.go(AppRoutes.login),
                              child: const Text('ВОЙТИ'),
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
