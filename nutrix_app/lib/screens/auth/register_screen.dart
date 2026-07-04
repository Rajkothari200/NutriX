import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _gender = 'male';
  String _activityLevel = 'moderately_active';
  String _goal = 'maintenance';
  bool _obscurePassword = true;
  int _step = 0; // 0 = account info, 1 = body metrics

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            age: int.tryParse(_ageController.text) ?? 25,
            gender: _gender,
            height: double.tryParse(_heightController.text) ?? 170,
            weight: double.tryParse(_weightController.text) ?? 70,
            activityLevel: _activityLevel,
            goal: _goal,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => _step == 0 ? context.go('/login') : setState(() => _step = 0),
        ),
        title: Text(_step == 0 ? 'Create Account' : 'Your Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Step indicator
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: _step >= 1
                              ? AppColors.primary
                              : AppColors.bgDarkSurface,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                if (_step == 0) ...[
                  _buildStep0(),
                ] else ...[
                  _buildStep1(authState),
                ],

                const SizedBox(height: 24),
                if (_step == 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Sign In',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline, size: 20),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Invalid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outlined, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) {
            if (v == null || v.length < 6) return 'Min 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                setState(() => _step = 1);
              }
            },
            child: const Text('Continue'),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStep1(AuthState authState) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.cake_outlined, size: 20),
                ),
                validator: (v) {
                  final age = int.tryParse(v ?? '');
                  if (age == null || age < 1 || age > 119) return 'Invalid';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'male'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  prefixIcon: Icon(Icons.height, size: 20),
                ),
                validator: (v) {
                  final h = double.tryParse(v ?? '');
                  if (h == null || h < 30 || h > 300) return 'Invalid';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20),
                ),
                validator: (v) {
                  final w = double.tryParse(v ?? '');
                  if (w == null || w < 10 || w > 600) return 'Invalid';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _activityLevel,
          decoration: const InputDecoration(
            labelText: 'Activity Level',
            prefixIcon: Icon(Icons.fitness_center_outlined, size: 20),
          ),
          items: const [
            DropdownMenuItem(value: 'sedentary', child: Text('Sedentary')),
            DropdownMenuItem(value: 'lightly_active', child: Text('Lightly Active')),
            DropdownMenuItem(value: 'moderately_active', child: Text('Moderately Active')),
            DropdownMenuItem(value: 'active', child: Text('Active')),
            DropdownMenuItem(value: 'very_active', child: Text('Very Active')),
          ],
          onChanged: (v) => setState(() => _activityLevel = v ?? 'moderately_active'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _goal,
          decoration: const InputDecoration(
            labelText: 'Fitness Goal',
            prefixIcon: Icon(Icons.flag_outlined, size: 20),
          ),
          items: const [
            DropdownMenuItem(value: 'fat loss', child: Text('Fat Loss')),
            DropdownMenuItem(value: 'weight gain', child: Text('Weight Gain')),
            DropdownMenuItem(value: 'muscle gain', child: Text('Muscle Gain')),
            DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
          ],
          onChanged: (v) => setState(() => _goal = v ?? 'maintenance'),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: authState.status == AuthStatus.loading ? null : _handleRegister,
            child: authState.status == AuthStatus.loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Create Account'),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }
}
