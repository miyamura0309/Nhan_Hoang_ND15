import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  // 1️⃣ TẠO hoặc CẬP NHẬT profile sau khi đăng nhập
  Future<void> createOrUpdateProfile(User user) async {
    try {
      final docRef = _usersCollection.doc(user.uid);
      final doc = await docRef.get();

      // Xác định login provider
      String provider = 'password';
      if (user.providerData.isNotEmpty) {
        provider = user.providerData.first.providerId;
      }

      if (doc.exists) {
        // ✅ User đã có profile → chỉ update lastLoginAt

        // Kiểm tra xem user đã custom avatar chưa
        final existingData = doc.data() as Map<String, dynamic>;
        final existingPhotoURL = existingData['photoURL'];
        final isCustomAvatar = existingPhotoURL != null &&
            existingPhotoURL.contains('firebasestorage');

        await docRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          // Với Google login, chỉ cập nhật displayName
          if (provider == 'google.com' && user.displayName != null)
            'displayName': user.displayName,
          // ⭐ CHỈ sync photoURL từ Google NÊU CHƯA CUSTOM
          if (provider == 'google.com' &&
              user.photoURL != null &&
              !isCustomAvatar)
            'photoURL': user.photoURL,
        });
        print('✅ Updated lastLoginAt for user: ${user.uid}');
      } else {
        // ✅ User chưa có profile → tạo mới
        final profile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'Người dùng',
          photoURL: user.photoURL,
          loginProvider: provider,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await docRef.set(profile.toMap());
        print('✅ Created profile for user: ${user.uid}');
      }
    } catch (e) {
      print('❌ Error creating/updating profile: $e');
      rethrow;
    }
  }

  // 2️⃣ LẤY profile theo UID
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();

      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error getting profile: $e');
      return null;
    }
  }

  // 3️⃣ STREAM profile (real-time updates)
  Stream<UserProfile?> getUserProfileStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // 4️⃣ CẬP NHẬT profile (chỉ các field được phép)
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? phoneNumber,
    String? bio,
    String? address,
    DateTime? dateOfBirth,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (displayName != null && displayName.isNotEmpty) {
        updates['displayName'] = displayName;
        // Đồng bộ với Firebase Auth
        await _auth.currentUser?.updateDisplayName(displayName);
      }
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (bio != null) updates['bio'] = bio;
      if (address != null) updates['address'] = address;
      if (dateOfBirth != null) {
        updates['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      }

      if (updates.isNotEmpty) {
        await _usersCollection.doc(uid).update(updates);
        print('✅ Profile updated successfully');
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      rethrow;
    }
  }

  // 5️⃣ CẬP NHẬT avatar (Base64 hoặc URL)
  Future<void> updatePhotoURL(String uid, String photoURL) async {
    try {
      // ⭐ Có thể là Base64 hoặc URL, Firestore chấp nhận cả 2
      await _usersCollection.doc(uid).update({'photoURL': photoURL});

      // Chỉ sync với Firebase Auth nếu là URL (không phải Base64)
      if (!photoURL.startsWith('data:image/')) {
        await _auth.currentUser?.updatePhotoURL(photoURL);
      }

      print('✅ Photo URL updated successfully');
    } catch (e) {
      print('❌ Error updating photo URL: $e');
      rethrow;
    }
  }

  // 6️⃣ XÓA profile và tài khoản
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Xóa dữ liệu Firestore
        await _usersCollection.doc(user.uid).delete();
        // Xóa tài khoản Auth
        await user.delete();
        print('✅ User account deleted successfully');
      }
    } catch (e) {
      print('❌ Error deleting account: $e');
      rethrow;
    }
  }

  // 7️⃣ KIỂM TRA profile có tồn tại không
  Future<bool> profileExists(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking profile: $e');
      return false;
    }
  }

  // 8️⃣ LẤY danh sách tất cả users (cho admin - optional)
  Future<List<UserProfile>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _usersCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting all users: $e');
      return [];
    }
  }

  // 9️⃣ TÌM KIẾM user theo email
  Future<List<UserProfile>> searchUsersByEmail(String email) async {
    try {
      QuerySnapshot snapshot = await _usersCollection
          .where('email', isGreaterThanOrEqualTo: email)
          .where('email', isLessThanOrEqualTo: email + '\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error searching users: $e');
      return [];
    }
  }
}