import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _weightController = TextEditingController();
  bool _loggingWeight = false;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _logWeight() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight < 10 || weight > 600) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight (10-600 kg)')),
      );
      return;
    }

    setState(() => _loggingWeight = true);
    try {
      await ApiClient().dio.post(
        ApiEndpoints.trackWeight,
        data: {'user_id': user.id, 'weight': weight},
      );
      if (mounted) {
        _weightController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Weight logged successfully! ✅'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _loggingWeight = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),

              // Avatar + Info
              _buildProfileHeader(context, user),
              const SizedBox(height: 24),

              // Body Stats
              _buildBodyStats(context, user),
              const SizedBox(height: 24),

              // Nutrition Targets
              _buildTargetsCard(context, user),
              const SizedBox(height: 24),

              // Weight Logger
              _buildWeightLogger(context),
              const SizedBox(height: 24),

              // Actions
              _buildActionsList(context),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bgDarkCard,
            AppColors.bgDarkSurface.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'N',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatGoal(user.goal),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildBodyStats(BuildContext context, user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Body Stats', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            _statTile(context, 'Age', '${user.age}', 'years', Icons.cake_outlined, AppColors.warning),
            const SizedBox(width: 10),
            _statTile(context, 'Height', '${user.height.toInt()}', 'cm', Icons.height_rounded, AppColors.info),
            const SizedBox(width: 10),
            _statTile(context, 'Weight', '${user.weight.toStringAsFixed(1)}', 'kg', Icons.monitor_weight_outlined, AppColors.accent),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statTile(context, 'BMI', user.bmi?.toStringAsFixed(1) ?? '--', user.bmiStatus ?? '', Icons.analytics_outlined, AppColors.primary),
            const SizedBox(width: 10),
            _statTile(context, 'TDEE', user.tdee?.toInt().toString() ?? '--', 'kcal', Icons.local_fire_department_rounded, AppColors.calories),
            const SizedBox(width: 10),
            _statTile(context, 'Activity', _shortActivity(user.activityLevel), '', Icons.directions_run_rounded, const Color(0xFFEC4899)),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _statTile(BuildContext context, String label, String value, String unit, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgDarkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (unit.isNotEmpty)
              Text(unit, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetsCard(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Targets', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _targetRow('Calories', '${user.targetCalories.toInt()} kcal', AppColors.calories),
          _targetRow('Protein', '${user.targetProtein.toInt()}g', AppColors.protein),
          _targetRow('Carbs', '${user.targetCarbs.toInt()}g', AppColors.carbs),
          _targetRow('Fat', '${user.targetFat.toInt()}g', AppColors.fat),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _targetRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildWeightLogger(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_weight_outlined, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text('Log Weight', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter weight in kg...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loggingWeight ? null : _logWeight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                child: _loggingWeight
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Log'),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms);
  }

  Widget _buildActionsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _actionItem(
          context,
          Icons.notifications_outlined,
          'Notifications',
          'Meal reminders & updates',
          AppColors.warning,
          () {},
        ),
        _actionItem(
          context,
          Icons.color_lens_outlined,
          'Appearance',
          'Dark mode enabled',
          AppColors.primary,
          () {},
        ),
        _actionItem(
          context,
          Icons.info_outline_rounded,
          'About NutriX',
          'Version 1.0.0',
          AppColors.info,
          () {},
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 400.ms);
  }

  Widget _actionItem(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgDarkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textDarkMuted),
          ],
        ),
      ),
    );
  }

  String _formatGoal(String goal) {
    return goal.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  String _shortActivity(String level) {
    switch (level) {
      case 'sedentary': return 'Low';
      case 'lightly_active': return 'Light';
      case 'moderately_active': return 'Medium';
      case 'active': return 'High';
      case 'very_active': return 'V.High';
      default: return level;
    }
  }
}
