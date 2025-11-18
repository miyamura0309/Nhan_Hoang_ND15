import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // ============================
  // Email & Password
  // ============================

  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      _logger.e('Email Registration Error: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      _logger.e('Email Sign In Error: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      return null;
    }
  }

  // ============================
  // Google Sign-In
  // ============================

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId: '87411107443-dv0scbsioue4qbnbvds4lvv102ntpauh.apps.googleusercontent.com',
      ).signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      _logger.e('Google Sign In Error: $e');
      return null;
    }
  }

  // ============================
  // Facebook Sign-In
  // ============================

  Future<User?> signInWithFacebook() async {
    try {
      if (kIsWeb) {
        // CHO WEB: Dùng Firebase signInWithPopup
        _logger.i('Using Web Facebook login with Firebase popup...');
        
        FacebookAuthProvider facebookProvider = FacebookAuthProvider();
        facebookProvider.addScope('email');
        facebookProvider.addScope('public_profile');
  
        UserCredential userCredential = 
            await _auth.signInWithPopup(facebookProvider);
        
        _logger.i('Facebook login success: ${userCredential.user?.email}');

        return userCredential.user;
        
      } else {
        _logger.i('Using Mobile Facebook login...');
        
        final LoginResult result = await FacebookAuth.instance.login(
          permissions: ['email', 'public_profile'],
        );

        if (result.status == LoginStatus.success) {
          final accessToken = result.accessToken?.tokenString;

          if (accessToken == null || accessToken.isEmpty) {
            _logger.e('Facebook access token is null or empty');
            return null;
          }

          final OAuthCredential credential =
              FacebookAuthProvider.credential(accessToken);

          UserCredential userCredential =
              await _auth.signInWithCredential(credential);
          
          _logger.i('Facebook login success: ${userCredential.user?.email}');
          return userCredential.user;
        } else if (result.status == LoginStatus.cancelled) {
          _logger.w('Facebook login cancelled by user.');
          return null;
        } else {
          _logger.e('Facebook login failed: ${result.message}');
          return null;
        }
      }
    } catch (e) {
      _logger.e('Facebook Sign In Error: $e');
      return null;
    }
  }
  // ============================
  // Sign Out
  // ============================

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _logger.i('User signed out successfully.');
    } catch (e) {
      _logger.e('Sign Out Error: $e');
    }
  }

  // ============================
  // Current User
  // ============================

  User? get currentUser => _auth.currentUser;
}
