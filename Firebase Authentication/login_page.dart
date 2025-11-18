// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'auth_service.dart';
// import 'home_page.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final AuthService _authService = AuthService();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void _loginEmail() async {
//     User? user = await _authService.signInWithEmail(
//         _emailController.text, _passwordController.text);
    
//     if (!mounted) return; // Check mounted trước khi dùng context
    
//     if (user != null) {
//       Navigator.pushReplacement(
//           context, MaterialPageRoute(builder: (_) => const HomePage()));
//     }
//   }

//   void _registerEmail() async {
//     User? user = await _authService.registerWithEmail(
//         _emailController.text, _passwordController.text);
    
//     if (!mounted) return; // Check mounted trước khi dùng context
    
//     if (user != null) {
//       Navigator.pushReplacement(
//           context, MaterialPageRoute(builder: (_) => const HomePage()));
//     }
//   }

//   void _loginGoogle() async {
//     User? user = await _authService.signInWithGoogle();
    
//     if (!mounted) return; // Check mounted trước khi dùng context
    
//     if (user != null) {
//       Navigator.pushReplacement(
//           context, MaterialPageRoute(builder: (_) => const HomePage()));
//     }
//   }

//   void _loginFacebook() async {
//     User? user = await _authService.signInWithFacebook();
    
//     if (!mounted) return; // Check mounted trước khi dùng context
    
//     if (user != null) {
//       Navigator.pushReplacement(
//           context, MaterialPageRoute(builder: (_) => const HomePage()));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Login')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(labelText: 'Email'),
//             ),
//             TextField(
//               controller: _passwordController,
//               decoration: const InputDecoration(labelText: 'Password'),
//               obscureText: true,
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 ElevatedButton(
//                   onPressed: _loginEmail,
//                   child: const Text('Sign In'),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: _registerEmail,
//                   child: const Text('Register'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _loginGoogle,
//               child: const Text('Sign in with Google'),
//             ),
//             const SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: _loginFacebook,
//               child: const Text('Sign in with Facebook'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// 

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true; 
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Hàm xử lý cho Email/Password (giữ nguyên)
  void _handleAuthResult(User? user) {
    setState(() {
      _isLoading = false;
    });

    if (!mounted) return; 
    
    if (user != null) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLogin ? 'Đăng nhập thất bại!' : 'Đăng ký thất bại! Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Email/Password - Giữ nguyên
  void _submitEmail() async {
    setState(() {
      _isLoading = true;
    });

    User? user;
    if (_isLogin) {
      user = await _authService.signInWithEmail(
          _emailController.text, _passwordController.text);
    } else {
      user = await _authService.registerWithEmail(
          _emailController.text, _passwordController.text);
    }

    _handleAuthResult(user);
  }

  // ✅ GOOGLE LOGIN - ĐÃ SỬA (GIẢI PHÁP 3)
  void _loginGoogle() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      User? user = await _authService.signInWithGoogle();
      
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      if (user != null) {
        // ✅ Thành công
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
      // Không làm gì nếu user == null (user đóng popup)
      
    } catch (e) {
      // ❌ Chỉ hiển thị lỗi khi có exception thật
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đăng nhập Google: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ✅ FACEBOOK LOGIN - ĐÃ SỬA (GIẢI PHÁP 3)
  void _loginFacebook() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      User? user = await _authService.signInWithFacebook();
      
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      if (user != null) {
        // ✅ Thành công
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
      // Không làm gì nếu user == null (user đóng popup)
      
    } catch (e) {
      // ❌ Chỉ hiển thị lỗi khi có exception thật
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đăng nhập Facebook: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF42A5F5); 

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Đăng Nhập' : 'Đăng Ký', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isLogin ? 'Chào mừng trở lại' : 'Tạo Tài Khoản Mới',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sử dụng Email & Mật khẩu hoặc Đăng nhập xã hội',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),

            // INPUT EMAIL
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ Email',
                prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
            ),
            const SizedBox(height: 20),

            // INPUT PASSWORD
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
            ),
            const SizedBox(height: 30),

            // NÚT SUBMIT
            SizedBox(
              height: 50,
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : ElevatedButton(
                    onPressed: _submitEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _isLogin ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ',
                      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
            ),
            const SizedBox(height: 10),

            // NÚT CHUYỂN ĐỔI
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                });
              },
              child: Text(
                _isLogin 
                  ? 'Chưa có tài khoản? Đăng ký ngay' 
                  : 'Đã có tài khoản? Đăng nhập',
                style: const TextStyle(color: primaryColor),
              ),
            ),

            const SizedBox(height: 30),
            
            // Divider
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('HOẶC', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            
            const SizedBox(height: 30),

            // SOCIAL BUTTONS
            _buildSocialButton(
              'Đăng nhập với Google',
              '../assets/google_logo.png',
              Colors.white,
              Colors.black54,
              _loginGoogle,
            ),
            const SizedBox(height: 15),
            _buildSocialButton(
              'Đăng nhập với Facebook',
              '../assets/facebook_logo.png',
              const Color(0xFF1877F2),
              Colors.white,
              _loginFacebook,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    String text,
    String iconPath,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Image.asset(
          iconPath, 
          height: 24.0,
          errorBuilder: (context, error, stackTrace) => Icon(
            text.contains('Google') ? Icons.g_mobiledata : Icons.facebook,
            color: textColor == Colors.white ? Colors.white : Colors.black,
          ),
        ),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}