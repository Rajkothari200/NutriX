import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/recipes')) return 1;
    if (location.startsWith('/barcode')) return 2;
    if (location.startsWith('/homely')) return 3;
    if (location.startsWith('/ai-coach')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/recipes');
        break;
      case 2:
        context.go('/barcode');
        break;
      case 3:
        context.go('/homely');
        break;
      case 4:
        context.go('/ai-coach');
        break;
    }
  }

  void _showProfileBottomSheet(BuildContext context, WidgetRef ref, String name, String email, String firstLetter) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.blueAction.withValues(alpha: 0.15),
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blueAction,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(authProvider.notifier).logout();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[700],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _getSelectedIndex(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = user?.name ?? 'Chaitya';
    final userEmail = user?.email ?? 'chaitya@example.com';
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'C';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgLightCard,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'NutriX',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              icon: const Icon(Icons.nightlight_round, size: 18, color: AppColors.textMuted),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showProfileBottomSheet(context, ref, userName, userEmail, firstLetter),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.blueAction.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.blueAction.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  firstLetter,
                  style: const TextStyle(
                    color: AppColors.blueAction,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgLightCard,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(context, index),
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedItemColor: AppColors.blueAction,
          unselectedItemColor: AppColors.textDim,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, height: 1.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, height: 1.5),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home, color: AppColors.blueAction)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.kitchen_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.kitchen, color: AppColors.blueAction)),
              label: 'Kitchen',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.qr_code_scanner_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.qr_code_scanner, color: AppColors.blueAction)),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_work_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_work, color: AppColors.blueAction)),
              label: 'Homely',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.chat_bubble_outline)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.chat_bubble, color: AppColors.blueAction)),
              label: 'Coach',
            ),
          ],
        ),
      ),
    );
  }
}
