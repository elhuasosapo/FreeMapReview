import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'config/constants.dart';
import 'screens/map_screen.dart';
import 'screens/location_detail_screen.dart';
import 'screens/add_review_screen.dart';
import 'screens/add_location_screen.dart';
import 'screens/local_login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const ProviderScope(child: FreeMapReviewApp()));
}

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const MapScreen(),
    ),
    GoRoute(
      path: '/login-local',
      builder: (_, __) => const LocalLoginScreen(),
    ),
    GoRoute(
      path: '/location/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return LocationDetailScreen(locationId: id);
      },
    ),
    GoRoute(
      path: '/location/:id/review',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AddReviewScreen(locationId: id);
      },
    ),
    GoRoute(
      path: '/add-location',
      builder: (context, state) {
        final lat = state.uri.queryParameters['lat'];
        final lng = state.uri.queryParameters['lng'];
        final position = lat != null && lng != null
            ? LatLng(double.parse(lat), double.parse(lng))
            : null;
        return AddLocationScreen(initialPosition: position);
      },
    ),
  ],
);

class FreeMapReviewApp extends ConsumerWidget {
  const FreeMapReviewApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
