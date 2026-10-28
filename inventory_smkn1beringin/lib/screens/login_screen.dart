import 'package:flutter/material.dart';

import '../models/item_model.dart';
import 'admin_dashboard.dart';
import 'register_screen.dart';
import 'user_dashboard.dart';

// ============================================================
// LOGIN COLORS
// ============================================================

class LoginColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5148D8);

  static const Color background = Color(0xFFF8F9FD);
  static const Color card = Colors.white;

  static const Color textDark = Color(0xFF24263A);
  static const Color textGrey = Color(0xFF7A7F95);
  static const Color border = Color(0xFFE5E7F0);

  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
}

// ============================================================
// HELPER SNACKBAR
// ============================================================

void showAppSnack(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? LoginColors.error : LoginColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
}

// ============================================================
// AUTH SCAFFOLD
// ============================================================

class AuthScaffold extends StatelessWidget {
  final Widget child;

  const AuthScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Dekorasi kanan atas
            Positioned(
              top: -115,
              right: -105,
              child: Container(
                width: 245,
                height: 245,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LoginColors.primary.withAlpha(18),
                ),
              ),
            ),

            // Dekorasi kiri bawah
            Positioned(
              bottom: -135,
              left: -115,
              child: Container(
                width: 275,
                height: 275,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withAlpha(10),
                ),
              ),
            ),

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PRIMARY BUTTON
// ============================================================

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: LoginColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              LoginColors.primary.withAlpha(150),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 23,
                height: 23,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ============================================================
// LOGIN SCREEN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Peringatan dari hasil login, ditampilkan di bawah masing-masing kolom.
  String? _usernameError;
  String? _passwordError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  // Hapus peringatan hasil login (di bawah username dan password).
  void _clearLoginErrors() {
    if (_usernameError == null && _passwordError == null) return;

    setState(() {
      _usernameError = null;
      _passwordError = null;
    });
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _usernameError = null;
      _passwordError = null;
      _isLoading = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    final identifier = _usernameController.text.trim();
    final password = _passwordController.text;

    final user = AuthService.login(
      identifier: identifier,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (user == null) {
      final exists = AuthService.findByUsername(identifier) != null;

      setState(() {
        if (exists) {
          _usernameError = null;
          _passwordError = 'Password salah.';
        } else if (AuthService.isPending(identifier)) {
          _passwordError = null;
          _usernameError =
              'Akun belum disetujui Admin Utama. Silakan tunggu.';
        } else {
          // Username tidak ada. Password ikut ditandai salah hanya bila
          // password itu juga tidak cocok dengan akun mana pun.
          final passwordKnown = AuthService.approvedAccounts.any(
            (a) => a.password == password,
          );

          _usernameError = 'Username tidak ditemukan.';
          _passwordError = passwordKnown ? null : 'Password salah.';
        }
      });

      // Kembalikan fokus ke kolom yang bermasalah agar bisa langsung diketik.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_passwordError != null && _usernameError == null) {
          // Hanya password yang salah: blok semua isinya supaya
          // langsung bisa dihapus / diketik ulang.
          _passwordFocus.requestFocus();
          _passwordController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _passwordController.text.length,
          );
        } else {
          _usernameFocus.requestFocus();
        }
      });
      return;
    }

    showAppSnack(
      context,
      'Login berhasil. Selamat datang, ${user.nama}!',
    );

    await Future.delayed(
      const Duration(milliseconds: 250),
    );

    if (!mounted) return;

    // ADMIN
    if (user.isAdmin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(
            user: user,
          ),
        ),
      );
      return;
    }

    // USER
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => UserDashboardScreen(
          user: user,
        ),
      ),
    );
  }

  // ==========================================================
  // VALIDATION
  // ==========================================================

  String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username wajib diisi.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi.';
    }

    if (value.length < 4) {
      return 'Password minimal 4 karakter.';
    }

    return null;
  }

  // ==========================================================
  // INPUT DECORATION
  // ==========================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,

      prefixIcon: Icon(
        icon,
        color: LoginColors.primary,
      ),

      suffixIcon: suffixIcon,

      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),

      labelStyle: const TextStyle(
        color: LoginColors.textGrey,
        fontWeight: FontWeight.w500,
      ),

      hintStyle: const TextStyle(
        color: Color(0xFFB0B4C4),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: LoginColors.border,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: LoginColors.primary,
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: LoginColors.error,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: LoginColors.error,
          width: 1.5,
        ),
      ),

      errorStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ==========================================================
  // LOGO - TRANSPARENT
  // ==========================================================

  Widget _buildLogo() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Image.asset(
        'assets/image/logo_smkn1_beringin.png',
cacheWidth: 300,

        // TIDAK ADA CONTAINER PUTIH
        // TIDAK ADA CIRCLE
        // TIDAK ADA CLIP OVAL
        fit: BoxFit.contain,

        errorBuilder: (_, __, ___) {
          return const Icon(
            Icons.school_rounded,
            size: 60,
            color: LoginColors.primary,
          );
        },
      ),
    );
  }

  // ==========================================================
  // SCHOOL INFO
  // ==========================================================

  Widget _buildSchoolInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: LoginColors.primary.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LoginColors.primary.withAlpha(22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: LoginColors.primary.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: LoginColors.primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SMK Negeri 1 Beringin',
                  style: TextStyle(
                    color: LoginColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'PPLG • Task & Inventory Manager',
                  style: TextStyle(
                    color: LoginColors.textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          22,
          14,
          22,
          26,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [



              // ==================================================
              // LOGO + WELCOME
              // ==================================================

              Center(
                child: Column(
                  children: [
                    // LOGO TANPA BACKGROUND
                    _buildLogo(),

                    const SizedBox(height: 8),

                    const Text(
                      'Task & Inventory Manager',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: LoginColors.textDark,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'SMKN 1 BERINGIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: LoginColors.textGrey,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // GARIS AKSEN
                    Container(
                      width: 46,
                      height: 4,
                      decoration: BoxDecoration(
                        color: LoginColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // LOGIN CARD
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  19,
                  20,
                  19,
                ),
                decoration: BoxDecoration(
                  color: LoginColors.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: LoginColors.border.withAlpha(150),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 24,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    const Text(
                      'Login',
                      style: TextStyle(
                        color: LoginColors.textDark,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Masuk menggunakan username akunmu.',
                      style: TextStyle(
                        color: LoginColors.textGrey,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // USERNAME
                    // ==================================================

                    TextFormField(
                      controller: _usernameController,
                      keyboardType:
                          TextInputType.text,
                      textInputAction:
                          TextInputAction.next,

                      autofillHints: const [
                        AutofillHints.username,
                      ],

                      onChanged: (_) => _clearLoginErrors(),

                      focusNode: _usernameFocus,

                      validator: _validateIdentifier,

                      decoration: _inputDecoration(
                        label: 'Username',
                        hint: 'Masukkan username',
                        icon: Icons.person_outline_rounded,
                        errorText: _usernameError,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // PASSWORD
                    // ==================================================

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction:
                          TextInputAction.done,

                      autofillHints: const [
                        AutofillHints.password,
                      ],

                      onFieldSubmitted: (_) {
                        if (!_isLoading) {
                          _handleLogin();
                        }
                      },

                      onChanged: (_) => _clearLoginErrors(),

                      focusNode: _passwordFocus,

                      validator: _validatePassword,

                      decoration: _inputDecoration(
                        label: 'Password',
                        hint: 'Masukkan password',
                        icon: Icons.lock_outline_rounded,
                        errorText: _passwordError,

                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Tampilkan password'
                              : 'Sembunyikan password',

                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },

                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color:
                                LoginColors.textGrey,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // LOGIN BUTTON
                    // ==================================================

                    PrimaryButton(
                      text: 'Masuk ke Dashboard',
                      icon: Icons.login_rounded,
                      loading: _isLoading,
                      onPressed: _handleLogin,
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // SECURITY INFO
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F3FF),
                        borderRadius:
                            BorderRadius.circular(13),
                        border: Border.all(
                          color:
                              LoginColors.primary.withAlpha(15),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.security_rounded,
                            color: LoginColors.primary,
                            size: 19,
                          ),

                          SizedBox(width: 9),

                          Expanded(
                            child: Text(
                              'Gunakan akun yang sudah terdaftar untuk mengakses dashboard sesuai peran akun.',
                              style: TextStyle(
                                color: LoginColors.textGrey,
                                fontSize: 11.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // ATAU
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: LoginColors.border,
                      thickness: 1,
                    ),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    child: Text(
                      'ATAU',
                      style: TextStyle(
                        color: LoginColors.textGrey
                            .withAlpha(180),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Divider(
                      color: LoginColors.border,
                      thickness: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ==================================================
              // REGISTER
              // ==================================================

              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text(
                      'Belum punya akun? ',
                      style: TextStyle(
                        color: LoginColors.textGrey,
                        fontSize: 13,
                      ),
                    ),

                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const RegisterScreen(),
                                ),
                              );
                            },
                      child: const Text(
                        'Daftar sekarang',
                        style: TextStyle(
                          color: LoginColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // SCHOOL IDENTITY
              // ==================================================

              _buildSchoolInfo(),

              const SizedBox(height: 15),

              // ==================================================
              // COPYRIGHT
              // ==================================================

              Center(
                child: Text(
                  '© ${DateTime.now().year} SMK Negeri 1 Beringin',
                  style: const TextStyle(
                    color: LoginColors.textGrey,
                    fontSize: 11,
                  ),
                ),
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
