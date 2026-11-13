import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Initialises Supabase when config is present. Returns whether it did,
/// so the app can still start (showing a placeholder) without keys.
Future<bool> initSupabase() async {
  if (!Env.hasSupabase) return false;
  // supabase_flutter renamed anonKey -> publishableKey; the anon (or
  // sb_publishable_...) key from `supabase status` works for either.
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );
  return true;
}
