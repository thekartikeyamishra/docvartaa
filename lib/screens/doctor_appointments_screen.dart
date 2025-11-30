// lib/screens/doctor_appointments_screen.dart
/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/custom_card.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _appointmentsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: uid)
        .orderBy('slotStart', descending: false)
        .limit(50)
        .snapshots();
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'ongoing':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.grey;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Appointments')),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _appointmentsStream(),
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;
            if (docs.isEmpty) return const Center(child: Text('No appointments yet'));

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final d = docs[i];
                final data = d.data();
                final apptId = d.id;
                
                final slotTs = data['slotStart'] as Timestamp?;
                final slotStr = slotTs != null 
                    ? DateFormat.yMMMd().add_jm().format(slotTs.toDate()) 
                    : 'Unknown Time';
                
                final patientName = data['patientName'] ?? 'Patient';
                final status = data['status'] ?? 'pending';

                return CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(slotStr, style: TextStyle(color: Colors.grey[700])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _statusChip(status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamed(
                              '/appointmentDetails', 
                              arguments: apptId
                            ),
                            child: const Text('Details'),
                          ),
                          const SizedBox(width: 8),
                          // Allow start if confirmed OR already ongoing (to rejoin) OR pending (for testing)
                          if (status == 'confirmed' || status == 'ongoing' || status == 'pending')
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to Call Screen (Initiator)
                                // NOTE: The CallScreen itself handles the Firestore update to 'ongoing'
                                Navigator.of(context).pushNamed(
                                  '/call',
                                  arguments: {
                                    'isInitiator': true,
                                    'appointmentId': apptId, 
                                  },
                                );
                              },
                              icon: const Icon(Icons.video_call),
                              label: Text(status == 'ongoing' ? 'Rejoin Call' : 'Start Call'),
                            ),
                          
                          // "Complete" button for manual status update if needed
                          if (status == 'ongoing' || status == 'confirmed')
                             Padding(
                               padding: const EdgeInsets.only(left: 8.0),
                               child: OutlinedButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('appointments')
                                      .doc(apptId)
                                      .update({'status': 'completed'});
                                },
                                child: const Text('Done'),
                               ),
                             ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
*/

// lib/screens/doctor_appointments_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_card.dart';

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _appointmentsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: uid)
        .orderBy('slotStart', descending: false)
        .limit(50)
        .snapshots();
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'confirmed': color = Colors.green; break;
      case 'ongoing': color = Colors.blue; break;
      case 'completed': color = Colors.grey; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Appointments')),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _appointmentsStream(),
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

            final docs = snap.data!.docs;
            if (docs.isEmpty) return const Center(child: Text('No appointments yet'));

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final d = docs[i];
                final data = d.data();
                final apptId = d.id;
                final patientName = data['patientName'] ?? 'Patient';
                final status = data['status'] ?? 'pending';

                return CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          _statusChip(status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamed('/appointmentDetails', arguments: apptId),
                            child: const Text('Details'),
                          ),
                          const SizedBox(width: 8),
                          if (status == 'confirmed' || status == 'ongoing' || status == 'pending')
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  '/call',
                                  arguments: {
                                    'isInitiator': true,
                                    'appointmentId': apptId, 
                                  },
                                );
                              },
                              icon: const Icon(Icons.video_call),
                              label: Text(status == 'ongoing' ? 'Rejoin Call' : 'Start Call'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}