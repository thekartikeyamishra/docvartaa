import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkForIncomingCalls();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                           📞 INCOMING CALL MONITORING
  // ═══════════════════════════════════════════════════════════════════════════

  void _checkForIncomingCalls() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      try {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final doc = change.doc;
            final data = doc.data();
            
            if (data != null) {
              _showIncomingCallDialog(data, doc.id);
            }
          }
        }
      } catch (e) {
        print('Error checking calls: $e');
      }
    }, onError: (error) {
      print('Error checking calls: $error');
    });
  }

  void _showIncomingCallDialog(Map<String, dynamic> callData, String callId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Incoming Video Call'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_call, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Dr. ${callData['callerName'] ?? 'Doctor'} is calling...',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectCall(callId);
            },
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptCall(callData, callId);
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptCall(Map<String, dynamic> callData, String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    Navigator.pushNamed(
      context,
      '/video-call',
      arguments: {
        'callId': callId,
        'appointmentId': callData['appointmentId'],
        'isDoctor': false,
      },
    );
  }

  Future<void> _rejectCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //                           🔐 LOGOUT FUNCTION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await _auth.signOut();
      // AuthWrapper in main.dart will automatically redirect to sign-in
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search-doctors'),
            tooltip: 'Search Doctors',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/patient-profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('Please login'))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('appointments')
                  .where('patientId', isEqualTo: userId)
                  .orderBy('slotStart', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final appointments = snapshot.data?.docs ?? [];

                if (appointments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No appointments yet'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/search-doctors'),
                          child: const Text('Find a Doctor'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final doc = appointments[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final appointmentId = doc.id;

                    return _buildAppointmentCard(data, appointmentId);
                  },
                );
              },
            ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/search-doctors'),
        icon: const Icon(Icons.search),
        label: const Text('Find Doctor'),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> data, String appointmentId) {
    final status = data['status'] ?? 'scheduled';
    final doctorId = data['doctorId'] ?? '';
    final scheduledTime = (data['slotStart'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor info
            FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('doctors').doc(doctorId).get(),
              builder: (context, doctorSnap) {
                if (!doctorSnap.hasData) {
                  return const Text('Loading doctor info...');
                }

                final doctorData = doctorSnap.data?.data() as Map<String, dynamic>?;
                final doctorName = doctorData?['displayName'] ?? 
                                 doctorData?['name'] ?? 
                                 'Doctor';
                final specialty = doctorData?['specialization'] ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. $doctorName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (specialty.isNotEmpty)
                      Text(
                        specialty,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],
                );
              },
            ),
            const Divider(height: 24),
            
            // Appointment details
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  scheduledTime != null
                      ? DateFormat('MMM dd, yyyy • hh:mm a').format(scheduledTime)
                      : 'Time not set',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Status: ${status.toUpperCase()}',
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ✅ ACTION BUTTONS
            if (status == 'ongoing')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _joinVideoCall(data, appointmentId),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Join Video Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              )
            else if (status == 'confirmed' || status == 'scheduled')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _viewAppointmentDetails(appointmentId),
                  child: const Text('View Details'),
                ),
              )
            else if (status == 'completed')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _viewAppointmentDetails(appointmentId),
                  icon: const Icon(Icons.description),
                  label: const Text('View Summary'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
      case 'confirmed':
        return Colors.blue;
      case 'ongoing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _joinVideoCall(Map<String, dynamic> appointmentData, String appointmentId) {
    final meetingRoomId = appointmentData['meetingRoomId'] ?? appointmentId;

    print('🎥 Patient joining video call');
    print('   Appointment ID: $appointmentId');
    print('   Meeting Room ID: $meetingRoomId');

    Navigator.pushNamed(
      context,
      '/video-call',
      arguments: {
        'callId': meetingRoomId,
        'appointmentId': appointmentId,
        'isDoctor': false,
      },
    );
  }

  void _viewAppointmentDetails(String appointmentId) {
    Navigator.pushNamed(
      context,
      '/appointment-details',
      arguments: {'appointmentId': appointmentId},
    );
  }
}