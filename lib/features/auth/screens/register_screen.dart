import 'package:flutter/material.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/utils/validators.dart';
import '../../navigation/main_navigation_shell.dart';

class RegisterScreen extends StatefulWidget {
  final BusinessController controller;

  const RegisterScreen({super.key, required this.controller});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _storeNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  String _recoveryChannel = 'sms';
  bool _obscurePassword = true;
  bool _obscureConfirmPass = true;
  bool _agreedToTerms = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _storeNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với Điều khoản sử dụng trước khi đăng ký!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await widget.controller.registerUser(
      fullName: _fullNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      storeName: _storeNameCtrl.text.trim(),
      recoveryChannel: _recoveryChannel,
    );

    setState(() => _isLoading = false);

    if (error == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Chào mừng ${_fullNameCtrl.text.trim()}! Đăng ký tài khoản thành công.'),
          backgroundColor: const Color(0xFF0F766E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainNavigationShell(controller: widget.controller),
        ),
        (route) => false,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Ký Tài Khoản'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 40,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Tạo Tài Khoản Hộ Kinh Doanh',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Khởi tạo tài khoản riêng để bảo vệ dữ liệu bán hàng & sổ nợ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
                const SizedBox(height: 24),

                // Họ tên
                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên chủ hộ kinh doanh *',
                    hintText: 'VD: Nguyễn Minh Quang',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => Validators.required(v, 'Vui lòng nhập họ và tên'),
                ),
                const SizedBox(height: 14),

                // Tên cửa hàng
                TextFormField(
                  controller: _storeNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên Cửa Hàng / Hộ Kinh Doanh *',
                    hintText: 'VD: Cửa Hàng Tạp Hóa Minh Quang',
                    prefixIcon: Icon(Icons.store),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => Validators.required(v, 'Vui lòng nhập tên cửa hàng'),
                ),
                const SizedBox(height: 14),

                // SĐT
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại đăng nhập & SMS *',
                    hintText: 'VD: 0987654321',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: Validators.requiredPhone,
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Hộp thư Gmail / Email *',
                    hintText: 'VD: quangmerino@gmail.com',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: Validators.requiredEmail,
                ),
                const SizedBox(height: 14),

                // Mật khẩu
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu bảo vệ *',
                    hintText: 'Tối thiểu 6 ký tự',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 14),

                // Xác nhận mật khẩu
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirmPass,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận lại mật khẩu *',
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                    ),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => Validators.confirmPassword(v, _passwordCtrl.text),
                ),
                const SizedBox(height: 16),

                // Kênh khôi phục ưu tiên
                const Text(
                  'Kênh nhận mã khôi phục khi quên mật khẩu:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: 'sms',
                      icon: Icon(Icons.sms_outlined, size: 16),
                      label: Text('SMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    ButtonSegment(
                      value: 'email',
                      icon: Icon(Icons.mail_outlined, size: 16),
                      label: Text('Gmail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    ButtonSegment(
                      value: 'whatsapp',
                      icon: Icon(Icons.chat_bubble_outline, size: 16),
                      label: Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    ButtonSegment(
                      value: 'facebook',
                      icon: Icon(Icons.facebook, size: 16),
                      label: Text('Facebook', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  selected: {_recoveryChannel},
                  onSelectionChanged: (v) => setState(() => _recoveryChannel = v.first),
                ),
                const SizedBox(height: 12),

                // Terms checkbox
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                  title: const Text(
                    'Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật dữ liệu của ứng dụng.',
                    style: TextStyle(fontSize: 12),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 16),

                // Register button
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _handleRegister,
                    icon: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.person_add),
                    label: Text(_isLoading ? 'Đang tạo tài khoản...' : 'Đăng Ký Tài Khoản'),
                  ),
                ),
                const SizedBox(height: 16),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Đã có tài khoản? ', style: TextStyle(fontSize: 13)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đăng nhập ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
