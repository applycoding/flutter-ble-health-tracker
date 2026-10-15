/// Runtime configuration. Firebase values come from `--dart-define` so the
/// demo runs when they are absent.
class AppConfig {
  const AppConfig({
    this.startInDemoMode = true,
    this.firebaseProjectId = '',
    this.firebaseApiKey = '',
  });

  static const environment = AppConfig(
    startInDemoMode: bool.fromEnvironment('DEMO_MODE', defaultValue: true),
    firebaseProjectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    firebaseApiKey: String.fromEnvironment('FIREBASE_API_KEY'),
  );

  final bool startInDemoMode;
  final String firebaseProjectId;
  final String firebaseApiKey;

  bool get firebaseConfigured =>
      firebaseProjectId.isNotEmpty && firebaseApiKey.isNotEmpty;
}
