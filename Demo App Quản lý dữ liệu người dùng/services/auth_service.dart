import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_profile_service.dart';
import 'failed_login_service.dart'; // ⭐ THÊM

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: null,
  );
  final UserProfileService _profileService = UserProfileService();
  final FailedLoginService _failedLoginService = FailedLoginService(); // ⭐ THÊM

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ⭐ VALIDATE MẬT KHẨU MẠNH
  String? validateStrongPassword(String password) {
    if (password.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ hoa';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ thường';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Mật khẩu phải có ít nhất 1 số';
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt';
    }

    return null;
  }

  // Đăng ký với Email & Password
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      // ⭐ VALIDATE MẬT KHẨU MẠNH
      final validationError = validateStrongPassword(password);
      if (validationError != null) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: validationError,
        );
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Tạo profile trong Firestore
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
      // ⭐ KIỂM TRA TÀI KHOẢN CÓ BỊ KHÓA KHÔNG
      final isLocked = await _failedLoginService.isAccountLocked(email);

      if (isLocked) {
        final remaining = await _failedLoginService.getRemainingLockTime(email);
        final minutes = remaining?.inMinutes ?? 0;
        final seconds = (remaining?.inSeconds ?? 0) % 60;

        throw FirebaseAuthException(
          code: 'account-locked',
          message: 'Tài khoản bị khóa do đăng nhập sai 5 lần. Vui lòng thử lại sau ${minutes}p${seconds}s',
        );
      }

      // Thử đăng nhập
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ⭐ ĐĂNG NHẬP THÀNH CÔNG → RESET FAILED ATTEMPTS
      await _failedLoginService.resetFailedAttempts(email);

      // Cập nhật last login
      if (userCredential.user != null) {
        await _profileService.createOrUpdateProfile(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // ⭐ ĐĂNG NHẬP THẤT BẠI → GHI NHẬN
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        final attempts = await _failedLoginService.recordFailedAttempt(email);

        if (attempts >= 5) {
          throw FirebaseAuthException(
            code: 'account-locked',
            message: 'Tài khoản bị khóa 5 phút do đăng nhập sai 5 lần',
          );
        } else if (attempts > 0) {
          final remaining = 5 - attempts;
          throw FirebaseAuthException(
            code: e.code,
            message: 'Sai mật khẩu. Còn $remaining lần thử',
          );
        }
      }

      print('❌ Lỗi đăng nhập: $e');
      rethrow;
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

      // Tạo/cập nhật profile trong Firestore
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

  // Gửi email xác thực
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // ⭐ ĐỔI MẬT KHẨU (yêu cầu mật khẩu cũ)
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;

      if (user == null || user.email == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      // Validate mật khẩu mới
      final validationError = validateStrongPassword(newPassword);
      if (validationError != null) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: validationError,
        );
      }

      // Xác thực lại với mật khẩu hiện tại
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Đổi mật khẩu
      await user.updatePassword(newPassword);

      print('✅ Đổi mật khẩu thành công');
    } catch (e) {
      print('❌ Lỗi đổi mật khẩu: $e');
      rethrow;
    }
  }

  // ⭐ KIỂM TRA XEM USER CÓ PHẢI TÀI KHOẢN EMAIL/PASSWORD KHÔNG
  bool isPasswordProvider() {
    final user = _auth.currentUser;
    if (user == null) return false;

    return user.providerData.any((provider) => provider.providerId == 'password');
  }
}