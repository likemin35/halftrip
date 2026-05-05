class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.fastApiBaseUrl,
    required this.useMockLogin,
    required this.useMockApi,
    required this.mapProvider,
    required this.kakaoMapAppKey,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8080/api',
      ),
      fastApiBaseUrl: String.fromEnvironment(
        'FASTAPI_BASE_URL',
        defaultValue: 'http://localhost:8000',
      ),
      useMockLogin: bool.fromEnvironment('USE_MOCK_LOGIN', defaultValue: true),
      useMockApi: bool.fromEnvironment('USE_MOCK_API', defaultValue: false),
      mapProvider: String.fromEnvironment('MAP_PROVIDER', defaultValue: 'mock'),
      kakaoMapAppKey: String.fromEnvironment('KAKAO_MAP_APP_KEY', defaultValue: ''),
    );
  }

  final String apiBaseUrl;
  final String fastApiBaseUrl;
  final bool useMockLogin;
  final bool useMockApi;
  final String mapProvider;
  final String kakaoMapAppKey;

  bool get canUseKakaoMap =>
      mapProvider.toLowerCase() == 'kakao' && kakaoMapAppKey.isNotEmpty;
}
