// lib/models/appointment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime slotStart;
  final DateTime slotEnd;
  final String mode;
  final String status;
  final String? meetingRoomId;
  final String? calendarEventId;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.slotStart,
    required this.slotEnd,
    required this.mode,
    required this.status,
    this.meetingRoomId,
    this.calendarEventId,
  });

  factory Appointment.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      patientId: data['patientId'],
      doctorId: data['doctorId'],
      slotStart: (data['slotStart'] as Timestamp).toDate(),
      slotEnd: (data['slotEnd'] as Timestamp).toDate(),
      mode: data['mode'],
      status: data['status'],
      meetingRoomId: data['meetingRoomId'],
      calendarEventId: data['calendarEventId'],
    );
  }
}
