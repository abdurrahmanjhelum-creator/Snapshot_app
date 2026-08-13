import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'password_reset_otp_verify_screen.dart';

// ✅ Forgot Password Screen - User email input karein OTP receive karne ke liye
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  // ✅ Send OTP for password reset
  Future<void> _sendOTP() async {
    final email = _emailCtrl.text.trim();

    // Validation - Email check karein
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email');
      return;
    }

    // Email format validation
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // API call - Forgot password OTP send karein
      final res = await ApiService.forgotPassword(email);
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        // Success - OTP sent succsessfully
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset OTP sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to Password Reset OTP verify screen with email
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PasswordResetOTPVerifyScreen(email: email),
            ),
          );
        }
      } else {
        // Error - Server response handle karein
        setState(() => _errorMessage = data['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      // Network error handle karein
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      // Loading state reset karein
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon - Password reset icon
            const Icon(Icons.lock_reset, size: 80, color: Colors.blue),
            const SizedBox(height: 24),

            // Title - Screen title
            const Text(
              'Reset Your Password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Subtitle - Instructions
            Text(
              'Enter your email address and we\'ll send you a 6-digit OTP to reset your password.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Email Input Field
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error Message Display
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            // Send OTP Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Send OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Back to Login Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
