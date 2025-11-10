// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'auth_service.dart';
// import 'login_page.dart';

// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Home'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               await AuthService().signOut();
              
//               // Check mounted trước khi dùng context
//               if (context.mounted) {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) => const LoginPage()),
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('Welcome, ${user?.displayName ?? user?.email ?? 'User'}'),
//             const SizedBox(height: 8),
//             Text('UID: ${user?.uid}'),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Hàm xử lý Đăng xuất và chuyển hướng
  Future<void> _handleSignOut(BuildContext context) async {
    await AuthService().signOut();

    // Check mounted trước khi dùng context
    if (context.mounted) {
      // Dùng pushReplacement để ngăn người dùng quay lại trang Home sau khi đăng xuất
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Lấy tên/email để hiển thị
    final userName = user?.displayName ?? user?.email ?? 'Người dùng';
    final userEmail = user?.email ?? 'Không có email';
    
    // Màu sắc chủ đạo mới
    const Color primaryColor = Color(0xFF42A5F5); // Blue-400

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: primaryColor,
        elevation: 0,
        
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. Tiêu đề (Bên trái)
            const Text(
              'Trang Chủ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20, 
              ),
            ),
            
            // 2. Nút Đăng xuất (Bên phải)
            Padding(
              padding: const EdgeInsets.only(right: 25.0), // Tạo khoảng cách an toàn
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Đăng xuất',
                onPressed: () => _handleSignOut(context),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 8, // Đổ bóng nhẹ
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), // Bo góc
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: primaryColor.withOpacity(0.15),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Xin chào, $userName!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      userEmail,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Divider(height: 24),

                    _buildUserInfoRow(
                      icon: Icons.vpn_key_outlined,
                      label: 'ID Người dùng (UID)',
                      value: user?.uid ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            
            const Text(
              'Các Chức Năng Chính:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildFeatureButton(
              context,
              icon: Icons.data_usage,
              label: 'Quản lý Dữ liệu',
              onTap: () {
              },
            ),
            _buildFeatureButton(
              context,
              icon: Icons.settings,
              label: 'Cài đặt Tài khoản',
              onTap: () {
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF42A5F5)),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}