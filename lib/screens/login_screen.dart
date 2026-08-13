import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';

import '../services/api_service.dart';

import 'register_screen.dart';

import 'otp_verification_screen.dart';

import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();

  final _passCtrl = TextEditingController();

  bool _obscure = true;

  Future<void> _login() async {
    final auth = Provider.of<AuthController>(context, listen: false);

    final error = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;

    if (error == null) {
      // Successful login ke baad ab HomeScreen par jaana hai

      Navigator.pushReplacementNamed(context, '/home');
    } else if (error.contains('Account not verified')) {
      // Show dialog for unverified account

      _showVerificationDialog();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        title: const Text('Account Not Verified'),

        content: const Text(
          'Your account is not verified. Would you like to resend the verification code?',
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),

            child: const Text('Cancel'),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              _resendOTP();
            },

            child: const Text('Resend OTP'),
          ),
        ],
      ),
    );
  }

  Future<void> _resendOTP() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));

      return;
    }

    try {
      final res = await ApiService.resendOTP(email);

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent successfully')),
          );

          Navigator.push(
            context,

            MaterialPageRoute(
              builder: (_) => OTPVerificationScreen(email: email),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to resend OTP')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),

        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                const Text(
                  'Snapshot',

                  style: TextStyle(
                    fontSize: 36,

                    fontWeight: FontWeight.bold,

                    fontFamily: 'Billabong',
                  ),
                ),

                const SizedBox(height: 40),

                TextField(
                  controller: _emailCtrl,

                  decoration: const InputDecoration(labelText: 'Email'),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _passCtrl,

                  obscureText: _obscure,

                  decoration: InputDecoration(
                    labelText: 'Password',

                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),

                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,

                  height: 45,

                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _login,

                    child: auth.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Login'),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
                  child: const Text('Forgot Password?'),
                ),

                TextButton(
                  onPressed: () => Navigator.push(
                    context,

                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),

                  child: const Text('Don\'t have an account? Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
