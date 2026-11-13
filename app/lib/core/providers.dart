import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Whether the app was built with Supabase config. Overridden in tests.
final backendConfiguredProvider = Provider<bool>((ref) => Env.hasSupabase);

/// The Supabase client. Only read this from repositories, never from widgets,
/// so tests can swap repositories for fakes.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);
