// lib/screens/patient_search_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_card.dart';
import '../widgets/primary_button.dart';

class PatientSearchScreen extends StatefulWidget {
  const PatientSearchScreen({super.key});

  @override
  State<PatientSearchScreen> createState() => _PatientSearchScreenState();
}

class _PatientSearchScreenState extends State<PatientSearchScreen> {
  final _keywordCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildStream() {
    final token = _keywordCtrl.text.trim().toLowerCase();
    final spec = _specCtrl.text.trim().toLowerCase();
    final city = _cityCtrl.text.trim().toLowerCase();

    Query<Map<String, dynamic>> query = _db.collection('doctors');

    // Priority 1: Name/Keyword Search (Using Array Contains)
    if (token.isNotEmpty) {
      return query.where('searchKeywords', arrayContains: token).limit(50).snapshots();
    }

    // Priority 2: Specialization (Exact match, lowercase)
    if (spec.isNotEmpty) {
      query = query.where('specializationLower', isEqualTo: spec);
    }

    // Priority 3: City (Exact match, lowercase)
    if (city.isNotEmpty) {
      query = query.where('cityLower', isEqualTo: city);
    }

    // If no filters, just show available doctors
    if (token.isEmpty && spec.isEmpty && city.isEmpty) {
      query = query.where('available', isEqualTo: true);
    }

    return query.limit(50).snapshots();
  }

  void _clearAll() {
    _keywordCtrl.clear();
    _specCtrl.clear();
    _cityCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Doctors')),
      body: SafeArea(
        child: Column(children: [
          // Filters
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextFormField(
                controller: _keywordCtrl, 
                decoration: const InputDecoration(labelText: 'Search Name', prefixIcon: Icon(Icons.search)),
                onChanged: (_) => setState((){}),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _specCtrl, 
                    decoration: const InputDecoration(labelText: 'Specialization'),
                    onChanged: (_) => setState((){}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl, 
                    decoration: const InputDecoration(labelText: 'City'),
                    onChanged: (_) => setState((){}),
                  ),
                ),
              ]),
            ]),
          ),
          
          // Results
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildStream(),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No doctors found matching your criteria.'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data();
                    final name = data['displayName'] ?? 'Unknown';
                    final spec = data['specialization'] ?? '';
                    final city = data['city'] ?? '';
                    final verified = data['kycVerified'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Row(children: [
                          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          if (verified) const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ]),
                        subtitle: Text('$spec • $city'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.of(context).pushNamed(
                          '/doctorProfile', 
                          arguments: doc.id
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}