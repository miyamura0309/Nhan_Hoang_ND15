import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_profile_service.dart'; // ⭐ IMPORT SERVICE MỚI

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: null,
  );
  final UserProfileService _profileService = UserProfileService(); // ⭐ THÊM

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng ký với Email & Password
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ⭐ TẠO PROFILE TRONG FIRESTORE
      if (userCredential.user != null) {
        await _profileService.createOrUpdateProfile(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('❌ Lỗi đăng ký: $e');
      rethrow;
    }
  }

  // Đăng nhập với Email & Password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ⭐ CẬP NHẬT LAST LOGIN
      if (userCredential.user != null) {
        await _profileService.createOrUpdateProfile(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('❌ Lỗi đăng nhập: $e');
      rethrow;
    }
  }

  // Đăng nhập với Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Hiển thị màn hình chọn tài khoản Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Nếu user hủy đăng nhập
      if (googleUser == null) {
        return null;
      }

      // Lấy thông tin xác thực
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Tạo credential cho Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Đăng nhập vào Firebase với credential
      final userCredential = await _auth.signInWithCredential(credential);

      // ⭐ TẠO/CẬP NHẬT PROFILE TRONG FIRESTORE
      if (userCredential.user != null) {
        await _profileService.createOrUpdateProfile(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('❌ Lỗi đăng nhập Google: $e');
      rethrow;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Reset password
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ⭐ GỬI EMAIL XÁC THỰC
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
}