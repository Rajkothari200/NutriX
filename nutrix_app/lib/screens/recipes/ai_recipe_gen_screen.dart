import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

class AiRecipeGenScreen extends ConsumerStatefulWidget {
  const AiRecipeGenScreen({super.key});

  @override
  ConsumerState<AiRecipeGenScreen> createState() => _AiRecipeGenScreenState();
}

class _AiRecipeGenScreenState extends ConsumerState<AiRecipeGenScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  String? _generatedRecipe;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Recipe Generator'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe what you want to eat, and our AI will instantly generate a custom recipe with macros.',
              style: TextStyle(color: AppColors.textDarkMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g. A high-protein vegetarian breakfast that takes under 15 minutes to make...',
                filled: true,
                fillColor: AppColors.bgDarkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _generateRecipe,
                icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(_isLoading ? 'Generating...' : 'Generate Recipe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_generatedRecipe != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgDarkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Generated Recipe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    Text(_generatedRecipe!, style: const TextStyle(height: 1.6)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _generateRecipe() {
    if (_promptController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _generatedRecipe = "1. Mash 1 cup of paneer and mix with diced onions and tomatoes.\\n2. Add salt, pepper, and a pinch of turmeric.\\n3. Scramble in a pan with 1 tsp of olive oil for 5 minutes.\\n4. Serve hot with whole wheat toast.\\n\\n**Nutrition**: 320 kcal | 22g Protein | 15g Carbs | 18g Fat";
        });
      }
    });
  }
}
