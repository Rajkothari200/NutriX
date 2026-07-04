import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';

class RecipeSearchScreen extends ConsumerStatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  ConsumerState<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends ConsumerState<RecipeSearchScreen> {
  final _ingredientsCtrl = TextEditingController();
  final _excludeCtrl = TextEditingController();
  final _maxTimeCtrl = TextEditingController();
  
  String _selectedGoal = '';
  String _selectedDiet = '';
  String _selectedCuisine = '';
  int _topN = 10;

  @override
  void dispose() {
    _ingredientsCtrl.dispose();
    _excludeCtrl.dispose();
    _maxTimeCtrl.dispose();
    super.dispose();
  }

  void _handleFindRecipes() {
    final ingredientsStr = _ingredientsCtrl.text.trim();
    if (ingredientsStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one ingredient.')),
      );
      return;
    }

    final ingredients = ingredientsStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one valid ingredient.')),
      );
      return;
    }

    final excludesStr = _excludeCtrl.text.trim();
    final excludes = excludesStr.isNotEmpty 
        ? excludesStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList() 
        : null;

    ref.read(recipeProvider.notifier).recommendRecipes(
      ingredients: ingredients,
      goal: _selectedGoal,
      dietType: _selectedDiet,
      cuisine: _selectedCuisine,
      excludeIngredients: excludes,
      maxCookingTime: int.tryParse(_maxTimeCtrl.text),
      topN: _topN,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final firstName = user?.name.split(' ').first ?? 'Chaitya';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildWelcomeCard(context, firstName),
            const SizedBox(height: 24),
            _buildSearchConfigCard(),
            const SizedBox(height: 24),
            _buildRecommendedRecipesCard(),
            const SizedBox(height: 24),
            _buildHowItWorksCard(),
            const SizedBox(height: 32),
            _buildFooter(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String firstName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              'Welcome to NutriX,\n$firstName!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textMain,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Optimize your nutrition intake, build homely meals with live calculators, scan products with custom barcode analysis, and plan custom diet targets instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/barcode'),
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('Scan Barcode'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/ai-coach'),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Ask AI Coach'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: AppColors.textMain,
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingredients on Hand (Comma-Separated)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.2)),
            const SizedBox(height: 8),
            TextField(
              controller: _ingredientsCtrl,
              decoration: const InputDecoration(hintText: 'e.g. paneer, tomato, rice, spinach'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Max Cooking Time (min)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.2)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _maxTimeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'e.g. 30'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Results to Show', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.2)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: _topN,
                            items: [5, 10, 15, 20]
                                .map((e) => DropdownMenuItem(value: e, child: Text('Top $e')))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _topN = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Goal Filter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.2)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedGoal,
                            items: [
                              {'label': 'No Filter', 'value': ''},
                              {'label': 'Weight Loss', 'value': 'weight loss'},
                              {'label': 'Muscle Gain', 'value': 'muscle gain'},
                              {'label': 'Weight Gain', 'value': 'weight gain'},
                              {'label': 'Maintenance', 'value': 'maintenance'},
                            ].map((e) => DropdownMenuItem(value: e['value'], child: Text(e['label']!))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedGoal = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Diet Type', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.2)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedDiet,
                            items: [
                              {'label': 'No Filter', 'value': ''},
                              {'label': 'Vegetarian', 'value': 'vegetarian'},
                              {'label': 'Vegan', 'value': 'vegan'},
                            ].map((e) => DropdownMenuItem(value: e['value'], child: Text(e['label']!))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedDiet = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleFindRecipes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFEDD5), // Peach background
                  foregroundColor: AppColors.calories,
                  side: const BorderSide(color: AppColors.calories),
                ),
                child: const Text('Find Recipes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedRecipesCard() {
    final recipeState = ref.watch(recipeProvider);

    if (recipeState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (recipeState.error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: ${recipeState.error}', style: const TextStyle(color: AppColors.error)),
        ),
      );
    }

    if (recipeState.recipes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Enter your ingredients and click "Find Recipes" to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recommended Recipes',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textMain, letterSpacing: 0.2),
                ),
                Text(
                  'Showing ${recipeState.recipes.length} of ${recipeState.totalResults} matches',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recipeState.recipes.length,
              itemBuilder: (context, index) {
                final r = recipeState.recipes[index];
                final matchPct = ((r['match_score'] ?? 0.0) as num).toDouble() * 100;
                final isHealthy = r['health_category'] == 'Healthy';
                final isUnhealthy = r['health_category'] == 'Unhealthy';
                final color = isHealthy 
                    ? Colors.green 
                    : isUnhealthy 
                        ? Colors.red 
                        : Colors.orange;

                final missing = r['ingredient_match']?['missing'] as List? ?? [];
                final extra = missing.isNotEmpty 
                    ? 'Additional: ${missing.take(3).join(', ')}${missing.length > 3 ? '...' : ''}' 
                    : 'All ingredients covered';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.bgLightCard,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    onTap: () => context.push('/recipe/${r['recipe_code']}'),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            r['recipe_name'] ?? 'Unnamed Recipe',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${matchPct.round()}% Match',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text('Health Score: ${r['health_score']?.round() ?? '--'} (${r['health_category'] ?? '—'})', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(extra, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        if (r['reason'] != null)
                          Text(r['reason'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.blueAction),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'How It Works',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            _howItWorksRow('🔍', 'Ingredient Matching', 'Fuzzy matching with RapidFuzz handles variations like tomato ≈ tomatoes, chilli ≈ chili, capsicum ≈ bell pepper.'),
            const SizedBox(height: 12),
            _howItWorksRow('❤️', 'Health Scoring', 'Each recipe scored 0-100 based on protein, fibre, sugar, sodium, and fat per 100g.'),
            const SizedBox(height: 12),
            _howItWorksRow('⭐', 'Ranking', 'Final score = ingredient match (50%) + health score (30%) + protein bonus - calorie penalty.'),
            const SizedBox(height: 12),
            _howItWorksRow('📝', 'Explanations', 'Deterministic, rule-based explanations — no external LLM APIs.'),
            const SizedBox(height: 12),
            _howItWorksRow('🧠', 'ML Extension', 'Optional RandomForest/XGBoost training pipeline included.'),
          ],
        ),
      ),
    );
  }

  Widget _howItWorksRow(String emoji, String title, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
              children: [
                TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.bgLightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'NutriX',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'AI-powered diet planning and recipe intelligence. Get commercial-grade wellness tracking, meal optimization, and custom homely meal creation instantly.',
            style: TextStyle(color: AppColors.textMuted, height: 1.6, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
