import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// ═══════════════════════════════════════════════════════════════════════════
//                        📥 SCREEN IMPORTS
// ═══════════════════════════════════════════════════════════════════════════

// Authentication Screens
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/auth/doctor_signup.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/role_select_screen.dart';
import 'screens/kyc_upload_screen.dart';

// Doctor Screens
import 'screens/doctor_home_screen.dart';
import 'screens/doctor_profile_screen.dart';
import 'screens/doctor_schedule_screen.dart';
import 'screens/doctor_appointments_screen.dart';

// Patient Screens
import 'screens/patient_home_screen.dart';
import 'screens/patient_profile_screen.dart';
import 'screens/patient_search_screen.dart';
import 'screens/patient_appointments_screen.dart';
import 'screens/patient_slots_screen.dart';

// Shared Screens
import 'screens/appointment_screen.dart';
import 'screens/appointment_details_screen.dart';
import 'screens/video_call_screen.dart'; // ✅ NOW USES WEBRTC (cross-platform)
import 'screens/transcript_viewer_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//                        🚀 MAIN ENTRY POINT
// ═══════════════════════════════════════════════════════════════════════════

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  try {
    developer.log('═══════════════════════════════════════════', name: 'DocVartaa');
    developer.log('🏥 DOCVARTAA - Telemedicine Platform', name: 'DocVartaa');
    developer.log('📅 Version 4.0.0 - WebRTC Integration', name: 'DocVartaa');
    developer.log('═══════════════════════════════════════════', name: 'DocVartaa');

    // ───────────────────────────────────────────────────────────────────────
    // Initialize Firebase
    // ───────────────────────────────────────────────────────────────────────
    developer.log('🔥 Initializing Firebase...', name: 'Startup');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    developer.log('✅ Firebase initialized successfully', name: 'Startup');

    // ───────────────────────────────────────────────────────────────────────
    // Video calling info
    // ───────────────────────────────────────────────────────────────────────
    developer.log('🎥 Video calling: WebRTC (cross-platform)', name: 'Startup');
    developer.log('✅ No configuration needed - ready to use!', name: 'Startup');
    developer.log('✅ FREE unlimited video calls', name: 'Startup');

    // ───────────────────────────────────────────────────────────────────────
    // Run the app
    // ───────────────────────────────────────────────────────────────────────
    developer.log('🚀 Starting DocVartaa app...', name: 'Startup');
    developer.log('═══════════════════════════════════════════', name: 'DocVartaa');
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    // Fatal initialization error
    developer.log(
      '❌ FATAL ERROR during initialization',
      name: 'Startup',
      error: e,
      stackTrace: stackTrace,
    );
    
    // Show error screen
    runApp(ErrorApp(error: e.toString()));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//                        📱 ROOT APP WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocVartaa - Telemedicine Platform',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      
      home: const AuthWrapper(),
      
      routes: {
        // AUTHENTICATION ROUTES
        '/sign-in': (_) => const SignInScreen(),
        '/signin': (_) => const SignInScreen(),
        '/login': (_) => const SignInScreen(),
        '/sign-up': (_) => const SignUpScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/register': (_) => const SignUpScreen(),
        '/doctor-signup': (_) => const DoctorSignUpScreen(),
        '/doctorSignup': (_) => const DoctorSignUpScreen(),
        '/doctor-register': (_) => const DoctorSignUpScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/forgotPassword': (_) => const ForgotPasswordScreen(),
        '/reset-password': (_) => const ForgotPasswordScreen(),
        '/role-select': (_) => RoleSelectScreen(),
        '/roleSelect': (_) => RoleSelectScreen(),
        '/kyc-upload': (_) => const KycUploadScreen(),
        '/kycUpload': (_) => const KycUploadScreen(),

        // DOCTOR ROUTES
        '/doctorHome': (_) => const DoctorHomeScreen(),
        '/doctor-home': (_) => const DoctorHomeScreen(),
        '/doctor_home': (_) => const DoctorHomeScreen(),
        '/doc-home': (_) => const DoctorHomeScreen(),
        '/doctorProfile': (_) => const DoctorProfileScreen(),
        '/doctor-profile': (_) => const DoctorProfileScreen(),
        '/doctor_profile': (_) => const DoctorProfileScreen(),
        '/schedule': (_) => const DoctorScheduleScreen(),
        '/doctor-schedule': (_) => const DoctorScheduleScreen(),
        '/doctorSchedule': (_) => const DoctorScheduleScreen(),
        '/doctor_schedule': (_) => const DoctorScheduleScreen(),
        '/doc-schedule': (_) => const DoctorScheduleScreen(),
        '/doctorAppointments': (_) => const DoctorAppointmentsScreen(),
        '/doctor-appointments': (_) => const DoctorAppointmentsScreen(),
        '/doctor_appointments': (_) => const DoctorAppointmentsScreen(),
        '/doc-appointments': (_) => const DoctorAppointmentsScreen(),

        // PATIENT ROUTES
        '/patientHome': (_) => const PatientHomeScreen(),
        '/patient-home': (_) => const PatientHomeScreen(),
        '/patient_home': (_) => const PatientHomeScreen(),
        '/patientProfile': (_) => const PatientProfileScreen(),
        '/patient-profile': (_) => const PatientProfileScreen(),
        '/patient_profile': (_) => const PatientProfileScreen(),
        '/searchDoctors': (_) => const PatientSearchScreen(),
        '/search-doctors': (_) => const PatientSearchScreen(),
        '/search_doctors': (_) => const PatientSearchScreen(),
        '/find-doctors': (_) => const PatientSearchScreen(),
        '/doctors': (_) => const PatientSearchScreen(),
        '/patientAppointments': (_) => const PatientAppointmentsScreen(),
        '/patient-appointments': (_) => const PatientAppointmentsScreen(),
        '/patient_appointments': (_) => const PatientAppointmentsScreen(),
        '/bookSlot': (_) => const PatientSlotsScreen(),
        '/book-slot': (_) => const PatientSlotsScreen(),
        '/book_slot': (_) => const PatientSlotsScreen(),
        '/slots': (_) => const PatientSlotsScreen(),
        '/instantConsult': (_) => const PatientSearchScreen(),
        '/instant-consult': (_) => const PatientSearchScreen(),
        '/instant_consult': (_) => const PatientSearchScreen(),

        // SHARED ROUTES
        '/appointments': (_) => const AppointmentsScreen(),
        '/appointment': (_) => const AppointmentsScreen(),
        '/transcripts': (_) => const TranscriptViewerScreen(),
        '/transcript': (_) => const TranscriptViewerScreen(),
      },
      
      onGenerateRoute: (RouteSettings settings) {
        developer.log('🧭 Navigation: ${settings.name}', name: 'Router');

        // APPOINTMENT DETAILS
        if (settings.name == '/appointment-details' ||
            settings.name == '/appointmentDetails' ||
            settings.name == '/appointment_details') {
          String? appointmentId;
          
          if (settings.arguments is Map<String, dynamic>) {
            appointmentId = (settings.arguments as Map<String, dynamic>)['appointmentId'];
          } else if (settings.arguments is String) {
            appointmentId = settings.arguments as String;
          }

          if (appointmentId != null && appointmentId.isNotEmpty) {
            developer.log('✅ Appointment details: $appointmentId', name: 'Router');
            return MaterialPageRoute(
              builder: (_) => AppointmentDetailsScreen(apptId: appointmentId!),
              settings: settings,
            );
          }
        }

        // VIDEO CALL (WebRTC)
        if (settings.name == '/video-call' ||
            settings.name == '/videoCall' ||
            settings.name == '/video_call' ||
            settings.name == '/call') {
          if (settings.arguments is Map<String, dynamic>) {
            final args = settings.arguments as Map<String, dynamic>;
            final callId = args['callId'] as String?;
            final appointmentId = args['appointmentId'] as String?;
            final isDoctor = args['isDoctor'] as bool? ?? false;

            if (callId != null && appointmentId != null) {
              developer.log('📞 Video call: $callId (WebRTC)', name: 'Router');
              return MaterialPageRoute(
                builder: (_) => VideoCallScreen(
                  callId: callId,
                  appointmentId: appointmentId,
                  isDoctor: isDoctor,
                ),
                settings: settings,
              );
            }
          }
        }

        // 404 NOT FOUND
        developer.log('❌ Route not found: ${settings.name}', name: 'Router');
        return _build404Route(settings.name ?? 'Unknown');
      },
    );
  }

  MaterialPageRoute _build404Route(String routeName) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
          backgroundColor: Colors.red,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 100, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    '404 - Route Not Found',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Route: $routeName',
                      style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Available Routes:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('• /sign-in, /sign-up'),
                        Text('• /doctorHome, /patientHome'),
                        Text('• /doctor-schedule ✅'),
                        Text('• /search-doctors ✅'),
                        Text('• /video-call (WebRTC)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                    icon: const Icon(Icons.home),
                    label: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//                        🔐 AUTHENTICATION WRAPPER
// ═══════════════════════════════════════════════════════════════════════════

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        developer.log('🔐 Auth state: ${snapshot.connectionState}', name: 'AuthWrapper');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          developer.log('👤 No user authenticated', name: 'AuthWrapper');
          return const SignInScreen();
        }

        developer.log('👤 User: ${snapshot.data!.uid}', name: 'AuthWrapper');
        return RoleBasedRouter(user: snapshot.data!);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//                        🎯 ROLE-BASED ROUTER
// ═══════════════════════════════════════════════════════════════════════════

class RoleBasedRouter extends StatelessWidget {
  final User user;

  const RoleBasedRouter({super.key, required this.user});

  Future<String> _getUserRole(String uid) async {
    developer.log('🔍 Fetching role: $uid', name: 'RoleRouter');

    try {
      // Check doctors collection
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .get();

      if (doctorDoc.exists) {
        developer.log('👨‍⚕️ Role: DOCTOR', name: 'RoleRouter');
        return 'doctor';
      }

      // Check users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final role = data?['role'] ?? data?['userType'] ?? 'patient';
        developer.log('👤 Role: $role', name: 'RoleRouter');
        return role;
      }

      developer.log('⚠️  No document, defaulting to PATIENT', name: 'RoleRouter');
      return 'patient';
    } catch (e) {
      developer.log('❌ Error: $e', name: 'RoleRouter');
      return 'patient';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getUserRole(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking your role...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        }

        final role = snapshot.data ?? 'patient';
        developer.log('🎯 Routing to: $role HOME', name: 'RoleRouter');

        return role == 'doctor' ? const DoctorHomeScreen() : const PatientHomeScreen();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//                        ❌ ERROR APP
// ═══════════════════════════════════════════════════════════════════════════

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 120, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    'Initialization Failed',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Text(
                      error,
                      style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Troubleshooting:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('✓ Check internet connection'),
                        Text('✓ Verify Firebase configuration'),
                        Text('✓ Run: flutter clean && flutter pub get'),
                        Text('✓ Check console logs'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}