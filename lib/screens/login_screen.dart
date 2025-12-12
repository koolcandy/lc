import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../utils/sso_login.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // 方便测试，这里可以预填一些逻辑，或者从本地读取上次记住的账号
  @override
  void initState() {
    super.initState();
    _loadSavedUsername();
  }

  Future<void> _loadSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('saved_username');
    if (savedUser != null) {
      _usernameController.text = savedUser;
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      // 1. 调用我们刚才写的工具类
      final ssoUtil = SsoLoginUtil();
      final token = await ssoUtil.loginAndGetToken(username, password);

      if (!mounted) return;

      // 2. 登录成功，保存 Token
      await context.read<AuthProvider>().setToken(token);

      // 3. 记住账号方便下次登录
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', username);

      // 4. 跳转回首页
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登录成功'), backgroundColor: Colors.green),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('统一身份认证')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo 或 标题
                  const Icon(
                    Icons.school,
                    size: 64,
                    color: Color(0xFFC8102E),
                  ), // 福大红
                  const SizedBox(height: 8),
                  const Text(
                    '福州大学 SSO',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // 账号输入框
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: '学号',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return '请输入学号';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 密码输入框
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: '密码',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return '请输入密码';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // 登录按钮
                  FilledButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('登录', style: TextStyle(fontSize: 16)),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    '提示：本应用通过原生请求直接模拟登录流程，不会保存您的密码。',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
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
