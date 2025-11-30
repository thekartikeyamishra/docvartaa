// lib/screens/patient_profile_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_card.dart';
import '../widgets/primary_button.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _historyCtrl = TextEditingController();
  
  // State variables
  String _gender = 'male';
  String _bloodGroup = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _historyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await _firestoreService.getUser(_uid);
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _nameCtrl.text = data['displayName'] ?? '';
        
        // Patient profile data is nested
        final profile = data['patientProfile'] as Map<String, dynamic>? ?? {};
        
        _ageCtrl.text = profile['age']?.toString() ?? '';
        _phoneCtrl.text = profile['phone'] ?? '';
        _addressCtrl.text = profile['address'] ?? '';
        _historyCtrl.text = profile['pastMedicalHistory'] ?? '';
        
        if (profile['gender'] != null) {
          setState(() => _gender = profile['gender']);
        }
        if (profile['bloodGroup'] != null) {
          setState(() => _bloodGroup = profile['bloodGroup']);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      // 1. Prepare data
      final profileData = {
        'age': int.tryParse(_ageCtrl.text.trim()),
        'gender': _gender,
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'bloodGroup': _bloodGroup,
        'pastMedicalHistory': _historyCtrl.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // 2. Update Firestore
      // Update display name at root level
      await _firestoreService.updateUser(_uid, {
        'displayName': _nameCtrl.text.trim(),
      });
      
      // Update nested patient profile
      await _firestoreService.updatePatientProfile(_uid, profileData);

      // 3. Update Auth Profile (optional, for faster local display)
      await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameCtrl.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageCtrl,
                              decoration: const InputDecoration(labelText: 'Age'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _gender,
                              decoration: const InputDecoration(labelText: 'Gender'),
                              items: const [
                                DropdownMenuItem(value: 'male', child: Text('Male')),
                                DropdownMenuItem(value: 'female', child: Text('Female')),
                                DropdownMenuItem(value: 'other', child: Text('Other')),
                              ],
                              onChanged: (v) => setState(() => _gender = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Phone Number'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(labelText: 'Address'),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medical Info',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _bloodGroup.isEmpty ? null : _bloodGroup,
                      decoration: const InputDecoration(labelText: 'Blood Group'),
                      items: const [
                        DropdownMenuItem(value: 'A+', child: Text('A+')),
                        DropdownMenuItem(value: 'A-', child: Text('A-')),
                        DropdownMenuItem(value: 'B+', child: Text('B+')),
                        DropdownMenuItem(value: 'B-', child: Text('B-')),
                        DropdownMenuItem(value: 'O+', child: Text('O+')),
                        DropdownMenuItem(value: 'O-', child: Text('O-')),
                        DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                        DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                      ],
                      onChanged: (v) => setState(() => _bloodGroup = v ?? ''),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _historyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Past Medical History',
                        hintText: 'Allergies, chronic conditions, surgeries...',
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isSaving ? 'Saving...' : 'Save Profile',
                onPressed: _isSaving ? null : _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}