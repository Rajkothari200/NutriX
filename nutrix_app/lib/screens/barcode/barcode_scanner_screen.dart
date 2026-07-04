import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scanner_provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final _barcodeInputController = TextEditingController();
  final _classifyController = TextEditingController();
  final _ocrFoodNameController = TextEditingController();
  
  XFile? _selectedOcrImage;
  String _selectedOcrMealType = 'Breakfast';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  void _loadAnalytics() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.read(analyticsProvider.notifier).fetchAnalytics(user.id);
    }
  }

  @override
  void dispose() {
    _barcodeInputController.dispose();
    _classifyController.dispose();
    _ocrFoodNameController.dispose();
    super.dispose();
  }

  // Camera Scanner launcher
  Future<void> _startCameraScan() async {
    var res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleBarcodeScannerPage(),
      ),
    );
    if (res is String && res != '-1' && res.isNotEmpty) {
      _barcodeInputController.text = res;
      _handleLookup(res);
    }
  }

  void _handleLookup(String barcode) {
    ref.read(barcodeProvider.notifier).lookupBarcode(barcode).then((_) {
      final state = ref.read(barcodeProvider);
      if (state.productData != null) {
        _showMealTypePicker(state.productData!);
      } else if (state.error != null) {
        _showManualFallbackDialog(barcode);
      }
    });
  }

  // Dialog to pick meal type to log
  void _showMealTypePicker(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) {
        String mealType = 'Breakfast';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Log Product to Meal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log "${product['name'] ?? 'Product'}" to your diary:'),
                  const SizedBox(height: 16),
                  const Text('MEAL TYPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: mealType,
                        isExpanded: true,
                        items: ['Breakfast', 'Lunch', 'Dinner', 'Snacks']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => mealType = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final user = ref.read(authProvider).user;
                    final nut = product['nutriments'] ?? {};
                    if (user != null) {
                      ref.read(barcodeProvider.notifier).logScannedMeal(
                        userId: user.id,
                        mealType: mealType,
                        productName: "${product['name']} (${product['brand'] ?? 'Unknown Brand'})",
                        calories: (nut['energy_kcal'] ?? 0.0).toDouble(),
                        protein: (nut['protein_g'] ?? 0.0).toDouble(),
                        carbs: (nut['carb_g'] ?? 0.0).toDouble(),
                        fat: (nut['fat_g'] ?? 0.0).toDouble(),
                      ).then((_) => _loadAnalytics());
                    }
                  },
                  child: const Text('Log & Find Alternatives'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog for manual barcode fallback entry
  void _showManualFallbackDialog(String barcode) {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final calCtrl = TextEditingController(text: '0');
    final protCtrl = TextEditingController(text: '0');
    final carbCtrl = TextEditingController(text: '0');
    final fatCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Manual Product Fallback'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Product not found in Open Food Facts cache. Enter details manually:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name')),
                const SizedBox(height: 8),
                TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: calCtrl, decoration: const InputDecoration(labelText: 'Calories (kcal)'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: protCtrl, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: carbCtrl, decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: fatCtrl, decoration: const InputDecoration(labelText: 'Fat (g)'), keyboardType: TextInputType.number)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(barcodeProvider.notifier).submitManualBarcode(
                  barcode: barcode,
                  productName: nameCtrl.text,
                  brand: brandCtrl.text,
                  calories: double.tryParse(calCtrl.text) ?? 0,
                  protein: double.tryParse(protCtrl.text) ?? 0,
                  carbs: double.tryParse(carbCtrl.text) ?? 0,
                  fat: double.tryParse(fatCtrl.text) ?? 0,
                ).then((_) {
                  final state = ref.read(barcodeProvider);
                  if (state.productData != null) {
                    _showMealTypePicker(state.productData!);
                  }
                });
              },
              child: const Text('Save Product'),
            ),
          ],
        );
      },
    );
  }

  // Image Picker launcher for OCR
  Future<void> _pickOcrImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedOcrImage = image;
      });
    }
  }

  Future<void> _handleOcrUpload() async {
    if (_selectedOcrImage == null) return;
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(ocrProvider.notifier).uploadOcrImage(
        filePath: _selectedOcrImage!.path,
        fileName: _selectedOcrImage!.name,
        mealType: _selectedOcrMealType,
        foodName: _ocrFoodNameController.text,
        userId: user.id,
      );
      _loadAnalytics();
    }
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
            _buildBarcodeCard(),
            const SizedBox(height: 24),
            _buildDietaryRuleCard(),
            const SizedBox(height: 24),
            _buildOcrCard(),
            const SizedBox(height: 24),
            _buildAnalyticsCard(),
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
                    onPressed: _startCameraScan,
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

  Widget _buildBarcodeCard() {
    final barcodeState = ref.watch(barcodeProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.center_focus_weak, color: AppColors.blueAction),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Barcode Scanner & Lookup',
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
              'Fetch product details from local cache or Open Food Facts.',
              style: TextStyle(color: AppColors.textMain, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text('PRODUCT BARCODE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeInputController,
                    decoration: const InputDecoration(hintText: 'e.g. 8901058002476'),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt_outlined),
                    onPressed: _startCameraScan,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: barcodeState.isLoading
                      ? null
                      : () => _handleLookup(_barcodeInputController.text),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                  child: barcodeState.isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Lookup'),
                ),
              ],
            ),
            if (barcodeState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('⚠️ ${barcodeState.error}', style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            ],
            if (barcodeState.logSuccessMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('✅ ${barcodeState.logSuccessMessage}', style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
            if (barcodeState.productData != null) ...[
              const SizedBox(height: 16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            barcodeState.productData!['product_name'] ?? barcodeState.productData!['name'] ?? 'Unknown Product',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (barcodeState.productData!['source'] ?? 'Cached').toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Brand: ${barcodeState.productData!['brand'] ?? '—'} | Grade: ${(barcodeState.productData!['nutrition_grade'] ?? '—').toUpperCase()}'),
                    const SizedBox(height: 4),
                    Text(
                      'Health Score: ${barcodeState.productData!['health_score'] != null ? barcodeState.productData!['health_score'].round() : '—'} (${barcodeState.productData!['health_category'] ?? '—'})',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purpleAction),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('NUTRITION PER 100G', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _nutritionGridItem('Energy', '${(barcodeState.productData!['nutriments']?['energy_kcal'] ?? 0).round()} kcal'),
                        _nutritionGridItem('Protein', '${barcodeState.productData!['nutriments']?['protein_g'] ?? 0}g'),
                        _nutritionGridItem('Carbs', '${barcodeState.productData!['nutriments']?['carb_g'] ?? 0}g'),
                        _nutritionGridItem('Fat', '${barcodeState.productData!['nutriments']?['fat_g'] ?? 0}g'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (barcodeState.alternatives != null && barcodeState.alternatives!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'RECOMMENDED HEALTHIER ALTERNATIVES',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary, letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),
              Column(
                children: barcodeState.alternatives!.map<Widget>((alt) {
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
                            Expanded(child: Text(alt['name'] ?? 'Alternative', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                            const SizedBox(width: 8),
                            Text('Rs. ${alt['price'] ?? '--'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(alt['reason'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(alt['comparison'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                children: [
                  TextSpan(text: 'Try: '),
                  TextSpan(text: '8901058002476 (Maggi)', style: TextStyle(color: AppColors.textLink)),
                  TextSpan(text: ' | '),
                  TextSpan(text: '1234567890123 (Mock)', style: TextStyle(color: AppColors.textLink)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutritionGridItem(String label, String val) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.bgLightCard,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMain), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDietaryRuleCard() {
    final classState = ref.watch(classificationProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_outlined, color: AppColors.blueAction),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dietary Rule Classifier',
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
              'Check ingredients against Jain, Vegetarian, Vegan, and Eggetarian rules.',
              style: TextStyle(color: AppColors.textMain, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text('INGREDIENTS (COMMA-SEPARATED)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _classifyController,
              decoration: const InputDecoration(hintText: 'e.g. potato, spinach, onion, chicken'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: classState.isLoading
                    ? null
                    : () => ref.read(classificationProvider.notifier).classifyIngredients(_classifyController.text),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.purpleAction),
                child: classState.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Analyze Ingredients'),
              ),
            ),
            if (classState.error != null) ...[
              const SizedBox(height: 16),
              Text(classState.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            if (classState.classificationData != null) ...[
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
                    _dietFlagRow('Vegan', classState.classificationData!['is_vegan'] ?? false),
                    _dietFlagRow('Vegetarian', classState.classificationData!['is_vegetarian'] ?? false),
                    _dietFlagRow('Jain', classState.classificationData!['is_jain'] ?? false),
                    _dietFlagRow('Eggetarian', classState.classificationData!['is_eggetarian'] ?? false),
                    if (classState.classificationData!['reasons'] != null &&
                        (classState.classificationData!['reasons'] as List).isNotEmpty) ...[
                      const Divider(),
                      const Text('Exclusion Warnings:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.error)),
                      const SizedBox(height: 4),
                      ...(classState.classificationData!['reasons'] as List).map((reason) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• $reason', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        );
                      }),
                    ] else ...[
                      const Divider(),
                      const Text('Perfect match! No exclusions detected.', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dietFlagRow(String label, bool val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            val ? '✅ Yes' : '❌ No',
            style: TextStyle(fontWeight: FontWeight.bold, color: val ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrCard() {
    final ocrState = ref.watch(ocrProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_alt_outlined, color: AppColors.blueAction),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'OCR Nutrition Label Scanner',
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
              'Upload a nutrition label image to extract macros and log it directly to your meals.',
              style: TextStyle(color: AppColors.textMain, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text('LABEL IMAGE FILE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickOcrImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Choose Image', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedOcrImage == null ? 'No file chosen' : _selectedOcrImage!.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                  ),
                ),
              ],
            ),
            if (_selectedOcrImage != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_selectedOcrImage!.path),
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MEAL TYPE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5)),
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
                            value: _selectedOcrMealType,
                            items: ['Breakfast', 'Lunch', 'Dinner', 'Snacks']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedOcrMealType = val);
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
                      const Text('FOOD NAME (OPTIONAL)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ocrFoodNameController,
                        decoration: const InputDecoration(hintText: 'e.g. Scanned Oats'),
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
                onPressed: _selectedOcrImage == null || ocrState.isLoading ? null : _handleOcrUpload,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueAction),
                child: ocrState.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Extract & Log Meal'),
              ),
            ),
            if (ocrState.error != null) ...[
              const SizedBox(height: 16),
              Text(ocrState.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            if (ocrState.ocrData != null) ...[
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
                    Text(
                      ocrState.ocrData!['status'] == 'success' ? '✅ OCR Success!' : '⚠️ OCR Fallback',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    if (ocrState.ocrData!['meal_logged'] == true)
                      const Text('Logged to your meals successfully!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    const Text('Parsed Nutrition details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('Calories: ${ocrState.ocrData!['parsed_nutrition']?['energy_kcal'] ?? 0} kcal'),
                    Text('Protein: ${ocrState.ocrData!['parsed_nutrition']?['protein_g'] ?? 0}g'),
                    Text('Carbs: ${ocrState.ocrData!['parsed_nutrition']?['carb_g'] ?? 0}g'),
                    Text('Fat: ${ocrState.ocrData!['parsed_nutrition']?['fat_g'] ?? 0}g'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard() {
    final analyticState = ref.watch(analyticsProvider);

    if (analyticState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final trend = analyticState.summaryData?['weekly_weight_trend']?.toStringAsFixed(1) ?? '0.0';
    final trendMsg = trend == '0.0' ? 'Stable weight' : 'Trend changing';
    
    final avgCal = analyticState.summaryData?['averages']?['calories']?.round().toString() ?? '0';
    final avgProt = analyticState.summaryData?['averages']?['protein']?.round().toString() ?? '0';
    final avgCarbs = analyticState.summaryData?['averages']?['carbs']?.round().toString() ?? '0';
    final avgFat = analyticState.summaryData?['averages']?['fat']?.round().toString() ?? '0';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: AppColors.blueAction),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Smart Nutrition Analytics',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weight Trend (Rate of Change)', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('$trend kg/week ($trendMsg)', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('calculated from your weight history logs', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('7-Day Nutrition Averages', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.2)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _macroStat('CALORIES', avgCal, AppColors.calories),
                _macroStat('PROTEIN', '${avgProt}g', AppColors.protein),
                _macroStat('CARBS', '${avgCarbs}g', AppColors.carbs),
                _macroStat('FAT', '${avgFat}g', AppColors.fat),
              ],
            ),
            const SizedBox(height: 24),
            const Text('View Metric History', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.2)),
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
                  value: 'Weekly Calories Average',
                  items: ['Weekly Calories Average'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) {},
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return Row(
                        children: [
                          Text('${(1.0 - index * 0.2).toStringAsFixed(1)}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          const SizedBox(width: 8),
                          Expanded(child: Container(height: 1, color: AppColors.border)),
                        ],
                      );
                    }),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        DateFormat('d MMM yyyy').format(DateTime.now()),
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroStat(String label, String value, Color color) {
    return Container(
      width: 64,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.bgLightCard,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textMain)),
        ],
      ),
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
