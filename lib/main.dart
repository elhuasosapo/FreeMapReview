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
import 'screens/locations_list_screen.dart';
import 'providers/local_auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConstants.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final isLoggedIn = await loadLocalAuth();

  runApp(ProviderScope(
    overrides: [
      localAuthProvider.overrideWith((ref) => isLoggedIn),
      localUserProvider.overrideWith((ref) => isLoggedIn ? 'admin' : null),
    ],
    child: const FreeMapReviewApp(),
  ));
}

class FreeMapReviewApp extends ConsumerStatefulWidget {
  const FreeMapReviewApp({super.key});

  @override
  ConsumerState<FreeMapReviewApp> createState() => _FreeMapReviewAppState();
}

class _FreeMapReviewAppState extends ConsumerState<FreeMapReviewApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    final authNotifier = ref.read(localAuthNotifierProvider);
    final router = GoRouter(
      refreshListenable: authNotifier,
      redirect: (context, state) {
        final isLoggedIn = ref.read(localAuthProvider);
        final isLoginRoute = state.matchedLocation == '/login-local';

        if (!isLoggedIn && !isLoginRoute) {
          return '/login-local';
        }
        if (isLoggedIn && isLoginRoute) {
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final lat = state.uri.queryParameters['lat'];
            final lng = state.uri.queryParameters['lng'];
            final target = (lat != null && lng != null)
                ? LatLng(double.parse(lat), double.parse(lng))
                : null;
            return MapScreen(initialTarget: target);
          },
        ),
        GoRoute(
          path: '/login-local',
          builder: (_, __) => const LocalLoginScreen(),
        ),
        GoRoute(
          path: '/locations',
          builder: (_, __) => const LocationsListScreen(),
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
            LatLng? position;
            if (lat != null && lng != null) {
              try {
                final latVal = double.parse(lat);
                final lngVal = double.parse(lng);
                // Validazione range coordinate
                if (latVal >= -90 && latVal <= 90 && lngVal >= -180 && lngVal <= 180) {
                  position = LatLng(latVal, lngVal);
                }
              } catch (e) {
                // Ignora coordinate invalidhe
              }
            }
            return AddLocationScreen(initialPosition: position);
          },
        ),
      ],
    );

    return router;
  }

  @override
  Widget build(BuildContext context) {
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
      routerConfig: _router,
    );
  }
}
