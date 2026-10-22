abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue:
          'https://ironlog-app-george-c0hdakfvh6ggg2dp.italynorth-01.azurewebsites.net');
}
