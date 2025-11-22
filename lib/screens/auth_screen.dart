import 'package:chat_app/screens/chat_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isLogin = true;
  bool _isLoading = false;

  String _userEmail = '';
  String _userName = '';
  String _userPassword = '';

  void _submitForm() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // 1. محاولة تسجيل الدخول
        await _authService.signInWithEmail(_userEmail, _userPassword);
      } else {
        // 2. محاولة إنشاء حساب
        try {
          await _authService.signUpWithEmail(
              _userEmail, _userPassword, _userName);
        } catch (e) {
          // الذكاء هنا: لو الإيميل موجود بالفعل، حاول تعمل تسجيل دخول بدلاً من الخطأ
          if (e.toString().contains('email-already-in-use')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Account exists. Logging you in...'),
                  backgroundColor: Colors.blue),
            );
            await _authService.signInWithEmail(_userEmail, _userPassword);
          } else {
            rethrow; // لو خطأ تاني، اظهره
          }
        }
      }

      // 3. الإنتقال الفوري بعد النجاح (بدون انتظار الـ Restart)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChatListScreen()),
        );
      }
    } catch (error) {
      // التعامل مع الأخطاء
      if (mounted) {
        String msg = "Authentication failed";
        if (error.toString().contains('user-not-found'))
          msg = "No user found with this email.";
        if (error.toString().contains('wrong-password'))
          msg = "Incorrect password.";
        if (error.toString().contains('weak-password'))
          msg = "Password is too weak.";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_chat_unread_rounded,
                  size: 80, color: Color(0xFF4F46E5)),
              const SizedBox(height: 20),
              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (!_isLogin)
                          TextFormField(
                            key: const ValueKey('username'),
                            validator: (value) =>
                                (value == null || value.length < 4)
                                    ? 'Min 4 characters.'
                                    : null,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            onSaved: (value) => _userName = value!,
                          ),
                        if (!_isLogin) const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('email'),
                          validator: (value) =>
                              (value == null || !value.contains('@'))
                                  ? 'Invalid email.'
                                  : null,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (value) => _userEmail = value!,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('password'),
                          validator: (value) =>
                              (value == null || value.length < 6)
                                  ? 'Min 6 characters.'
                                  : null,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          onSaved: (value) => _userPassword = value!,
                        ),
                        const SizedBox(height: 20),
                        if (_isLoading)
                          const CircularProgressIndicator()
                        else
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: Text(_isLogin ? 'Login' : 'Sign Up'),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isLogin = !_isLogin),
                                child: Text(
                                  _isLogin
                                      ? 'Create new account'
                                      : 'I already have an account',
                                  style:
                                      const TextStyle(color: Color(0xFF4F46E5)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
