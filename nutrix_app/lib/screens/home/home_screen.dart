import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scanner_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(analyticsProvider.notifier).fetchAnalytics(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final firstName = user?.name.split(' ').first ?? 'Chaitya';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(context, firstName),
            const SizedBox(height: 28),
            _buildQuickActionsGrid(context),
            const SizedBox(height: 28),
            _buildNutritionAverages(ref),
            const SizedBox(height: 36),
            _buildFooter(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String firstName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.blueAction],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, $firstName! 👋',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Welcome back to your personalized diet & nutrition planner. Let\'s optimize your health targets today!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textMain, letterSpacing: -0.2),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.35,
          children: [
            _actionTile(
              context,
              title: 'Scan Barcode',
              desc: 'Scan & log meals',
              icon: Icons.qr_code_scanner,
              color: AppColors.primary,
              route: '/barcode',
            ),
            _actionTile(
              context,
              title: 'Ask AI Coach',
              desc: 'Get diet feedback',
              icon: Icons.chat_bubble_outline,
              color: AppColors.purpleAction,
              route: '/ai-coach',
            ),
            _actionTile(
              context,
              title: 'Homely Builder',
              desc: 'Estimate macros',
              icon: Icons.science_outlined,
              color: AppColors.blueAction,
              route: '/homely',
            ),
            _actionTile(
              context,
              title: 'Explore Recipes',
              desc: 'Find healthy meals',
              icon: Icons.restaurant_menu_outlined,
              color: AppColors.calories,
              route: '/recipes',
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionAverages(WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final hasData = state.summaryData != null;

    final avgCal = hasData ? '${state.summaryData!['avg_calories']?.round() ?? 0}' : '0';
    final avgProt = hasData ? '${state.summaryData!['avg_protein']?.round() ?? 0}g' : '0g';
    final avgCarbs = hasData ? '${state.summaryData!['avg_carbs']?.round() ?? 0}g' : '0g';
    final avgFat = hasData ? '${state.summaryData!['avg_fat']?.round() ?? 0}g' : '0g';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your 7-Day Nutrition Averages',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textMain, letterSpacing: -0.2),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _macroItem('Calories', avgCal, AppColors.calories),
                _macroItem('Protein', avgProt, AppColors.protein),
                _macroItem('Carbs', avgCarbs, AppColors.carbs),
                _macroItem('Fat', avgFat, AppColors.fat),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _macroItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'NutriX',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textMain, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Smart wellness, custom diets & live meal logs.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          const Text(
            'v2.0.0 • Made with ❤️',
            style: TextStyle(color: AppColors.textDim, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
