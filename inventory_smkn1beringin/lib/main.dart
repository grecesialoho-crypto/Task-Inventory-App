import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/item_model.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Muat data tersimpan (akun, riwayat persetujuan, tugas & inventory).
  await AppStorage.init();
  AuthService.load();
  ItemStore.load();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF5F7FB),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const TaskInventoryApp());
}

// ============================================================
// APP COLORS
// ============================================================

class AppColors {
  static const navy = Color(0xFF07152E);
  static const navyLight = Color(0xFF10294D);
  static const blue = Color(0xFF3478F6);
  static const cyan = Color(0xFF43C6E8);
  static const green = Color(0xFF10B981);
  static const background = Color(0xFFF5F7FB);
  static const text = Color(0xFF172B4D);
  static const muted = Color(0xFF718096);
}

// ============================================================
// MAIN APP
// ============================================================

class TaskInventoryApp extends StatefulWidget {
  const TaskInventoryApp({super.key});

  @override
  State<TaskInventoryApp> createState() => _TaskInventoryAppState();
}

class _TaskInventoryAppState extends State<TaskInventoryApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Simpan ulang semua data saat aplikasi ditutup / masuk latar belakang.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      AuthService.saveNow();
      ItemStore.saveNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMKN 1 Beringin',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.background,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          primary: AppColors.blue,
          secondary: AppColors.green,
          surface: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F9FC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.blue,
              width: 1.7,
            ),
          ),
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.zero,
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        floatingActionButtonTheme:
            FloatingActionButtonThemeData(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),

      // APLIKASI LANGSUNG MEMBUKA HALAMAN LOGIN
      initialRoute: '/login',

      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
