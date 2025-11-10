import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // IMPORT để decode Base64
import '../services/auth_service.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final _authService = AuthService();

  Future<void> _signOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.orange),
            SizedBox(width: 12),
            Text('Đăng xuất'),
          ],
        ),
        content: Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await _authService.signOut();
    }
  }

  String _getProviderName(String providerId) {
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'password':
        return 'Email & Mật khẩu';
      case 'phone':
        return 'Số điện thoại';
      default:
        return providerId;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
      'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
      'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ⭐ BUILD AVATAR (hỗ trợ Base64 và URL)
  Widget _buildAvatar(String? photoURL) {
    ImageProvider? imageProvider;

    if (photoURL != null && photoURL.isNotEmpty) {
      if (photoURL.startsWith('data:image/')) {
        // ⭐ Base64
        try {
          final base64String = photoURL.split(',')[1];
          final bytes = base64Decode(base64String);
          imageProvider = MemoryImage(bytes);
        } catch (e) {
          print('❌ Lỗi decode Base64: $e');
        }
      } else {
        // URL (Google avatar)
        imageProvider = NetworkImage(photoURL);
      }
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.white,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Icon(
        Icons.person,
        size: 50,
        color: Colors.blue,
      )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Trang chủ'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Nút vào Profile
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header với gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue, Colors.blue.shade300],
                ),
              ),
              padding: EdgeInsets.fromLTRB(24, 40, 24, 60),
              child: Column(
                children: [
                  // ⭐ AVATAR VỚI STREAM TỪ FIRESTORE (real-time update)
                  StreamBuilder<DocumentSnapshot>(
                    stream: user != null
                        ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      String? photoURL;
                      String? displayName;

                      if (snapshot.hasData && snapshot.data!.exists) {
                        // Lấy từ Firestore (có thể là Base64)
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        photoURL = data['photoURL'];
                        displayName = data['displayName'];
                      } else {
                        // Fallback sang Firebase Auth
                        photoURL = user?.photoURL;
                        displayName = user?.displayName;
                      }

                      return Column(
                        children: [
                          // Avatar
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: _buildAvatar(photoURL),
                          ),
                          SizedBox(height: 16),

                          // Tên user
                          Text(
                            displayName ?? user?.displayName ?? 'Người dùng',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 8),

                  // Email
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.email ?? 'Không có email',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card thông tin
            Transform.translate(
              offset: Offset(0, -30),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Tiêu đề
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 12),
                            Text(
                              'Thông tin tài khoản',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // User ID
                        _buildInfoRow(
                          icon: Icons.fingerprint,
                          title: 'User ID',
                          value: user?.uid ?? 'Không có ID',
                          color: Colors.purple,
                        ),
                        Divider(height: 32),

                        // Email verified
                        _buildInfoRow(
                          icon: Icons.verified_user,
                          title: 'Email đã xác thực',
                          value: user?.emailVerified == true
                              ? 'Đã xác thực'
                              : 'Chưa xác thực',
                          color: user?.emailVerified == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                        Divider(height: 32),

                        // Provider
                        _buildInfoRow(
                          icon: Icons.login,
                          title: 'Phương thức đăng nhập',
                          value: user?.providerData.isNotEmpty == true
                              ? _getProviderName(
                              user!.providerData.first.providerId)
                              : 'Không xác định',
                          color: Colors.blue,
                        ),
                        Divider(height: 32),

                        // Ngày tạo tài khoản
                        _buildInfoRow(
                          icon: Icons.calendar_today,
                          title: 'Ngày tạo tài khoản',
                          value: user?.metadata.creationTime != null
                              ? _formatDate(user!.metadata.creationTime!)
                              : 'Không xác định',
                          color: Colors.teal,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Nút vào Profile
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
                icon: Icon(Icons.person),
                label: Text(
                  'Xem Profile Đầy Đủ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Nút đăng xuất
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: () => _signOut(context),
                icon: Icon(Icons.logout),
                label: Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}