import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:retrieva/core/router/app_routes.dart';
import 'package:retrieva/models/item_model.dart';
import 'package:retrieva/screens/browse_screen.dart';
import 'package:retrieva/screens/home_screen.dart';
import 'package:retrieva/screens/item_details_screen.dart';

import 'package:retrieva/screens/login_screen.dart';
import 'package:retrieva/screens/my_items_screen.dart';
import 'package:retrieva/screens/pick_loc_screen.dart';
import 'package:retrieva/screens/signup_screen.dart';

import '../../screens/post_item_screen.dart';
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.items,
    routes: [

      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.edit,
        builder: (context, state) {
          final item = state.extra as Item?;

        return PostItemScreen(existingItem: item,);}
      ),
      GoRoute(
          path: AppRoutes.post,
          builder: (context, state) =>


            const PostItemScreen()
      ),
      GoRoute(
          path: AppRoutes.detail,
          builder: (context, state) {
            final item = state.extra as Item?;

            return ItemDetailScreen(item: item,);}
      ),
      GoRoute(
        path: AppRoutes.items,
        builder: (context, state) => const BrowseScreen(),
      ),
      GoRoute(
        path: AppRoutes.map,
        builder: (context, state) => const LocationPickerScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.listing,
        builder: (context, state) => const MyListingsScreen(),
      ),
    ],
  );
});
