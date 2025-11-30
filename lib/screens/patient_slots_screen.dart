// lib/screens/patient_slots_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/custom_card.dart';
import '../widgets/primary_button.dart';

class PatientSlotsScreen extends StatefulWidget {
  const PatientSlotsScreen({super.key});

  @override
  State<PatientSlotsScreen> createState() => _PatientSlotsScreenState();
}

class _PatientSlotsScreenState extends State<PatientSlotsScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? _uid;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final u = _auth.currentUser;
    if (u != null) {
      _uid = u.uid;
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  /// Stream of available slots from the global index
  Stream<QuerySnapshot<Map<String, dynamic>>> _publishedSlotsStream() {
    return _db
        .collection('slots_index')
        .where('published', isEqualTo: true)
        .where('slotStart', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('slotStart')
        .snapshots();
  }

  /// Helper to fetch doctor details for display
  Future<Map<String, dynamic>?> _fetchDoctor(String doctorId) async {
    try {
      final snap = await _db.collection('doctors').doc(doctorId).get();
      if (!snap.exists) return null;
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  // --- FIX: Refactored Conflict Check ---
  // Firestore cannot query: WHERE start < X AND end > Y.
  // Solution: Query WHERE start < X. Then iterate results to check if end > Y.
  Future<bool> _checkPatientConflict(DateTime newSlotStart, DateTime newSlotEnd) async {
    if (_uid == null) return false;
    
    try {
      // 1. Query: Get all appointments for this patient that START before the new slot ENDS.
      // This effectively grabs any appointment that *could* overlap on the timeline.
      final q = await _db
          .collection('appointments')
          .where('patientId', isEqualTo: _uid)
          .where('slotStart', isLessThan: Timestamp.fromDate(newSlotEnd)) 
          .get();

      // 2. Filter (Client-side): Check if the retrieved appointment actually overlaps.
      // An overlap exists if: Existing_End > New_Start
      for (var doc in q.docs) {
        final data = doc.data();
        final existingEndTs = data['slotEnd'] as Timestamp?;
        final status = data['status'] as String?;

        // Skip if data is malformed or appointment was cancelled
        if (existingEndTs == null || status == 'cancelled') continue;

        final existingEnd = existingEndTs.toDate();

        if (existingEnd.isAfter(newSlotStart)) {
          return true; // Conflict found
        }
      }
      return false;
    } catch (e) {
      debugPrint("Conflict check failed: $e");
      // Fail safe: If network check fails, we typically don't want to block the user 
      // from trying, but in a strict system you might return true. 
      // Returning false here prevents the app from freezing if the query fails.
      return false; 
    }
  }

  Future<void> _bookSlot(BuildContext ctx, Map<String, dynamic> slotDoc) async {
    if (_uid == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please sign in to book')));
      return;
    }

    final slotId = slotDoc['slotId'] as String?;
    final doctorId = slotDoc['doctorId'] as String?;
    if (slotId == null || doctorId == null) return;

    setState(() => _loading = true);

    try {
      // 1. Verify Slot exists and is still published (Concurrency protection)
      final slotSnap = await _db.collection('doctors').doc(doctorId).collection('slots').doc(slotId).get();
      
      if (!slotSnap.exists || slotSnap.data()?['published'] != true) {
        throw Exception('This slot is no longer available.');
      }

      final slotStart = (slotSnap.data()!['slotStart'] as Timestamp).toDate();
      final slotEnd = (slotSnap.data()!['slotEnd'] as Timestamp).toDate();

      // 2. Check for conflicts with patient's existing schedule
      final hasConflict = await _checkPatientConflict(slotStart, slotEnd);
      if (hasConflict) {
        throw Exception('You already have an appointment booked during this time.');
      }

      // 3. Create the Appointment
      // We set status to 'confirmed' so it shows up immediately for the doctor to start call
      final apptRef = _db.collection('appointments').doc();
      await apptRef.set({
        'appointmentId': apptRef.id,
        'slotId': slotId,
        'doctorId': doctorId,
        'patientId': _uid,
        'patientName': _auth.currentUser?.displayName ?? 'Patient',
        'slotStart': Timestamp.fromDate(slotStart),
        'slotEnd': Timestamp.fromDate(slotEnd),
        'status': 'confirmed', 
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Mark slot as unpublished (Booked)
      // This prevents others from seeing it in the global index
      await _db.collection('doctors').doc(doctorId).collection('slots').doc(slotId).update({'published': false});
      await _db.collection('slots_index').doc(slotId).delete();

      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Appointment Booked Successfully!'),
            backgroundColor: Colors.green,
          )
        );
        Navigator.pop(ctx);
      }
    } catch (e) {
      // Robust Error Handling
      if (mounted) {
        String errorMsg = e.toString().replaceAll('Exception:', '').trim();
        if (errorMsg.contains('permission-denied')) {
          errorMsg = "Permission denied. Please checking your connection or login.";
        }
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _slotTile(Map<String, dynamic> s, Map<String, dynamic>? doctorData) {
    final start = (s['slotStart'] as Timestamp).toDate();
    final doctorName = doctorData?['displayName'] ?? 'Doctor';
    final specialization = doctorData?['specialization'] ?? '';
    final fee = doctorData?['consultationFee'] ?? '—';

    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            doctorName.isNotEmpty ? doctorName[0].toUpperCase() : 'D',
            style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
          )
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doctorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text(specialization, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMd().add_jm().format(start), 
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)
            ),
          ]),
        ),
        Column(children: [
          if (fee != '—')
            Text('₹$fee', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _bookSlot(context, s),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 36)
            ),
            child: const Text('Book'),
          )
        ])
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Slots')),
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _publishedSlotsStream(),
              builder: (context, snap) {
                // Error Handling for Stream
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Unable to load slots.\nCheck your internet connection.\n\nError: ${snap.error}', 
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  );
                }
                
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('No slots available right now', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final sDoc = docs[i];
                    final s = sDoc.data();
                    final doctorId = s['doctorId'] as String?;
                    
                    // Fetch doctor details asynchronously for each slot
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: (doctorId != null) ? _fetchDoctor(doctorId) : Future.value(null),
                      builder: (ctx, dsnap) {
                        if (dsnap.connectionState == ConnectionState.waiting) {
                          // Show a loading placeholder for the tile
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: SizedBox(height: 80, child: Center(child: LinearProgressIndicator(minHeight: 2))),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _slotTile(s, dsnap.data),
                        );
                      },
                    );
                  },
                );
              },
            ),
            // Loading Overlay
            if (_loading)
              Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              )
          ],
        ),
      ),
    );
  }
}