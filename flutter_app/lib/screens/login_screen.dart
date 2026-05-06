import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../data/residence_options.dart';
import '../models/app_models.dart';
import '../widgets/app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const bool _useMockLogin =
      bool.fromEnvironment('USE_MOCK_LOGIN', defaultValue: true);

  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();

  final _signUpNameController = TextEditingController();
  final _signUpLoginIdController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpPhoneController = TextEditingController();

  String? _selectedProvince;
  String? _selectedCity;

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    _signUpNameController.dispose();
    _signUpLoginIdController.dispose();
    _signUpPasswordController.dispose();
    _signUpPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final cities = _selectedProvince == null
        ? const <String>[]
        : residenceOptions[_selectedProvince] ?? const <String>[];

    return AppShell(
      title: '로그인',
      modeName: controller.modeName,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '여행 신청부터 정산 준비까지\n한 번에 관리하는 반값여행 앱',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '이제 카카오/구글 대신 아이디와 비밀번호로 바로 시작할 수 있어요.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  if (_useMockLogin) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '빠르게 둘러보기',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '배포 환경에서는 처음 로그인 전에 회원가입이 필요합니다. 바로 체험하려면 게스트 로그인을 사용해 주세요.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF64748B),
                                ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: controller.isBusy
                                ? null
                                : () => _handleMockLogin(context),
                            child: const Text('게스트로 바로 시작하기'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const TabBar(
                          tabs: [
                            Tab(text: '로그인'),
                            Tab(text: '회원가입'),
                          ],
                        ),
                        SizedBox(
                          height: 430,
                          child: TabBarView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _TextFieldCard(
                                      controller: _loginIdController,
                                      label: '아이디',
                                      hintText: '로그인 아이디를 입력해 주세요',
                                    ),
                                    const SizedBox(height: 14),
                                    _TextFieldCard(
                                      controller: _passwordController,
                                      label: '비밀번호',
                                      hintText: '비밀번호를 입력해 주세요',
                                      obscureText: true,
                                    ),
                                    const Spacer(),
                                    FilledButton(
                                      onPressed: controller.isBusy
                                          ? null
                                          : () => _handleLogin(context),
                                      child: const Text('로그인'),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: ListView(
                                  children: [
                                    _TextFieldCard(
                                      controller: _signUpNameController,
                                      label: '이름',
                                      hintText: '이름을 입력해 주세요',
                                    ),
                                    const SizedBox(height: 14),
                                    _TextFieldCard(
                                      controller: _signUpLoginIdController,
                                      label: '아이디',
                                      hintText: '사용할 아이디를 입력해 주세요',
                                    ),
                                    const SizedBox(height: 14),
                                    _TextFieldCard(
                                      controller: _signUpPasswordController,
                                      label: '비밀번호',
                                      hintText: '4자 이상 입력해 주세요',
                                      obscureText: true,
                                    ),
                                    const SizedBox(height: 14),
                                    _TextFieldCard(
                                      controller: _signUpPhoneController,
                                      label: '전화번호',
                                      hintText: '010-0000-0000',
                                    ),
                                    const SizedBox(height: 14),
                                    _DropdownCard<String>(
                                      label: '광역시/도',
                                      value: _selectedProvince,
                                      items: residenceOptions.keys.toList(),
                                      hintText: '거주 광역시/도를 선택해 주세요',
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedProvince = value;
                                          _selectedCity = null;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    _DropdownCard<String>(
                                      label: '시/군/구',
                                      value: _selectedCity,
                                      items: cities,
                                      hintText: '거주 시/군/구를 선택해 주세요',
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCity = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    FilledButton(
                                      onPressed: controller.isBusy
                                          ? null
                                          : () => _handleSignUp(context),
                                      child: const Text('회원가입 후 시작하기'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (controller.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (controller.isBusy) ...[
                    const SizedBox(height: 18),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMockLogin(BuildContext context) async {
    final controller = AppScope.of(context);
    try {
      await controller.login(LoginProvider.guest);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게스트 로그인에 실패했습니다. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _handleLogin(BuildContext context) async {
    final controller = AppScope.of(context);
    try {
      await controller.loginWithCredentials(
        loginId: _loginIdController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인에 실패했습니다. 입력한 정보를 확인해 주세요.')),
      );
    }
  }

  Future<void> _handleSignUp(BuildContext context) async {
    if (_selectedProvince == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('거주 지역을 모두 선택해 주세요.')),
      );
      return;
    }

    final controller = AppScope.of(context);
    final residence = '$_selectedProvince $_selectedCity';

    try {
      await controller.signUpWithCredentials(
        name: _signUpNameController.text.trim(),
        loginId: _signUpLoginIdController.text.trim(),
        password: _signUpPasswordController.text.trim(),
        phoneNumber: _signUpPhoneController.text.trim(),
        residence: residence,
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입에 실패했습니다. 입력 내용을 다시 확인해 주세요.')),
      );
    }
  }
}

class _TextFieldCard extends StatelessWidget {
  const _TextFieldCard({
    required this.controller,
    required this.label,
    required this.hintText,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF16A34A)),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownCard<T> extends StatelessWidget {
  const _DropdownCard({
    required this.label,
    required this.value,
    required this.items,
    required this.hintText,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String hintText;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF16A34A)),
            ),
          ),
        ),
      ],
    );
  }
}
