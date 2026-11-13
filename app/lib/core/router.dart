import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/challenge/presentation/this_week_screen.dart';
import 'providers.dart';
import 'widgets/status_screens.dart';

abstract final class Routes {
  static const offline = '/offline';
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const onboarding = '/onboarding';
  static const home = '/';
}

/// Where the user should be, given backend/auth/profile state.
/// Returns null when [location] is already acceptable.
@visibleForTesting
String? authRedirect({
  required bool backendConfigured,
  required AsyncValue<String?> auth,
  required AsyncValue<Object?> profile,
  required bool profileOnboarded,
  required String location,
}) {
  String? go(String target) => location == target ? null : target;

  if (!backendConfigured) return go(Routes.offline);
  if (auth.isLoading && !auth.hasValue) return go(Routes.splash);
  if (auth.value == null) return go(Routes.signIn);
  if (profile.isLoading && !profile.hasValue) return go(Routes.splash);
  if (!profileOnboarded) return go(Routes.onboarding);
  // Signed in and onboarded: keep them out of the auth flow.
  const authFlow = {
    Routes.offline,
    Routes.splash,
    Routes.signIn,
    Routes.onboarding,
  };
  return authFlow.contains(location) ? Routes.home : null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final backendConfigured = ref.watch(backendConfiguredProvider);
  final refresh = ValueNotifier(0);
  ref.onDispose(refresh.dispose);

  if (backendConfigured) {
    ref.listen(authStateProvider, (_, _) => refresh.value++);
    ref.listen(myProfileProvider, (_, _) => refresh.value++);
  }

  return GoRouter(
    initialLocation: backendConfigured ? Routes.splash : Routes.offline,
    refreshListenable: refresh,
    redirect: (context, state) {
      if (!backendConfigured) {
        return state.matchedLocation == Routes.offline ? null : Routes.offline;
      }
      final profile = ref.read(myProfileProvider);
      return authRedirect(
        backendConfigured: true,
        auth: ref.read(authStateProvider),
        profile: profile,
        profileOnboarded: profile.value?.isOnboarded ?? false,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(path: Routes.offline, builder: (_, _) => const OfflineScreen()),
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: Routes.home, builder: (_, _) => const ThisWeekScreen()),
    ],
  );
});
