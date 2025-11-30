// lib/services/booking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Check if a slot is still available for booking
  /// FIXED: Proper conflict detection that allows back-to-back appointments
  Future<bool> isSlotAvailable({
    required String doctorId,
    required String patientId,
    required DateTime slotStart,
    required DateTime slotEnd,
  }) async {
    try {
      // Check for patient conflicts
      final patientQuery = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .where('status', whereIn: ['confirmed', 'ongoing'])
          .get();

      for (var doc in patientQuery.docs) {
        final data = doc.data();
        final existingStart = (data['slotStart'] as Timestamp).toDate();
        final existingEnd = (data['slotEnd'] as Timestamp).toDate();

        if (_hasTimeOverlap(slotStart, slotEnd, existingStart, existingEnd)) {
          return false;
        }
      }

      // Check for doctor conflicts
      final doctorQuery = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', whereIn: ['confirmed', 'ongoing'])
          .get();

      for (var doc in doctorQuery.docs) {
        final data = doc.data();
        final existingStart = (data['slotStart'] as Timestamp).toDate();
        final existingEnd = (data['slotEnd'] as Timestamp).toDate();

        if (_hasTimeOverlap(slotStart, slotEnd, existingStart, existingEnd)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error checking slot availability: $e');
      return false;
    }
  }

  /// Check if two time ranges overlap (excluding touching endpoints)
  bool _hasTimeOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    if (end1.isBefore(start2) || end1.isAtSameMomentAs(start2)) return false;
    if (end2.isBefore(start1) || end2.isAtSameMomentAs(start1)) return false;
    return true;
  }

  /// Book appointment with meeting room ID
  Future<String?> bookAppointment({
    required String doctorId,
    required String patientId,
    required DateTime slotStart,
    required DateTime slotEnd,
    String? notes,
  }) async {
    try {
      final isAvailable = await isSlotAvailable(
        doctorId: doctorId,
        patientId: patientId,
        slotStart: slotStart,
        slotEnd: slotEnd,
      );

      if (!isAvailable) {
        throw Exception('This time slot is no longer available');
      }

      final appointmentId = _uuid.v4();
      final meetingRoomId = _uuid.v4();

      await _firestore.collection('appointments').doc(appointmentId).set({
        'doctorId': doctorId,
        'patientId': patientId,
        'slotStart': Timestamp.fromDate(slotStart),
        'slotEnd': Timestamp.fromDate(slotEnd),
        'status': 'confirmed',
        'meetingRoomId': meetingRoomId, // CRITICAL FIX
        'notes': notes ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return appointmentId;
    } catch (e) {
      print('Error booking appointment: $e');
      return null;
    }
  }

  /// Cancel appointment
  Future<bool> cancelAppointment(String appointmentId, String userId) async {
    try {
      final doc = await _firestore.collection('appointments').doc(appointmentId).get();
      if (!doc.exists) throw Exception('Appointment not found');

      final data = doc.data()!;
      if (data['doctorId'] != userId && data['patientId'] != userId) {
        throw Exception('Unauthorized');
      }

      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': userId,
      });
      return true;
    } catch (e) {
      print('Error cancelling: $e');
      return false;
    }
  }

  /// Complete appointment
  Future<bool> completeAppointment(String appointmentId, String doctorId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error completing: $e');
      return false;
    }
  }

  Stream<QuerySnapshot> getAppointmentsForUser({
    required String userId,
    required bool isDoctor,
  }) {
    return _firestore
        .collection('appointments')
        .where(isDoctor ? 'doctorId' : 'patientId', isEqualTo: userId)
        .orderBy('slotStart', descending: true)
        .snapshots();
  }
}