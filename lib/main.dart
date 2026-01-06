import 'package:flutter/material.dart';
import 'package:nebeng_app/SplashScreen.dart';
import 'package:nebeng_app/providers/connectivity_service.dart';
import 'package:nebeng_app/providers/report_note_provider.dart';
import 'package:nebeng_app/providers/report_provider.dart';
import 'package:nebeng_app/providers/student_class_provider.dart';
import 'package:nebeng_app/providers/student_provider.dart';
import 'package:nebeng_app/providers/user_provider.dart';
import 'package:nebeng_app/screens/DashboardScreen.dart';
import 'package:nebeng_app/screens/assigned_reports_screen.dart';
import 'package:nebeng_app/screens/home/backup/home_screen.dart';
import 'package:nebeng_app/screens/home/home_screen.dart';
import 'package:nebeng_app/screens/profile_screen.dart';
import 'package:nebeng_app/screens/reports/add_report_screen.dart';
import 'package:nebeng_app/screens/reports/my_reports_screen.dart';
import 'package:nebeng_app/screens/reports/report_detail_screen.dart';
import 'package:nebeng_app/screens/reports/report_list_screen.dart';
import 'package:nebeng_app/screens/reports/student_selection_for_report_screen.dart';
import 'package:nebeng_app/screens/students/student_list_screen.dart';
import 'package:nebeng_app/screens/students_screen.dart';
import 'package:nebeng_app/utils/app_styles.dart';
import 'package:provider/provider.dart';
import 'package:nebeng_app/providers/auth_provider.dart'; // Nanti akan dibuat
import 'package:nebeng_app/screens/auth/login_screen.dart';
// import 'package:nebeng_app/screens/home/home_screen.dart';
import 'package:nebeng_app/utils/app_colors.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, StudentProvider>(
          create:
              (context) => StudentProvider(
                Provider.of<AuthProvider>(context, listen: false),
              ),
          update:
              (context, auth, previousStudentProvider) => StudentProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReportProvider>(
          create:
              (context) => ReportProvider(
                Provider.of<AuthProvider>(context, listen: false),
              ),
          update:
              (context, auth, previousReportProvider) => ReportProvider(auth),
        ),
        // Add ReportNoteProvider here
        ChangeNotifierProxyProvider<AuthProvider, ReportNoteProvider>(
          create:
              (context) => ReportNoteProvider(
                Provider.of<AuthProvider>(context, listen: false),
              ),
          update:
              (context, auth, previousReportNoteProvider) =>
                  ReportNoteProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, StudentClassProvider>(
          create:
              (context) => StudentClassProvider(
                Provider.of<AuthProvider>(context, listen: false),
              ),
          update:
              (context, auth, previousReportNoteProvider) =>
                  StudentClassProvider(auth),
        ),
        ChangeNotifierProvider(
          create:
              (context) => UserProvider(
                Provider.of<AuthProvider>(context, listen: false),
              ),
        ), 
         Provider<ConnectivityService>(create: (context) => ConnectivityService()),
// <-- Tambahkan ini
      ],
      child: MaterialApp(
        title: 'Nebeng App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: AppColors.primaryBlue,
          scaffoldBackgroundColor: AppColors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.white,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: AppColors.black),
            bodyMedium: TextStyle(color: AppColors.black),
            titleLarge: TextStyle(color: AppColors.black),
          ),
          buttonTheme: const ButtonThemeData(
            buttonColor: AppColors.primaryBlue,
            textTheme: ButtonTextTheme.primary,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.white,
          ),
          cardTheme: CardTheme(
            color: AppColors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.lightGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        home: SplashScreen(),

        routes: {
          '/login': (context) => const LoginScreen(),
          // '/home': (context) => const HomeScreen(),
          '/home':
              (context) =>
                  const HomeScreen(), // Rute baru untuk MainScreen (dengan Navbar)
          // Tambahkan rute untuk layar lain
          '/add-report': (context) => const StudentSelectionForReportScreen(),
          '/my-reports': (context) => const MyReportsScreen(), // Laporanku
          '/my-tasks': (context) => const AssignedReportsScreen(), // Tugasku
          '/my-students': (context) => const StudentsScreen(), // Siswaku
          '/my-profile': (context) => const ProfileScreen(), // Profilku
          // '/report-detail': (context) {
          //   final args = ModalRoute.of(context)!.settings.arguments as int;
          //   return ReportDetailScreen(report: report,);
          // },
          '/students': (context) => const StudentListScreen(),
          '/reports': (context) => const ReportListScreen(),
          '/add_report_select_student':
              (context) =>
                  const StudentSelectionForReportScreen(), // Tambahkan rute ini
          // Tambahkan rute lain di sini
        },
      ),
    );
  }
}
