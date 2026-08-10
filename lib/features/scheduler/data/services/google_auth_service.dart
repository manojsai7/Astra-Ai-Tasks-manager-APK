import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

/// Handles Google Authentication and supplies authenticated HTTP clients
/// for Gmail and Calendar APIs.
class GoogleAuthService {
  static final GoogleAuthService instance = GoogleAuthService._internal();
  GoogleAuthService._internal() {
    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
      serverClientId: defaultClientIdPlaceholder,
    );
  }

  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/calendar.readonly',
  ];

  /// 🔑 Web Client ID from Google Cloud Console / google-services.json
  static const String defaultClientIdPlaceholder = "1016085578580-ugurj686fc753v8k6tqs0o314qkar8p1.apps.googleusercontent.com";

  late GoogleSignIn _googleSignIn;

  GoogleSignInAccount? _currentUser;
  auth.AuthClient? _authClient;

  void initialize({String? clientId, String? serverClientId}) {
    final effectiveClientId = (clientId != null && clientId.isNotEmpty)
        ? clientId
        : (defaultClientIdPlaceholder != "YOUR_GOOGLE_CLIENT_ID_HERE" ? defaultClientIdPlaceholder : null);

    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
      clientId: effectiveClientId,
      serverClientId: serverClientId ?? effectiveClientId,
    );
  }

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  /// Stream of user sign-in state changes.
  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;

  /// Silently attempts to sign in a previously authenticated user.
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        _authClient = await _googleSignIn.authenticatedClient();
      }
      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  /// Initiates interactive Google Sign-In.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        _authClient = await _googleSignIn.authenticatedClient();
      }
      return _currentUser;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtains an authenticated HTTP client for googleapis calls.
  Future<auth.AuthClient?> getAuthenticatedClient() async {
    if (_authClient != null) return _authClient;
    _currentUser ??= await _googleSignIn.signInSilently();
    if (_currentUser != null) {
      _authClient = await _googleSignIn.authenticatedClient();
    }
    return _authClient;
  }

  /// Signs out the user.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _authClient = null;
  }
}
