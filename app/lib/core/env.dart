/// Build-time configuration, passed with `--dart-define` or
/// `--dart-define-from-file`. Only public values belong here: the
/// Supabase URL and anon key are safe to ship because RLS guards the data.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Show the Google button only once the OAuth client is set up in Supabase.
  static const googleSignInEnabled = bool.fromEnvironment('GOOGLE_SIGN_IN');

  /// App-wide time zone for the weekly challenge window.
  static const challengeTimeZone = String.fromEnvironment(
    'CHALLENGE_TZ',
    defaultValue: 'Europe/London',
  );

  /// Where Supabase sends the user back to after OAuth on Android/iOS.
  static const mobileAuthRedirect = 'com.questly.questly://login-callback';

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
