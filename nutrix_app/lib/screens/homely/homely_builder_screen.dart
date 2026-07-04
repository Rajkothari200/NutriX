import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/homely_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class HomelyBuilderScreen extends ConsumerStatefulWidget {
  const HomelyBuilderScreen({super.key});

  @override
  ConsumerState<HomelyBuilderScreen> createState() => _HomelyBuilderScreenState();
}

class _HomelyBuilderScreenState extends ConsumerState<HomelyBuilderScreen> {
  // Custom Meal Form Controllers
  final _mealNameCtrl = TextEditingController();
  final _cuisineCtrl = TextEditingController(text: 'Indian');
  final _regionCtrl = TextEditingController();
  bool _isCommunity = true;
  
  // Custom Meal Ingredients Rows
  final List<Map<String, dynamic>> _ingredientRows = [
    {'nameCtrl': TextEditingController(), 'qtyCtrl': TextEditingController(text: '100'), 'unit': 'grams'}
  ];

  // Interactive Builder States
  String? _selectedBaseMealCode;
  int _quantity = 4;
  final Map<String, double> _condimentQuantities = {};
  String _selectedSlot = 'Lunch';

  // Search Community Controller
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homelyBuilderProvider.notifier).fetchDefaults().then((_) {
        final defaultsState = ref.read(homelyBuilderProvider);
        if (defaultsState.defaults != null) {
          final baseMeals = defaultsState.defaults!['base_meals'] as List;
          if (baseMeals.isNotEmpty) {
            setState(() {
              _selectedBaseMealCode = baseMeals[0]['code'];
            });
          }
          final condiments = defaultsState.defaults!['condiments'] as List;
          for (var c in condiments) {
            _condimentQuantities[c['id']] = 0.0;
          }
        }
      });
      ref.read(homelyCommunityProvider.notifier).searchMeals('');
      ref.read(homelyCommunityProvider.notifier).fetchPending();
    });
  }

  @override
  void dispose() {
    _mealNameCtrl.dispose();
    _cuisineCtrl.dispose();
    _regionCtrl.dispose();
    _searchCtrl.dispose();
    for (var row in _ingredientRows) {
      row['nameCtrl'].dispose();
      row['qtyCtrl'].dispose();
    }
    super.dispose();
  }

  void _addIngredientRow() {
    setState(() {
      _ingredientRows.add({
        'nameCtrl': TextEditingController(),
        'qtyCtrl': TextEditingController(text: '100'),
        'unit': 'grams'
      });
    });
  }

  void _removeIngredientRow(int index) {
    if (_ingredientRows.length > 1) {
      setState(() {
        _ingredientRows[index]['nameCtrl'].dispose();
        _ingredientRows[index]['qtyCtrl'].dispose();
        _ingredientRows.removeAt(index);
      });
    }
  }

  List<Map<String, dynamic>> _getIngredientsPayload() {
    return _ingredientRows.map((row) {
      return {
        'ingredient_name': (row['nameCtrl'] as TextEditingController).text.trim(),
        'amount': double.tryParse((row['qtyCtrl'] as TextEditingController).text) ?? 0.0,
        'unit': row['unit'],
      };
    }).toList();
  }

  void _calculateCustomMacros() {
    final payload = _getIngredientsPayload();
    if (payload.any((i) => i['ingredient_name'].isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all ingredient names.')),
      );
      return;
    }
    ref.read(homelyCustomMealProvider.notifier).calculateMacros(payload);
  }

  void _saveCustomMeal() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    
    final name = _mealNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meal name.')),
      );
      return;
    }

    final ingredients = _getIngredientsPayload();
    if (ingredients.any((i) => i['ingredient_name'].isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all ingredient names.')),
      );
      return;
    }

    ref.read(homelyCustomMealProvider.notifier).createCustomMeal(
      name: name,
      cuisine: _cuisineCtrl.text.trim(),
      region: _regionCtrl.text.trim(),
      isCommunity: _isCommunity,
      ingredients: ingredients,
      userId: user.id,
    ).then((success) {
      if (success) {
        _mealNameCtrl.clear();
        _regionCtrl.clear();
        setState(() {
          _ingredientRows.clear();
          _ingredientRows.add({
            'nameCtrl': TextEditingController(),
            'qtyCtrl': TextEditingController(text: '100'),
            'unit': 'grams'
          });
        });
        ref.read(homelyCommunityProvider.notifier).searchMeals('');
        ref.read(homelyCommunityProvider.notifier).fetchPending();
      }
    });
  }

  // Live calculation for builder macros
  Map<String, double> _calculateLiveBuilderMacros(Map<String, dynamic> defaults) {
    final baseMeals = defaults['base_meals'] as List;
    final condiments = defaults['condiments'] as List;

    final baseItem = baseMeals.firstWhere((m) => m['code'] == _selectedBaseMealCode, orElse: () => null);
    if (baseItem == null) return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};

    final baseWeight = _quantity * (baseItem['unit_weight_g'] as num).toDouble();
    final baseNutrients = baseItem['nutrients_100g'] as Map<String, dynamic>;

    double calories = ((baseNutrients['energy_kcal'] as num).toDouble() * baseWeight) / 100.0;
    double protein = ((baseNutrients['protein_g'] as num).toDouble() * baseWeight) / 100.0;
    double carbs = ((baseNutrients['carb_g'] as num).toDouble() * baseWeight) / 100.0;
    double fat = ((baseNutrients['fat_g'] as num).toDouble() * baseWeight) / 100.0;

    for (var c in condiments) {
      final qty = _condimentQuantities[c['id']] ?? 0.0;
      if (qty > 0) {
        final weight = qty * (c['unit_weight_g'] as num).toDouble();
        final condNutrients = c['nutrients_100g'] as Map<String, dynamic>;
        calories += ((condNutrients['energy_kcal'] as num).toDouble() * weight) / 100.0;
        protein += ((condNutrients['protein_g'] as num).toDouble() * weight) / 100.0;
        carbs += ((condNutrients['carb_g'] as num).toDouble() * weight) / 100.0;
        fat += ((condNutrients['fat_g'] as num).toDouble() * weight) / 100.0;
      }
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  void _logBuilderMeal(Map<String, dynamic> defaults, Map<String, double> liveMacros) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final baseMeals = defaults['base_meals'] as List;
    final baseItem = baseMeals.firstWhere((m) => m['code'] == _selectedBaseMealCode, orElse: () => null);
    if (baseItem == null) return;

    String mealDesc = '$_quantity ${baseItem['name']}';
    final condiments = defaults['condiments'] as List;
    for (var c in condiments) {
      final qty = _condimentQuantities[c['id']] ?? 0.0;
      if (qty > 0) {
        mealDesc += ' + ${c['name']} ($qty ${c['unit']})';
      }
    }

    final apiClient = ApiClient();
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final logPayload = {
      'user_id': user.id,
      'log_date': todayStr,
      'meal_type': _selectedSlot,
      'food_name': mealDesc,
      'calories': liveMacros['calories']!.roundToDouble(),
      'protein': liveMacros['protein']!.roundToDouble(),
      'carbs': liveMacros['carbs']!.roundToDouble(),
      'fat': liveMacros['fat']!.roundToDouble(),
    };

    try {
      await apiClient.dio.post(ApiEndpoints.mealLogs, data: logPayload);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged homely builder meal as $_selectedSlot successfully!'), backgroundColor: Colors.green),
      );
      setState(() {
        _quantity = 4;
        for (var key in _condimentQuantities.keys) {
          _condimentQuantities[key] = 0.0;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _logCommunityMealDirect(dynamic meal) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final nut = meal['nutrition'] ?? {};
    final apiClient = ApiClient();
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final logPayload = {
      'user_id': user.id,
      'log_date': todayStr,
      'meal_type': 'Lunch',
      'food_name': meal['name'] ?? 'Community Meal',
      'calories': (nut['energy_kcal'] ?? 0.0).toDouble(),
      'protein': (nut['protein_g'] ?? 0.0).toDouble(),
      'carbs': (nut['carb_g'] ?? 0.0).toDouble(),
      'fat': (nut['fat_g'] ?? 0.0).toDouble(),
    };

    try {
      await apiClient.dio.post(ApiEndpoints.mealLogs, data: logPayload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged community meal to Lunch successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildCreateCustomMealCard(),
            const SizedBox(height: 24),
            _buildInteractiveBuilderCard(),
            const SizedBox(height: 24),
            _buildCommunitySearchCard(),
            const SizedBox(height: 24),
            _buildCommunityApprovalsCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateCustomMealCard() {
    final customState = ref.watch(homelyCustomMealProvider);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book, color: AppColors.blueAction),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Create Custom Homely Meal',
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
            _inputLabel('MEAL NAME'),
            const SizedBox(height: 8),
            TextField(
              controller: _mealNameCtrl,
              decoration: const InputDecoration(hintText: 'e.g. Papad Churi / Ghee Rice'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _inputLabel('CUISINE'),
                      const SizedBox(height: 8),
                      TextField(controller: _cuisineCtrl, decoration: const InputDecoration(hintText: 'e.g. Indian')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _inputLabel('REGION (OPTIONAL)'),
                      const SizedBox(height: 8),
                      TextField(controller: _regionCtrl, decoration: const InputDecoration(hintText: 'e.g. Rajasthan')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => setState(() => _isCommunity = !_isCommunity),
              child: Row(
                children: [
                  Checkbox(
                    value: _isCommunity,
                    onChanged: (val) {
                      if (val != null) setState(() => _isCommunity = val);
                    },
                    activeColor: AppColors.blueAction,
                  ),
                  const Expanded(
                    child: Text(
                      'Publish to Community Kitchen',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMain),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ingredients &\nQuantities',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                OutlinedButton(
                  onPressed: _addIngredientRow,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textMain,
                  ),
                  child: const Text('+ Add Ingredient'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ingredientRows.length,
              itemBuilder: (context, index) {
                final row = _ingredientRows[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgLightCard,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: row['nameCtrl'],
                              decoration: const InputDecoration(
                                hintText: 'Ingredient e.g. Paneer',
                                labelText: 'Ingredient Name',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.error),
                            onPressed: () => _removeIngredientRow(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: row['qtyCtrl'],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Qty',
                                labelText: 'Quantity',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: row['unit'],
                                  isExpanded: true,
                                  items: ['grams', 'ml', 'pieces']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => row['unit'] = v);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            if (customState.error != null) ...[
              const SizedBox(height: 16),
              Text(customState.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            if (customState.successMessage != null) ...[
              const SizedBox(height: 16),
              Text(customState.successMessage!, style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
            if (customState.calculatedMacros != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CALCULATED TOTAL MACROS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _totalMacroItem('Calories', '${customState.calculatedMacros!['totals']?['energy_kcal']?.round() ?? 0} kcal'),
                        _totalMacroItem('Protein', '${customState.calculatedMacros!['totals']?['protein_g'] ?? 0}g'),
                        _totalMacroItem('Carbs', '${customState.calculatedMacros!['totals']?['carb_g'] ?? 0}g'),
                        _totalMacroItem('Fat', '${customState.calculatedMacros!['totals']?['fat_g'] ?? 0}g'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: customState.isLoading ? null : _calculateCustomMacros,
                      icon: const Icon(Icons.flash_on, color: Colors.orange),
                      label: customState.isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Calculate Macros'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.purpleAction),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: customState.isSaving ? null : _saveCustomMeal,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: customState.isSaving 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save & Publish Meal'),
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

  Widget _totalMacroItem(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildInteractiveBuilderCard() {
    final builderState = ref.watch(homelyBuilderProvider);

    if (builderState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (builderState.defaults == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Could not load builder defaults.')),
        ),
      );
    }

    final defaults = builderState.defaults!;
    final baseMeals = defaults['base_meals'] as List;
    final condiments = defaults['condiments'] as List;

    final liveMacros = _calculateLiveBuilderMacros(defaults);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Interactive Homely Meal Builder',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: AppColors.primary,
                        ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            const Text(
              'Choose a base Indian meal and adjust condiment sliders to dynamically calculate macros.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            _inputLabel('BASE INDIAN MEAL'),
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
                  value: _selectedBaseMealCode,
                  items: baseMeals.map<DropdownMenuItem<String>>((m) {
                    return DropdownMenuItem<String>(
                      value: m['code'],
                      child: Text('${m['name']} (${(m['nutrients_100g']?['energy_kcal'] ?? 0).round()} kcal/100g)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBaseMealCode = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            _inputLabel('QUANTITY (PIECES): $_quantity'),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.border,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _quantity.toDouble(),
                min: 1,
                max: 12,
                divisions: 11,
                onChanged: (val) => setState(() => _quantity = val.toInt()),
              ),
            ),
            const SizedBox(height: 16),
            _inputLabel('CONDIMENTS & ADD-ONS'),
            const SizedBox(height: 12),
            ...condiments.map<Widget>((c) {
              final val = _condimentQuantities[c['id']] ?? 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${c['name']} (${c['unit']})', style: const TextStyle(fontSize: 12)),
                        Text('${val.round()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    Slider(
                      value: val,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      activeColor: AppColors.purpleAction,
                      onChanged: (newVal) {
                        setState(() {
                          _condimentQuantities[c['id']] = newVal;
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgLightCard,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('COMBINED LIVE NUTRITION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _macroStat('Calories (kcal)', '${liveMacros['calories']!.round()}', AppColors.primary),
                      _macroStat('Protein', '${liveMacros['protein']!.round()}g', AppColors.blueAction),
                      _macroStat('Carbs', '${liveMacros['carbs']!.round()}g', AppColors.calories),
                      _macroStat('Fat', '${liveMacros['fat']!.round()}g', AppColors.error),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _inputLabel('MEAL SLOT'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedSlot,
                        items: ['Breakfast', 'Lunch', 'Dinner', 'Snacks']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSlot = val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _logBuilderMeal(defaults, liveMacros),
                      icon: const Text('📝'),
                      label: const Text('Log Homely Meal'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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

  Widget _buildCommunitySearchCard() {
    final commState = ref.watch(homelyCommunityProvider);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.search, color: AppColors.blueAction),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Community Kitchen & Custom Meals',
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(hintText: 'Search approved community meals.'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => ref.read(homelyCommunityProvider.notifier).searchMeals(_searchCtrl.text),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMain,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (commState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (commState.communityMeals.isEmpty)
              const Center(
                child: Text('No matching homely meals found.', style: TextStyle(color: AppColors.textMuted)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: commState.communityMeals.length,
                itemBuilder: (context, index) {
                  final meal = commState.communityMeals[index];
                  final nut = meal['nutrition'] ?? {};
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.bgLightCard,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                meal['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _logCommunityMealDirect(meal),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 11),
                              ),
                              child: const Text('Log Meal'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Cuisine: ${meal['cuisine'] ?? '—'} | Region: ${meal['region'] ?? '—'}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        Text(
                          'Macros: ${(nut['energy_kcal'] ?? 0).round()} kcal | ${(nut['protein_g'] ?? 0).round()}g P | ${(nut['carb_g'] ?? 0).round()}g C | ${(nut['fat_g'] ?? 0).round()}g F',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityApprovalsCard() {
    final commState = ref.watch(homelyCommunityProvider);
    final user = ref.watch(authProvider).user;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rate_review, color: AppColors.blueAction),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Community Kitchen Approvals',
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
            const Text(
              'Moderate user homely meal submissions for the community database.',
              style: TextStyle(color: AppColors.textMain, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (commState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (commState.pendingReviews.isEmpty)
              const Center(
                child: Text('No pending reviews found.', style: TextStyle(color: AppColors.textMuted)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: commState.pendingReviews.length,
                itemBuilder: (context, index) {
                  final meal = commState.pendingReviews[index];
                  final nut = meal['nutrition'] ?? {};
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.bgLightCard,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meal['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Cuisine: ${meal['cuisine'] ?? '—'} | Region: ${meal['region'] ?? '—'}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        Text(
                          'Macros: ${(nut['energy_kcal'] ?? 0).round()} kcal | ${(nut['protein_g'] ?? 0).round()}g P | ${(nut['carb_g'] ?? 0).round()}g C',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (user != null) {
                                    ref.read(homelyCommunityProvider.notifier).moderateMeal(
                                      mealId: meal['id'],
                                      status: 'approved',
                                      userId: user.id,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('Approve', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (user != null) {
                                    ref.read(homelyCommunityProvider.notifier).moderateMeal(
                                      mealId: meal['id'],
                                      status: 'rejected',
                                      userId: user.id,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Reject', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5),
    );
  }

  Widget _macroStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
      ],
    );
  }
}
