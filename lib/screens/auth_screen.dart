import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/profile_service.dart';
import '../data/supabase_client.dart';
import '../theme/coffee_palette.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.requiredRole});

  final String? requiredRole;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  late final Stream<AuthState> _authStream;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    _authStream = supabase.auth.onAuthStateChange;
    _authSub = _authStream.listen((event) {
      final session = event.session;
      if (session != null) {
        _validateRole();
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await supabase.auth.signUp(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback/',
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _validateRole() async {
    if (!mounted) return;
    final requiredRole = widget.requiredRole;
    if (requiredRole == null || requiredRole.isEmpty) {
      setState(() => _isLoading = false);
      Navigator.pop(context, true);
      return;
    }

    final profile = await ProfileService().fetchProfile();
    final role = profile?.role ?? 'customer';
    final allowed = role == requiredRole || role == 'admin';
    if (!allowed) {
      await supabase.auth.signOut();
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No staff access for this account.')),
      );
      return;
    }

    setState(() => _isLoading = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text('Sign in', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        children: [
          Text(
            _isLogin ? 'Welcome back' : 'Create your account',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              filled: true,
              fillColor: CoffeePalette.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              filled: true,
              fillColor: CoffeePalette.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: CoffeePalette.espresso,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(_isLogin ? 'Sign in' : 'Create account'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleGoogleLogin,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: CoffeePalette.espresso),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: Image.asset(
              'assets/images/googlesymbol.png',
              width: 18,
              height: 18,
              fit: BoxFit.contain,
            ),
            label: const Text('Continue with Google'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => setState(() => _isLogin = !_isLogin),
            child: Text(
              _isLogin
                  ? 'New here? Create an account'
                  : 'Already have an account? Sign in',
            ),
          ),
        ],
      ),
    );
  }
}
