// lib/screens/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';

class BookingScreen extends StatefulWidget {
  final String patientId;
  final String doctorId;
  const BookingScreen({
    super.key,
    required this.patientId,
    required this.doctorId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? start;
  DateTime? end;
  String mode = 'video';
  String notes = '';
  bool loading = false;
  final BookingService _booking = BookingService();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (time == null) return;

    setState(() {
      start = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> pickEnd() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour + 1, minute: now.minute),
    );
    if (time == null) return;

    setState(() {
      end = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> submit() async {
    if (start == null || end == null || end!.isBefore(start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick valid start and end times'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // CRITICAL FIX: Call bookAppointment() instead of requestAppointment()
      final appointmentId = await _booking.bookAppointment(
        patientId: widget.patientId,
        doctorId: widget.doctorId,
        slotStart: start!,
        slotEnd: end!,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;

      if (appointmentId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Appointment booked successfully!\nID: $appointmentId'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        throw Exception('Failed to create appointment');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd-MM-yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Start Time Picker
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time, color: Colors.blue),
                title: const Text('Start Time'),
                subtitle: Text(
                  start == null ? 'Tap to pick start time' : fmt.format(start!),
                  style: TextStyle(
                    color: start == null ? Colors.grey : Colors.black87,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: pickStart,
              ),
            ),

            const SizedBox(height: 12),

            // End Time Picker
            Card(
              child: ListTile(
                leading: const Icon(Icons.timer, color: Colors.blue),
                title: const Text('End Time'),
                subtitle: Text(
                  end == null ? 'Tap to pick end time' : fmt.format(end!),
                  style: TextStyle(
                    color: end == null ? Colors.grey : Colors.black87,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: pickEnd,
              ),
            ),

            const SizedBox(height: 12),

            // Appointment Mode
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consultation Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: mode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (v) => setState(() => mode = v!),
                      items: const [
                        DropdownMenuItem(
                          value: 'video',
                          child: Row(
                            children: [
                              Icon(Icons.video_call, color: Colors.blue),
                              SizedBox(width: 12),
                              Text('Video Consultation'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'offline',
                          child: Row(
                            children: [
                              Icon(Icons.local_hospital, color: Colors.green),
                              SizedBox(width: 12),
                              Text('In-person Visit'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Notes (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Add any special requests or concerns...',
                        contentPadding: EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: loading ? null : submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle),
                        SizedBox(width: 12),
                        Text(
                          'Book Appointment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 16),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your appointment will be confirmed automatically. '
                        'You will receive a meeting link for video consultations.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}