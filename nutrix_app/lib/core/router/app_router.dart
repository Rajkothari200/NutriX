import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nutrix_app/providers/auth_provider.dart';
import 'package:nutrix_app/screens/auth/login_screen.dart';
import 'package:nutrix_app/screens/auth/register_screen.dart';
import 'package:nutrix_app/screens/home/home_screen.dart';
import 'package:nutrix_app/screens/recipes/recipe_search_screen.dart';
import 'package:nutrix_app/screens/recipes/recipe_detail_screen.dart';
import 'package:nutrix_app/screens/meal_plan/meal_plan_screen.dart';
import 'package:nutrix_app/screens/barcode/barcode_scanner_screen.dart';
import 'package:nutrix_app/screens/ai_coach/ai_coach_screen.dart';
import 'package:nutrix_app/screens/profile/profile_screen.dart';
import 'package:nutrix_app/screens/shell/main_shell.dart';
import 'package:nutrix_app/screens/homely/homely_builder_screen.dart';
import 'package:nutrix_app/screens/recipes/ai_recipe_gen_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return null;
      }

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/recipes',
            builder: (context, state) => const RecipeSearchScreen(),
          ),
          GoRoute(
            path: '/barcode',
            builder: (context, state) => const BarcodeScannerScreen(),
          ),
          GoRoute(
            path: '/homely',
            builder: (context, state) => const HomelyBuilderScreen(),
          ),
          GoRoute(
            path: '/ai-coach',
            builder: (context, state) => const AiCoachScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/meal-plan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MealPlanScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/ai-recipe-gen',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AiRecipeGenScreen(),
      ),
      GoRoute(
        path: '/recipe/:code',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RecipeDetailScreen(
          recipeCode: state.pathParameters['code']!,
        ),
      ),
    ],
  );
});
