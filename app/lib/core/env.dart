/// Build-time configuration, passed with `--dart-define` or
/// `--dart-define-from-file`. Only public values belong here: the
/// Supabase URL and anon key are safe to ship because RLS guards the data.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// App-wide time zone for the weekly challenge window.
  static const challengeTimeZone = String.fromEnvironment(
    'CHALLENGE_TZ',
    defaultValue: 'Europe/London',
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
