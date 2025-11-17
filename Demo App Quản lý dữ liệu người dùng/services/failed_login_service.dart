import 'package:cloud_firestore/cloud_firestore.dart';

class FailedLoginService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection để lưu failed attempts
  CollectionReference get _failedAttemptsCollection =>
      _firestore.collection('failed_login_attempts');

  // Kiểm tra xem tài khoản có bị khóa không
  Future<bool> isAccountLocked(String email) async {
    try {
      final doc = await _failedAttemptsCollection.doc(email).get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final lockedUntil = (data['lockedUntil'] as Timestamp?)?.toDate();

      // Nếu có lockedUntil và chưa hết thời gian khóa
      if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
        return true;
      }

      // Nếu đã hết thời gian khóa, reset attempts
      if (lockedUntil != null && DateTime.now().isAfter(lockedUntil)) {
        await _resetFailedAttempts(email);
        return false;
      }

      return false;
    } catch (e) {
      print('❌ Error checking account lock: $e');
      return false;
    }
  }

  // Lấy thời gian còn lại bị khóa
  Future<Duration?> getRemainingLockTime(String email) async {
    try {
      final doc = await _failedAttemptsCollection.doc(email).get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      final lockedUntil = (data['lockedUntil'] as Timestamp?)?.toDate();

      if (lockedUntil == null) return null;

      final remaining = lockedUntil.difference(DateTime.now());

      if (remaining.isNegative) return null;

      return remaining;
    } catch (e) {
      print('❌ Error getting remaining lock time: $e');
      return null;
    }
  }

  // Ghi nhận lần đăng nhập thất bại
  Future<int> recordFailedAttempt(String email) async {
    try {
      final docRef = _failedAttemptsCollection.doc(email);
      final doc = await docRef.get();

      int currentAttempts = 0;

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        currentAttempts = data['attempts'] as int? ?? 0;

        // Kiểm tra xem có lockedUntil chưa hết hạn không
        final lockedUntil = (data['lockedUntil'] as Timestamp?)?.toDate();
        if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
          return currentAttempts; // Đã bị khóa, không tăng attempts nữa
        }
      }

      currentAttempts++;

      // Nếu đạt 5 lần, khóa tài khoản 5 phút
      if (currentAttempts >= 5) {
        final lockUntil = DateTime.now().add(Duration(minutes: 5));

        await docRef.set({
          'email': email,
          'attempts': currentAttempts,
          'lockedUntil': Timestamp.fromDate(lockUntil),
          'lastAttempt': FieldValue.serverTimestamp(),
        });

        // Lưu log vào Firestore để admin theo dõi (optional)
        try {
          await _firestore.collection('security_logs').add({
            'type': 'account_locked',
            'email': email,
            'timestamp': FieldValue.serverTimestamp(),
            'reason': '5 failed login attempts',
            'lockDuration': '5 minutes',
          });
          print('⚠️ Account locked for: $email');
        } catch (e) {
          print('❌ Error logging security event: $e');
        }

        return currentAttempts;
      }

      // Cập nhật số lần thất bại
      await docRef.set({
        'email': email,
        'attempts': currentAttempts,
        'lastAttempt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return currentAttempts;
    } catch (e) {
      print('❌ Error recording failed attempt: $e');
      return 0;
    }
  }

  // Reset failed attempts sau khi đăng nhập thành công
  Future<void> resetFailedAttempts(String email) async {
    await _resetFailedAttempts(email);
  }

  Future<void> _resetFailedAttempts(String email) async {
    try {
      await _failedAttemptsCollection.doc(email).delete();
      print('✅ Reset failed attempts for: $email');
    } catch (e) {
      print('❌ Error resetting failed attempts: $e');
    }
  }

  // Lấy số lần thất bại hiện tại
  Future<int> getFailedAttempts(String email) async {
    try {
      final doc = await _failedAttemptsCollection.doc(email).get();

      if (!doc.exists) return 0;

      final data = doc.data() as Map<String, dynamic>;
      return data['attempts'] as int? ?? 0;
    } catch (e) {
      print('❌ Error getting failed attempts: $e');
      return 0;
    }
  }
}