// Firebase initialization status utility
class FirebaseStatus {
  static bool _isInitialized = false;
  static String? _errorMessage;
  
  static void setInitialized(bool initialized, [String? error]) {
    _isInitialized = initialized;
    _errorMessage = error;
  }
  
  static bool get isInitialized => _isInitialized;
  static String? get errorMessage => _errorMessage;
}
