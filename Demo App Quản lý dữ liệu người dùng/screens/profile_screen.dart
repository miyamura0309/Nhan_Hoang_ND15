import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'dart:convert';

class ProfileScreen extends StatelessWidget {
  final UserProfileService _profileService = UserProfileService();
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa cập nhật';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Chưa cập nhật';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _getInitials(String name) {
    List<String> names = name.trim().split(' ');
    if (names.isEmpty) return 'U';
    if (names.length == 1) return names[0][0].toUpperCase();
    return (names[0][0] + names[names.length - 1][0]).toUpperCase();
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

  // BUILD AVATAR (hỗ trợ Base64 và URL)
  Widget _buildAvatar(String? photoURL, String displayName) {
    ImageProvider? imageProvider;

    if (photoURL != null && photoURL.isNotEmpty) {
      if (photoURL.startsWith('data:image/')) {
        // Base64
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
          ? Text(
        _getInitials(displayName),
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(),
                ),
              );
            },
            tooltip: 'Chỉnh sửa profile',
          ),
        ],
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _profileService.getUserProfileStream(currentUser.uid),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải...'),
                ],
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Đã có lỗi xảy ra'),
                  SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileScreen()),
                      );
                    },
                    child: Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          // No data
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Không tìm thấy thông tin profile'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await _profileService.createOrUpdateProfile(currentUser);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileScreen()),
                      );
                    },
                    child: Text('Tạo profile'),
                  ),
                ],
              ),
            );
          }

          final profile = snapshot.data!;

          return SingleChildScrollView(
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
                        child: _buildAvatar(profile.photoURL, profile.displayName),
                      ),
                      SizedBox(height: 16),

                      // Display name
                      Text(
                        profile.displayName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Email với verified badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.email, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text(
                              profile.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            if (currentUser.emailVerified) ...[
                              SizedBox(width: 8),
                              Icon(
                                Icons.verified,
                                color: Colors.greenAccent,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Body với thông tin
                Transform.translate(
                  offset: Offset(0, -30),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card thông tin cá nhân
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person, color: Colors.blue),
                                    SizedBox(width: 12),
                                    Text(
                                      'Thông tin cá nhân',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),

                                if (profile.bio != null && profile.bio!.isNotEmpty)
                                  _buildInfoRow(
                                    icon: Icons.info_outline,
                                    title: 'Giới thiệu',
                                    value: profile.bio!,
                                    color: Colors.purple,
                                  ),

                                if (profile.bio != null && profile.bio!.isNotEmpty)
                                  Divider(height: 32),

                                _buildInfoRow(
                                  icon: Icons.phone,
                                  title: 'Số điện thoại',
                                  value: profile.phoneNumber ?? 'Chưa cập nhật',
                                  color: Colors.green,
                                ),
                                Divider(height: 32),

                                _buildInfoRow(
                                  icon: Icons.location_on,
                                  title: 'Địa chỉ',
                                  value: profile.address ?? 'Chưa cập nhật',
                                  color: Colors.orange,
                                ),
                                Divider(height: 32),

                                _buildInfoRow(
                                  icon: Icons.cake,
                                  title: 'Ngày sinh',
                                  value: _formatDate(profile.dateOfBirth),
                                  color: Colors.pink,
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        // Card thông tin tài khoản
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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

                                _buildInfoRow(
                                  icon: Icons.fingerprint,
                                  title: 'User ID',
                                  value: '${profile.uid.substring(0, 12)}...',
                                  color: Colors.purple,
                                ),
                                Divider(height: 32),

                                _buildInfoRow(
                                  icon: Icons.login,
                                  title: 'Phương thức đăng nhập',
                                  value: _getProviderName(profile.loginProvider),
                                  color: Colors.blue,
                                ),
                                Divider(height: 32),

                                _buildInfoRow(
                                  icon: currentUser.emailVerified
                                      ? Icons.verified_user
                                      : Icons.warning,
                                  title: 'Trạng thái email',
                                  value: currentUser.emailVerified
                                      ? 'Đã xác thực'
                                      : 'Chưa xác thực',
                                  color: currentUser.emailVerified
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                Divider(height: 32),

                                _buildInfoRow(
                                  icon: Icons.calendar_today,
                                  title: 'Ngày tạo tài khoản',
                                  value: _formatDate(profile.createdAt),
                                  color: Colors.teal,
                                ),
                                Divider(height: 32),

                                _buildInfoRow(
                                  icon: Icons.access_time,
                                  title: 'Đăng nhập lần cuối',
                                  value: _formatDateTime(profile.lastLoginAt),
                                  color: Colors.indigo,
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 24),

                        // Nút gửi email verification (nếu chưa verify)
                        if (!currentUser.emailVerified)
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await currentUser.sendEmailVerification();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ Email xác thực đã được gửi'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Lỗi: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.email),
                            label: Text('Gửi email xác thực'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                        if (!currentUser.emailVerified) SizedBox(height: 12),

                        // ⭐ NÚT ĐỔI MẬT KHẨU (chỉ hiện với tài khoản email/password)
                        if (_authService.isPasswordProvider())
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChangePasswordScreen(),
                                ),
                              );
                            },
                            icon: Icon(Icons.lock_reset),
                            label: Text('Đổi mật khẩu'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                        if (_authService.isPasswordProvider()) SizedBox(height: 12),

                        // Nút xóa tài khoản
                        OutlinedButton.icon(
                          onPressed: () => _showDeleteDialog(context),
                          icon: Icon(Icons.delete_forever, color: Colors.red),
                          label: Text(
                            'Xóa tài khoản',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                            side: BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ⭐ DIALOG XÓA TÀI KHOẢN - YÊU CẦU MẬT KHẨU
  void _showDeleteDialog(BuildContext context) {
    final currentUser = _auth.currentUser;
    final isPasswordProvider = _authService.isPasswordProvider();
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 12),
              Text('Xóa tài khoản'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc chắn muốn xóa tài khoản? Tất cả dữ liệu sẽ bị xóa vĩnh viễn và không thể khôi phục.',
              ),

              // ⭐ YÊU CẦU NHẬP MẬT KHẨU (nếu là tài khoản email/password)
              if (isPasswordProvider) ...[
                SizedBox(height: 16),
                Text(
                  'Nhập mật khẩu để xác nhận:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // ⭐ XÁC THỰC LẠI NẾU LÀ TÀI KHOẢN EMAIL/PASSWORD
                  if (isPasswordProvider) {
                    if (passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Vui lòng nhập mật khẩu'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final credential = EmailAuthProvider.credential(
                      email: currentUser!.email!,
                      password: passwordController.text,
                    );

                    await currentUser.reauthenticateWithCredential(credential);
                  }

                  // Xóa tài khoản
                  await _profileService.deleteUserAccount();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } on FirebaseAuthException catch (e) {
                  Navigator.pop(context);

                  String message = 'Lỗi: ${e.message}';

                  if (e.code == 'wrong-password') {
                    message = 'Mật khẩu không đúng';
                  } else if (e.code == 'requires-recent-login') {
                    message = 'Vui lòng đăng nhập lại để xóa tài khoản';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Xóa'),
            ),
          ],
        ),
      ),
    );
  }
}