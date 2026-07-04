import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../providers/auth_provider.dart';
import '../../models/meal_plan.dart';

class MealPlanNotifier extends StateNotifier<AsyncValue<MealPlan?>> {
  MealPlanNotifier() : super(const AsyncValue.data(null));

  Future<void> generatePlan(int userId, String preference) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiClient().dio.post(
        ApiEndpoints.generateMealPlan,
        data: {
          'user_id': userId,
          'preference': preference,
          'tolerance': 0.15,
        },
      );
      state = AsyncValue.data(MealPlan.fromJson(response.data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final mealPlanProvider =
    StateNotifierProvider<MealPlanNotifier, AsyncValue<MealPlan?>>((ref) {
  return MealPlanNotifier();
});

class MealPlanScreen extends ConsumerStatefulWidget {
  const MealPlanScreen({super.key});

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen> {
  String _preference = 'balanced';

  final _preferences = [
    {'key': 'balanced', 'label': 'Balanced', 'icon': Icons.balance_rounded, 'color': AppColors.primary},
    {'key': 'high_protein', 'label': 'High Protein', 'icon': Icons.fitness_center_rounded, 'color': AppColors.protein},
    {'key': 'low_carb', 'label': 'Low Carb', 'icon': Icons.grass_rounded, 'color': AppColors.accent},
    {'key': 'low_fat', 'label': 'Low Fat', 'icon': Icons.water_drop_rounded, 'color': AppColors.info},
  ];

  @override
  Widget build(BuildContext context) {
    final mealPlanState = ref.watch(mealPlanProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Meal Plan', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                'AI-optimized daily meal plan using OR-Tools solver',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Preference selector
              Text('Dietary Preference', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _preferences.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final pref = _preferences[index];
                    final selected = _preference == pref['key'];
                    final color = pref['color'] as Color;
                    return GestureDetector(
                      onTap: () => setState(() => _preference = pref['key'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 90,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selected ? color.withValues(alpha: 0.15) : AppColors.bgDarkCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? color : Colors.white.withValues(alpha: 0.06),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(pref['icon'] as IconData, color: color, size: 24),
                            const SizedBox(height: 6),
                            Text(
                              pref['label'] as String,
                              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Generate Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: mealPlanState.isLoading || user == null
                      ? null
                      : () => ref
                          .read(mealPlanProvider.notifier)
                          .generatePlan(user.id, _preference),
                  icon: mealPlanState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(mealPlanState.isLoading ? 'Generating...' : 'Generate Meal Plan'),
                ),
              ),

              const SizedBox(height: 28),

              // Results
              mealPlanState.when(
                loading: () => _buildLoadingPlaceholder(),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Could not generate a plan. Try different preferences or adjust your targets.',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
                data: (plan) {
                  if (plan == null) {
                    return _buildEmptyState(context);
                  }
                  return _buildMealPlanResult(context, plan);
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.restaurant_menu_rounded, size: 64, color: AppColors.textDarkMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No meal plan yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Generate a personalized plan above',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Column(
      children: List.generate(
        4,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.bgDarkCard,
            borderRadius: BorderRadius.circular(14),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.05)),
      ),
    );
  }

  Widget _buildMealPlanResult(BuildContext context, MealPlan plan) {
    final slots = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    final slotIcons = {
      'Breakfast': Icons.free_breakfast_rounded,
      'Lunch': Icons.lunch_dining_rounded,
      'Dinner': Icons.dinner_dining_rounded,
      'Snack': Icons.icecream_rounded,
    };
    final slotColors = {
      'Breakfast': AppColors.warning,
      'Lunch': AppColors.accent,
      'Dinner': AppColors.primary,
      'Snack': const Color(0xFFEC4899),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Plan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),

        ...slots.asMap().entries.map((entry) {
          final i = entry.key;
          final slot = entry.value;
          final meal = plan.meals[slot];
          final color = slotColors[slot] ?? AppColors.primary;
          final icon = slotIcons[slot] ?? Icons.restaurant;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgDarkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot,
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meal?.recipeName ?? 'No recipe assigned',
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (meal != null)
                        Text(
                          '${meal.calories.toInt()} kcal · P${meal.proteinG.toInt()}g · C${meal.carbsG.toInt()}g · F${meal.fatG.toInt()}g',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (200 + 100 * i).ms, duration: 400.ms).slideX(begin: 0.05);
        }),

        const SizedBox(height: 16),

        // Totals Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.darkCardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Totals', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _totalRow('Calories', plan.totals['calories'] ?? 0, plan.targets['calories'] ?? 0, AppColors.calories),
              _totalRow('Protein', plan.totals['protein_g'] ?? 0, plan.targets['protein_g'] ?? 0, AppColors.protein),
              _totalRow('Carbs', plan.totals['carbs_g'] ?? 0, plan.targets['carbs_g'] ?? 0, AppColors.carbs),
              _totalRow('Fat', plan.totals['fat_g'] ?? 0, plan.targets['fat_g'] ?? 0, AppColors.fat),
            ],
          ),
        ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
      ],
    );
  }

  Widget _totalRow(String label, double actual, double target, Color color) {
    final percent = target > 0 ? (actual / target).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: AppColors.textDarkMuted, fontSize: 13)),
              Text(
                '${actual.toInt()} / ${target.toInt()}',
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
