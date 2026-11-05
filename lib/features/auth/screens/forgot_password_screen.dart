import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final BusinessController controller;
  final String? initialIdentifier;

  const ForgotPasswordScreen({
    super.key,
    required this.controller,
    this.initialIdentifier,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  final TextEditingController _identifierCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  int _currentStep = 1; // 1: Select Channel & Identifier, 2: Enter OTP, 3: New Password
  String _selectedChannel = 'sms'; // 'sms', 'email', 'whatsapp', 'facebook'
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

  // Countdown timer for resend OTP
  int _countdownSeconds = 60;
  Timer? _countdownTimer;

  // Recovery meta
  String? _simulatedOtp;
  String? _destinationInfo;

  @override
  void initState() {
    super.initState();
    if (widget.initialIdentifier != null && widget.initialIdentifier!.isNotEmpty) {
      _identifierCtrl.text = widget.initialIdentifier!;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _identifierCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownSeconds = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleSendRecoveryCode() async {
    if (!_step1FormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final res = await widget.controller.requestPasswordRecovery(
      identifier: _identifierCtrl.text.trim(),
      channel: _selectedChannel,
    );

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _simulatedOtp = res['otp'] as String;
        _destinationInfo = res['destination'] as String;
        _currentStep = 2;
      });
      _startCountdown();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'Có lỗi xảy ra, vui lòng thử lại!'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleVerifyOtp() {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đúng mã OTP gồm 6 chữ số!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isValid = widget.controller.verifyRecoveryOtp(
      identifier: _identifierCtrl.text.trim(),
      code: code,
    );

    if (isValid) {
      _countdownTimer?.cancel();
      setState(() => _currentStep = 3);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã OTP không chính xác hoặc đã hết hạn (5 phút)!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_step3FormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await widget.controller.resetPassword(
      identifier: _identifierCtrl.text.trim(),
      newPassword: _newPassCtrl.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Cập nhật mật khẩu mới thành công! Vui lòng đăng nhập lại.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi cập nhật mật khẩu!'),
          backgroundColor: Colors.red,
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
        title: const Text('Lấy Lại Mật Khẩu'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stepper Header
              _buildStepIndicator(isDark),
              const SizedBox(height: 24),

              if (_currentStep == 1) _buildStep1ChannelSelection(isDark),
              if (_currentStep == 2) _buildStep2OtpVerification(isDark),
              if (_currentStep == 3) _buildStep3NewPassword(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Row(
      children: [
        _buildStepBadge(1, 'Kênh gửi', _currentStep >= 1, _currentStep == 1, isDark),
        Expanded(child: Container(height: 2, color: _currentStep >= 2 ? const Color(0xFF0F766E) : Colors.grey.shade300)),
        _buildStepBadge(2, 'Nhập OTP', _currentStep >= 2, _currentStep == 2, isDark),
        Expanded(child: Container(height: 2, color: _currentStep >= 3 ? const Color(0xFF0F766E) : Colors.grey.shade300)),
        _buildStepBadge(3, 'Đổi mật khẩu', _currentStep >= 3, _currentStep == 3, isDark),
      ],
    );
  }

  Widget _buildStepBadge(int step, String label, bool isReached, bool isCurrent, bool isDark) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isCurrent
              ? const Color(0xFF0F766E)
              : (isReached ? Colors.teal.shade200 : (isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
          child: Text(
            '$step',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isCurrent || isReached ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? (isDark ? Colors.tealAccent : const Color(0xFF0F766E)) : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ],
    );
  }

  // ================= STEP 1: CHỌN KÊNH & NHẬP THÔNG TIN =================
  Widget _buildStep1ChannelSelection(bool isDark) {
    final channels = [
      {
        'id': 'sms',
        'title': 'Tin Nhắn SMS',
        'desc': 'Gửi mã OTP 6 số qua số điện thoại di động',
        'icon': Icons.sms_outlined,
        'color': Colors.blue,
      },
      {
        'id': 'email',
        'title': 'Hộp Thư Gmail',
        'desc': 'Gửi liên kết và mã xác nhận về hộp thư Gmail',
        'icon': Icons.mail_outlined,
        'color': Colors.redAccent,
      },
      {
        'id': 'whatsapp',
        'title': 'WhatsApp',
        'desc': 'Nhận mã OTP qua ứng dụng tin nhắn WhatsApp',
        'icon': Icons.chat_bubble_outline,
        'color': Colors.green,
      },
      {
        'id': 'facebook',
        'title': 'Facebook / Messenger',
        'desc': 'Hỗ trợ xác minh qua Facebook hoặc nhân viên CSKH',
        'icon': Icons.facebook,
        'color': Colors.indigo,
      },
    ];

    return Form(
      key: _step1FormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Chọn Kênh Nhận Mã Khôi Phục',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Hệ thống sẽ gửi mã bảo mật 6 số qua kênh bạn lựa chọn bên dưới để xác thực danh tính.',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 16),

          ...channels.map((ch) {
            final isSelected = _selectedChannel == ch['id'];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.teal.shade900.withValues(alpha: 0.3) : Colors.teal.shade50)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0F766E) : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () => setState(() => _selectedChannel = ch['id'] as String),
                leading: CircleAvatar(
                  backgroundColor: (ch['color'] as Color).withValues(alpha: 0.15),
                  child: Icon(ch['icon'] as IconData, color: ch['color'] as Color),
                ),
                title: Text(
                  ch['title'] as String,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? const Color(0xFF0F766E) : null),
                ),
                subtitle: Text(ch['desc'] as String, style: const TextStyle(fontSize: 11)),
                trailing: Radio<String>(
                  value: ch['id'] as String,
                  groupValue: _selectedChannel,
                  onChanged: (v) => setState(() => _selectedChannel = v!),
                ),
              ),
            );
          }),

          const SizedBox(height: 12),
          TextFormField(
            controller: _identifierCtrl,
            keyboardType: _selectedChannel == 'email' ? TextInputType.emailAddress : TextInputType.phone,
            decoration: InputDecoration(
              labelText: _selectedChannel == 'email'
                  ? 'Địa chỉ Gmail đã đăng ký *'
                  : 'Số điện thoại đã đăng ký *',
              hintText: _selectedChannel == 'email' ? 'VD: minhquang@gmail.com' : 'VD: 0987654321',
              prefixIcon: Icon(_selectedChannel == 'email' ? Icons.email_outlined : Icons.phone_outlined),
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (v) => Validators.required(
              v,
              _selectedChannel == 'email' ? 'Vui lòng nhập địa chỉ Gmail' : 'Vui lòng nhập số điện thoại',
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _handleSendRecoveryCode,
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_outlined),
              label: Text(_isLoading ? 'Đang gửi mã...' : 'Tiếp Tục & Gửi Mã Xác Nhận'),
            ),
          ),
        ],
      ),
    );
  }

  // ================= STEP 2: NHẬP MÃ OTP =================
  Widget _buildStep2OtpVerification(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Simulated Notification Banner for effortless demo/testing
        if (_simulatedOtp != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.amber.shade700 : Colors.amber.shade400),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_chat_unread_outlined, color: Colors.amber, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔔 [Mô phỏng ${_channelDisplayName(_selectedChannel)}]:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        'Mã OTP xác thực của bạn là: $_simulatedOtp',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.deepOrange),
                      ),
                      const Text(
                        'Mã có hiệu lực trong vòng 5 phút.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _otpCtrl.text = _simulatedOtp ?? ''),
                  child: const Text('Điền nhanh'),
                ),
              ],
            ),
          ),

        Text(
          'Nhập Mã OTP Xác Nhận',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Mã 6 chữ số đã được gửi qua ${_channelDisplayName(_selectedChannel)} đến: ${_destinationInfo ?? _identifierCtrl.text}',
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
        ),
        const SizedBox(height: 20),

        TextFormField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: const InputDecoration(
            hintText: '------',
            counterText: '',
            prefixIcon: Icon(Icons.key_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          onChanged: (v) {
            if (v.trim().length == 6) {
              _handleVerifyOtp();
            }
          },
        ),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Chưa nhận được mã? ', style: TextStyle(fontSize: 13)),
            if (_countdownSeconds > 0)
              Text('Gửi lại sau ($_countdownSeconds s)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey))
            else
              TextButton(
                onPressed: _handleSendRecoveryCode,
                child: const Text('Gửi lại mã OTP', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: _handleVerifyOtp,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Xác Thực Mã OTP'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _currentStep = 1),
          child: const Text('« Đổi kênh gửi hoặc SĐT / Email khác'),
        ),
      ],
    );
  }

  // ================= STEP 3: ĐẶT MẬT KHẨU MỚI =================
  Widget _buildStep3NewPassword(bool isDark) {
    return Form(
      key: _step3FormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tạo Mật Khẩu Mới',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Mã OTP đã được xác thực thành công. Hãy đặt mật khẩu mới có ít nhất 6 ký tự để bảo vệ tài khoản.',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _newPassCtrl,
            obscureText: _obscureNewPass,
            decoration: InputDecoration(
              labelText: 'Mật khẩu mới *',
              hintText: 'Nhập ít nhất 6 ký tự',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureNewPass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
              ),
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: Validators.password,
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _confirmPassCtrl,
            obscureText: _obscureConfirmPass,
            decoration: InputDecoration(
              labelText: 'Xác nhận lại mật khẩu mới *',
              prefixIcon: const Icon(Icons.lock_reset),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
              ),
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            validator: (v) => Validators.confirmPassword(v, _newPassCtrl.text),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _handleResetPassword,
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.done_all),
              label: Text(_isLoading ? 'Đang lưu...' : 'Lưu Mật Khẩu & Hoàn Tất'),
            ),
          ),
        ],
      ),
    );
  }

  String _channelDisplayName(String channel) {
    switch (channel) {
      case 'email':
        return 'Gmail';
      case 'whatsapp':
        return 'WhatsApp';
      case 'facebook':
        return 'Facebook';
      case 'sms':
      default:
        return 'SMS';
    }
  }
}
