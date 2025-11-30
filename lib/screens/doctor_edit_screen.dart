// lib/screens/doctor_edit_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';

class DoctorEditScreen extends StatefulWidget {
  const DoctorEditScreen({super.key});

  @override State<DoctorEditScreen> createState() => _DoctorEditScreenState();
}

class _DoctorEditScreenState extends State<DoctorEditScreen> {
  final _name = TextEditingController();
  final _speciality = TextEditingController();
  final _bio = TextEditingController();
  File? _avatar;
  final StorageService _storage = StorageService();
  final UserService _userService = UserService();
  final uid = FirebaseAuth.instance.currentUser!.uid;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final u = await _userService.getUserById(uid);
    setState(() {
      _name.text = u?.name ?? '';
      _speciality.text = u?.profile?['speciality'] ?? '';
      _bio.text = u?.profile?['bio'] ?? '';
    });
  }

  Future<void> pickAvatar() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (p == null) return;
    setState(() => _avatar = File(p.path));
  }

  Future<void> save() async {
    setState(() => saving = true);
    String? avatarUrl;
    if (_avatar != null) {
      avatarUrl = await _storage.uploadAvatar(uid, _avatar!);
    }
    final profile = {
      'speciality': _speciality.text.trim(),
      'bio': _bio.text.trim(),
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
    await _userService.updateProfile(uid, profile);
    setState(() => saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(children: [
          GestureDetector(onTap: pickAvatar, child: CircleAvatar(radius: 40, backgroundImage: _avatar != null ? FileImage(_avatar!) : null)),
          TextField(controller: _name, decoration: InputDecoration(labelText: 'Name')),
          TextField(controller: _speciality, decoration: InputDecoration(labelText: 'Speciality')),
          TextField(controller: _bio, decoration: InputDecoration(labelText: 'Bio')),
          SizedBox(height: 12),
          ElevatedButton(onPressed: saving ? null : save, child: saving ? CircularProgressIndicator() : Text('Save')),
        ]),
      ),
    );
  }
}
