// lib/screens/patient_appointments_screen.dart
/*
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../widgets/primary_button.dart';
import '../widgets/custom_card.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  // Track the currently displayed call dialog to avoid stacking them
  String? _activeCallDialogApptId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text("Not logged in")));

    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // Stream orders by time so upcoming is first
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('patientId', isEqualTo: uid)
            .orderBy('slotStart', descending: false)
            .limit(50)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          
          // Check for any appointment that just turned 'ongoing'
          // We use a post-frame callback to show the dialog safely
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkForIncomingCalls(docs);
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No upcoming appointments'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final status = (data['status'] ?? 'pending') as String;
              final meetingRoomId = data['meetingRoomId'] as String?;
              
              final Timestamp? ts = data['slotStart'] as Timestamp?;
              final dateStr = ts != null 
                  ? DateFormat.yMMMd().add_jm().format(ts.toDate()) 
                  : 'TBD';

              // Logic: Can join if status is ongoing OR confirmed (if room exists)
              // 'ongoing' is the trigger for the popup
              final isOngoing = status == 'ongoing';
              final canJoin = (isOngoing || status == 'confirmed') && meetingRoomId != null;

              return CustomCard(
                padding: const EdgeInsets.all(16),
                // Highlight card green if call is live
                color: isOngoing ? Colors.green.shade50 : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isOngoing)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('CALL IN PROGRESS', 
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Chip(
                          label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10)),
                          backgroundColor: _getStatusColor(status).withOpacity(0.1),
                          labelStyle: TextStyle(color: _getStatusColor(status)),
                          visualDensity: VisualDensity.compact,
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Doctor ID: ${data['doctorId'] ?? 'Unknown'}', 
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: canJoin 
                      ? PrimaryButton(
                          label: isOngoing ? 'Join Call Now' : 'Join Waiting Room',
                          icon: Icons.video_camera_front,
                          // Make button green if ongoing
                          // Assuming PrimaryButton takes a color, or we let it use default theme
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              '/call',
                              arguments: {
                                'isInitiator': false,
                                'roomId': meetingRoomId,
                              },
                            );
                          },
                        )
                      : OutlinedButton(
                          onPressed: null, // Disabled
                          child: Text(
                            status == 'pending' ? 'Waiting for confirmation' 
                            : status == 'completed' ? 'Completed'
                            : 'Scheduled',
                          ),
                        ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _checkForIncomingCalls(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    try {
      // Look for the *first* appointment that is 'ongoing' and has a room ID
      final ongoingCall = docs.firstWhere(
        (d) => d.data()['status'] == 'ongoing' && d.data()['meetingRoomId'] != null,
        orElse: () => docs.firstWhere((d) => false), // Dummy fallback if not found to avoid exception
      );
      
      // If no ongoing call found, reset our tracker and return
      // (Use .exists or check id to verify valid doc was found)
      if (!ongoingCall.exists) {
         // If we had a dialog open for a call that ended, we could close it here, 
         // but standard dialogs block interaction anyway.
         _activeCallDialogApptId = null;
         return;
      }

      final apptId = ongoingCall.id;
      final roomId = ongoingCall.data()['meetingRoomId'];

      // Only show dialog if we haven't shown it for this specific appointment yet
      if (_activeCallDialogApptId != apptId) {
        _activeCallDialogApptId = apptId;
        
        showDialog(
          context: context,
          barrierDismissible: false, // User must accept or decline
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.ring_volume, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text('Incoming Consultation'),
              ],
            ),
            content: const Text(
              'Your doctor has started the video consultation.\n\nWould you like to join now?',
              style: TextStyle(fontSize: 16),
            ),
            actionsPadding: const EdgeInsets.all(16),
            actions: [
              TextButton(
                onPressed: () {
                  // "Decline" just closes the dialog, doesn't cancel the appt
                  // We reset _activeCallDialogApptId so it doesn't pop up immediately again
                  // unless the user leaves and comes back, or status changes
                  Navigator.pop(ctx); 
                },
                child: const Text('Later', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.video_call),
                label: const Text('Join Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.of(context).pushNamed(
                    '/call',
                    arguments: {
                      'isInitiator': false,
                      'roomId': roomId,
                    },
                  );
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Fallback for safety
      debugPrint("Error checking incoming calls: $e");
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'confirmed') return Colors.green;
    if (status == 'ongoing') return Colors.blue;
    if (status == 'completed') return Colors.grey;
    if (status == 'cancelled') return Colors.red;
    return Colors.orange;
  }
}
*/

// lib/screens/patient_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_card.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  String? _activeCallDialogApptId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text("Not logged in")));

    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('patientId', isEqualTo: uid)
            .orderBy('slotStart', descending: false)
            .limit(50)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkForIncomingCalls(docs);
          });

          if (docs.isEmpty) return const Center(child: Text('No upcoming appointments'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final status = (data['status'] ?? 'pending') as String;
              final meetingRoomId = data['meetingRoomId'] as String?;
              final ts = data['slotStart'] as Timestamp?;
              final dateStr = ts != null ? DateFormat.yMMMd().add_jm().format(ts.toDate()) : 'TBD';

              final isOngoing = status == 'ongoing';
              final canJoin = (isOngoing || status == 'confirmed') && meetingRoomId != null;

              return CustomCard(
                color: isOngoing ? Colors.green.shade50 : null,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isOngoing)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('CALL IN PROGRESS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Chip(
                          label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10)),
                          backgroundColor: Colors.grey.shade200,
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: canJoin 
                      ? PrimaryButton(
                          label: isOngoing ? 'Join Call Now' : 'Join Waiting Room',
                          icon: Icons.video_camera_front,
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              '/call',
                              arguments: {
                                'isInitiator': false,
                                'roomId': meetingRoomId,
                              },
                            );
                          },
                        )
                      : const OutlinedButton(onPressed: null, child: Text('Scheduled')),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _checkForIncomingCalls(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    try {
      final ongoingCall = docs.firstWhere(
        (d) => d.data()['status'] == 'ongoing' && d.data()['meetingRoomId'] != null,
        orElse: () => docs.firstWhere((d) => false, orElse: () => docs.first), 
      );
      
      // Check if we actually found a valid ongoing call doc
      if (ongoingCall.exists && ongoingCall.data()['status'] != 'ongoing') {
        // Fallback returned a non-ongoing doc, so no call active
        _activeCallDialogApptId = null;
        return;
      }

      final apptId = ongoingCall.id;
      final roomId = ongoingCall.data()['meetingRoomId'];

      if (_activeCallDialogApptId != apptId) {
        _activeCallDialogApptId = apptId;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [Icon(Icons.ring_volume, color: Colors.green, size: 28), SizedBox(width: 12), Text('Incoming Call')]),
            content: const Text('Your doctor has started the consultation. Join now?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/call', arguments: {'isInitiator': false, 'roomId': roomId});
                },
                child: const Text('Join'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Error checking calls: $e");
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'confirmed') return Colors.green;
    if (status == 'ongoing') return Colors.blue;
    if (status == 'completed') return Colors.grey;
    if (status == 'cancelled') return Colors.red;
    return Colors.orange;
  }
}