import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Form state
  String _email = '';
  String _password = '';
  String _username = '';
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;

  Future<void> _submitAuthForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        await _authService.signInWithEmail(_email, _password);
      } else {
        await _authService.signUpWithEmail(_email, _password, _username);
      }
      // Navigation is handled by AuthWrapper in main.dart
    } catch (e) {
      setState(() => _error = e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                CircleAvatar(
                  radius: 40,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.chat_bubble_rounded,
                      size: 40, color: primaryColor),
                ),
                const SizedBox(height: 20),
                Text(
                  _isLogin ? "Welcome Back!" : "Create Account",
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // Username Field (Sign up only)
                if (!_isLogin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      key: const ValueKey('username'),
                      decoration:
                          _inputDecoration('Username', Icons.person_outline),
                      validator: (val) => (val == null || val.length < 4)
                          ? 'Min 4 characters'
                          : null,
                      onSaved: (val) => _username = val!,
                    ),
                  ),

                // Email Field
                TextFormField(
                  key: const ValueKey('email'),
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      _inputDecoration('Email Address', Icons.email_outlined),
                  validator: (val) =>
                      (!val!.contains('@')) ? 'Invalid email' : null,
                  onSaved: (val) => _email = val!,
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  key: const ValueKey('password'),
                  obscureText: true,
                  decoration: _inputDecoration('Password', Icons.lock_outline),
                  validator: (val) =>
                      (val!.length < 6) ? 'Min 6 characters' : null,
                  onSaved: (val) => _password = val!,
                ),
                const SizedBox(height: 24),

                // Error Message
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    color: Colors.red.shade50,
                    child: Text(_error!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12)),
                  ),

                // Action Button
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _submitAuthForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_isLogin ? 'Login' : 'Sign Up',
                            style: const TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text("Continue with Google"),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin
                              ? 'Create new account'
                              : 'I already have an account',
                          style: TextStyle(color: primaryColor),
                        ),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}
