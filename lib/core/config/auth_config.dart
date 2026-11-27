/// Optional account (PRD_v9 section 6). All values come from
/// `--dart-define` at build time and are never committed.
abstract final class AuthConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// The project's publishable key (or the legacy anon key). Public by
  /// design: row level security protects the data.
  static const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  /// The Google "Web application" OAuth client (needed on Android and iOS so
  /// the ID token is issued for Supabase).
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// The Google "iOS" OAuth client.
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  /// Sign in with Apple on Android, through Apple's web page. Off until the
  /// owner has set up the Apple Services ID in Supabase
  /// (docs/auth-setup.md); pass `--dart-define=APPLE_ON_ANDROID=true`.
  static const appleOnAndroid = bool.fromEnvironment('APPLE_ON_ANDROID');

  /// Where Apple's web sign-in returns to the app. Must be listed in
  /// Supabase > Authentication > URL Configuration > Redirect URLs.
  static const authRedirect = 'gitaapp://open/login-callback';

  /// Without a Supabase project the app has no account features at all.
  static bool get enabled => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
