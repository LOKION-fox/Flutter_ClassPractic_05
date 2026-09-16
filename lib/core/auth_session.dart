class AuthSession {
  String? accessToken;
  String? refreshToken;

  bool get isAuthorized => accessToken != null && accessToken!.isNotEmpty;

  void clear() {
    accessToken = null;
    refreshToken = null;
  }
}
