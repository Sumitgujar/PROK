// Base URL for the FastAPI backend.
// On Android emulator, use 10.0.2.2 instead of localhost.
// On iOS simulator or physical device, use your machine's LAN IP.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000', // Android emulator default
);

const String kTokenKey = 'prok_token';
const String kUserKey = 'prok_user';

/// Named routes
class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const attendance = '/attendance';
  static const documents = '/documents';
  static const scholarships = '/scholarships';
  static const courses = '/courses';
}
