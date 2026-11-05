import 'package:flutter/material.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/utils/validators.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final BusinessController controller;

  const LoginScreen({super.key, required this.controller});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await widget.controller.loginUser(
      identifier: _identifierCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    setState(() => _isLoading = false);

    if (error == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('👋 Xin chào ${widget.controller.currentUser?.fullName ?? "bạn"}! Đăng nhập thành công.'),
          backgroundColor: const Color(0xFF0F766E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = widget.controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Nhập Tài Khoản'),
        actions: [
          PopupMenuButton<ThemeMode>(
            tooltip: 'Giao diện Sáng / Tối',
            icon: Icon(
              ctrl.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : (ctrl.themeMode == ThemeMode.light ? Icons.light_mode : Icons.brightness_auto),
            ),
            onSelected: (mode) => ctrl.setThemeMode(mode),
            itemBuilder: (context) => const [
              PopupMenuItem(value: ThemeMode.system, child: Text('🌓 Theo hệ thống')),
              PopupMenuItem(value: ThemeMode.light, child: Text('☀️ Chế độ sáng')),
              PopupMenuItem(value: ThemeMode.dark, child: Text('🌙 Chế độ tối')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding Logo
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2F1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        size: 42,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Center(
                    child: Text(
                      'Sổ Tay Hộ Kinh Doanh',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F766E),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  Center(
                    child: Text(
                      'Bảo mật dữ liệu bán hàng, sổ nợ hộ gia đình & dòng tiền',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Ô nhập SĐT / Email
                  TextFormField(
                    controller: _identifierCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại hoặc Email / Gmail *',
                      hintText: 'VD: 0987654321 hoặc ten@gmail.com',
                      prefixIcon: Icon(Icons.account_circle_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (v) => Validators.required(v, 'Vui lòng nhập SĐT hoặc Email'),
                  ),
                  const SizedBox(height: 14),

                  // Mật khẩu
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu *',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (v) => Validators.required(v, 'Vui lòng nhập mật khẩu'),
                  ),
                  const SizedBox(height: 8),

                  // Ghi nhớ & Quên mật khẩu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? true),
                          ),
                          const Text('Ghi nhớ đăng nhập', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(
                                controller: widget.controller,
                                initialIdentifier: _identifierCtrl.text.trim(),
                              ),
                            ),
                          );
                        },
                        child: const Text('Quên mật khẩu?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nút Đăng nhập
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _handleLogin,
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.login),
                      label: Text(_isLoading ? 'Đang xác thực...' : 'Đăng Nhập', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Chưa có tài khoản?',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                      ),
                      Expanded(child: Divider(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nút Tạo tài khoản mới
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegisterScreen(controller: widget.controller),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_outlined, color: Color(0xFF0F766E)),
                      label: const Text(
                        'Đăng Ký Tài Khoản Mới',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                      ),
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
