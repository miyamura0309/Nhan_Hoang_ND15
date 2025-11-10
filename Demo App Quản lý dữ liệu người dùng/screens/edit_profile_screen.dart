import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../services/base64_image_service.dart'; // ⭐ IMPORT BASE64 SERVICE
import 'dart:convert'; // ⭐ IMPORT để dùng base64Decode

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserProfileService _profileService = UserProfileService();
  final Base64ImageService _imageService = Base64ImageService(); // ⭐ BASE64 SERVICE
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingImage = false; // ⭐ ĐANG CHỌN ẢNH
  UserProfile? _currentProfile;
  String? _newAvatarBase64; // ⭐ BASE64 STRING

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final profile = await _profileService.getUserProfile(user.uid);
      if (profile != null) {
        setState(() {
          _currentProfile = profile;
          _nameController.text = profile.displayName;
          _phoneController.text = profile.phoneNumber ?? '';
          _bioController.text = profile.bio ?? '';
          _addressController.text = profile.address ?? '';
          _selectedDate = profile.dateOfBirth;
          _isLoading = false;
        });
      }
    }
  }

  // ⭐ CHỌN ẢNH VÀ CONVERT SANG BASE64
  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);

    try {
      // Convert ảnh sang Base64
      final String? base64String = await _imageService.pickAndConvertToBase64();

      if (base64String != null) {
        // Kiểm tra kích thước
        final size = _imageService.getBase64Size(base64String);

        if (size > 800) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Ảnh quá lớn (${size.toStringAsFixed(0)}KB). Vui lòng chọn ảnh nhỏ hơn.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        setState(() {
          _newAvatarBase64 = base64String;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã chọn ảnh (${size.toStringAsFixed(0)}KB). Nhấn "Lưu" để cập nhật'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // ⭐ Nếu có ảnh mới (Base64), cập nhật photoURL
        if (_newAvatarBase64 != null) {
          await _profileService.updatePhotoURL(user.uid, _newAvatarBase64!);
        }

        // Cập nhật các thông tin khác
        await _profileService.updateUserProfile(
          uid: user.uid,
          displayName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          dateOfBirth: _selectedDate,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('✅ Cập nhật thành công'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('❌ Lỗi: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập họ tên';
    }
    if (value.length < 2) {
      return 'Họ tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Số điện thoại không hợp lệ (10-11 số)';
    }
    return null;
  }

  // ⭐ BUILD AVATAR (hỗ trợ cả URL và Base64)
  Widget _buildAvatar() {
    ImageProvider? imageProvider;

    if (_newAvatarBase64 != null) {
      // Ảnh mới vừa chọn (Base64)
      final base64String = _newAvatarBase64!.split(',')[1];
      final bytes = base64Decode(base64String);
      imageProvider = MemoryImage(bytes);
    } else if (_currentProfile?.photoURL != null) {
      final photoURL = _currentProfile!.photoURL!;
      if (photoURL.startsWith('data:image/')) {
        // Base64
        final base64String = photoURL.split(',')[1];
        final bytes = base64Decode(base64String);
        imageProvider = MemoryImage(bytes);
      } else {
        // URL
        imageProvider = NetworkImage(photoURL);
      }
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.blue.shade100,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Icon(Icons.person, size: 50, color: Colors.blue)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chỉnh sửa Profile'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Chỉnh sửa Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ⭐ AVATAR
              Center(
                child: Stack(
                  children: [
                    _buildAvatar(),

                    // Nút camera
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _isPickingImage ? null : _pickImage,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isPickingImage
                              ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  _isPickingImage
                      ? 'Đang xử lý...'
                      : 'Nhấn camera để thay đổi ảnh',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  '💡 Lưu ý: Dung lượng ảnh không quá 800KB',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 32),

              // Họ tên
              Text(
                'Họ và tên *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Nhập họ và tên',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: _validateName,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 20),

              // Số điện thoại
              Text(
                'Số điện thoại',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: 'Nhập số điện thoại (10-11 số)',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 20),

              // Ngày sinh
              Text(
                'Ngày sinh',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cake, color: Colors.grey[600]),
                      SizedBox(width: 16),
                      Text(
                        _selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                            : 'Chọn ngày sinh',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate != null
                              ? Colors.black87
                              : Colors.grey[600],
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Địa chỉ
              Text(
                'Địa chỉ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Nhập địa chỉ',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 20),

              // Giới thiệu
              Text(
                'Giới thiệu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  hintText: 'Viết vài dòng về bạn...',
                  prefixIcon: Icon(Icons.info_outline, size: 24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 4,
                maxLength: 200,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: 32),

              // Nút Lưu
              ElevatedButton(
                onPressed: _isSaving || _isPickingImage ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSaving
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Lưu thay đổi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Nút Hủy
              OutlinedButton(
                onPressed: _isSaving || _isPickingImage
                    ? null
                    : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[400]!),
                ),
                child: Text(
                  'Hủy',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

