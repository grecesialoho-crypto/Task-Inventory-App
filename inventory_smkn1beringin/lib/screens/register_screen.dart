import 'package:flutter/material.dart';
import '../models/item_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ============================================================
  // FORM
  // ============================================================

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _usernameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;
  String _selectedRole = 'User';

  String? _errorMessage;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF7F9FC);
  static const Color textDark = Color(0xFF172033);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF16A34A);

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    final String name = _nameController.text.trim();
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    // ==========================================================
    // REGISTER
    //
    // AuthService.register pada item_model.dart menggunakan
    // named parameter:
    // username, password, role, email, dan name.
    // ==========================================================

    final String? error = AuthService.register(
      username: username,
      password: password,
      role: _selectedRole,
      email: email,
      name: name,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      setState(() {
        _errorMessage = error;
      });
      return;
    }

    await _showSuccessDialog();
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            28,
            24,
            20,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: successColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: successColor,
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Registrasi Berhasil!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pendaftaran berhasil dikirim. Akun belum bisa digunakan sebelum disetujui oleh Admin Utama. Silakan tunggu persetujuan terlebih dahulu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Kembali ke Login',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _validateName(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Nama lengkap wajib diisi';
    }

    if (text.length < 3) {
      return 'Nama minimal 3 karakter';
    }

    return null;
  }

  String? _validateUsername(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Username wajib diisi';
    }

    if (text.length < 4) {
      return 'Username minimal 4 karakter';
    }

    if (text.contains(' ')) {
      return 'Username tidak boleh menggunakan spasi';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Email wajib diisi';
    }

    final RegExp emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(text)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final String text = value ?? '';

    if (text.isEmpty) {
      return 'Password wajib diisi';
    }

    if (text.length < 6) {
      return 'Password minimal 6 karakter';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final String text = value ?? '';

    if (text.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }

    if (text != _passwordController.text) {
      return 'Password tidak sama';
    }

    return null;
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return SizedBox(
      width: 105,
      height: 105,
      child: Image.asset(
        'assets/image/logo_smkn1_beringin.png',
cacheWidth: 300,
        fit: BoxFit.contain,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return Container(
            decoration: BoxDecoration(
              color: primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
              size: 48,
              color: primary,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: primary,
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(
        color: textMuted,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: primary,
          width: 1.7,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: errorColor,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: errorColor,
          width: 1.5,
        ),
      ),
      errorStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              top: -80,
              right: -70,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  color: primary.withAlpha(15),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              bottom: -90,
              left: -80,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  color: primary.withAlpha(12),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                  ),
                  child: Column(
                    children: [
                      // ==================================================
                      // BACK BUTTON
                      // ==================================================

                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                },
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                          ),
                          color: textDark,
                          tooltip: 'Kembali',
                        ),
                      ),

                      const SizedBox(height: 2),

                      // ==================================================
                      // LOGO
                      // ==================================================

                      _buildLogo(),

                      const SizedBox(height: 12),

                      // ==================================================
                      // TITLE
                      // ==================================================

                      const Text(
                        'Buat Akun Baru',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),

                      const SizedBox(height: 7),

                      const Text(
                        'Daftarkan akun untuk menggunakan\n'
                        'Task & Inventory Manager',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: textMuted,
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ==================================================
                      // FORM CARD
                      // ==================================================

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Informasi Akun',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                ),
                              ),

                              const SizedBox(height: 4),

                              const Text(
                                'Pilih role akun, lalu tunggu persetujuan Admin Utama sebelum login.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: textMuted,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ==================================================
                              // NAMA
                              // ==================================================

                              TextFormField(
                                controller: _nameController,
                                textInputAction:
                                    TextInputAction.next,
                                textCapitalization:
                                    TextCapitalization.words,
                                validator: _validateName,
                                decoration: _inputDecoration(
                                  label: 'Nama Lengkap',
                                  hint: 'Masukkan nama lengkap',
                                  icon: Icons.person_outline_rounded,
                                ),
                              ),

                              const SizedBox(height: 15),

                              // ==================================================
                              // USERNAME
                              // ==================================================

                              TextFormField(
                                controller: _usernameController,
                                textInputAction:
                                    TextInputAction.next,
                                autocorrect: false,
                                validator: _validateUsername,
                                decoration: _inputDecoration(
                                  label: 'Username',
                                  hint: 'Contoh: user123',
                                  icon:
                                      Icons.alternate_email_rounded,
                                ),
                              ),

                              const SizedBox(height: 15),

                              // ==================================================
                              // ROLE AKUN
                              // ==================================================

                              DropdownButtonFormField<String>(
                                initialValue: _selectedRole,
                                isExpanded: true,
                                decoration: _inputDecoration(
                                  label: 'Role Akun',
                                  hint: 'Pilih role akun',
                                  icon: Icons.admin_panel_settings_outlined,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'User',
                                    child: Text('User'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Admin',
                                    child: Text('Admin'),
                                  ),
                                ],
                                onChanged: _isLoading
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setState(() {
                                          _selectedRole = value;
                                        });
                                      },
                                validator: (value) =>
                                    value == null ? 'Pilih role akun.' : null,
                              ),

                              const SizedBox(height: 15),

                              // ==================================================
                              // EMAIL
                              // ==================================================

                              TextFormField(
                                controller: _emailController,
                                keyboardType:
                                    TextInputType.emailAddress,
                                textInputAction:
                                    TextInputAction.next,
                                autocorrect: false,
                                validator: _validateEmail,
                                decoration: _inputDecoration(
                                  label: 'Email',
                                  hint: 'contoh@email.com',
                                  icon: Icons.email_outlined,
                                ),
                              ),

                              const SizedBox(height: 15),

                              // ==================================================
                              // PASSWORD
                              // ==================================================

                              TextFormField(
                                controller: _passwordController,
                                obscureText:
                                    _isPasswordObscured,
                                textInputAction:
                                    TextInputAction.next,
                                validator: _validatePassword,
                                decoration: _inputDecoration(
                                  label: 'Password',
                                  hint: 'Minimal 6 karakter',
                                  icon:
                                      Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordObscured =
                                            !_isPasswordObscured;
                                      });
                                    },
                                    icon: Icon(
                                      _isPasswordObscured
                                          ? Icons
                                              .visibility_outlined
                                          : Icons
                                              .visibility_off_outlined,
                                      color: textMuted,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 15),

                              // ==================================================
                              // KONFIRMASI PASSWORD
                              // ==================================================

                              TextFormField(
                                controller:
                                    _confirmPasswordController,
                                obscureText:
                                    _isConfirmPasswordObscured,
                                textInputAction:
                                    TextInputAction.done,
                                validator:
                                    _validateConfirmPassword,
                                onFieldSubmitted: (_) {
                                  if (!_isLoading) {
                                    _register();
                                  }
                                },
                                decoration: _inputDecoration(
                                  label: 'Konfirmasi Password',
                                  hint: 'Masukkan ulang password',
                                  icon:
                                      Icons.lock_reset_rounded,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isConfirmPasswordObscured =
                                            !_isConfirmPasswordObscured;
                                      });
                                    },
                                    icon: Icon(
                                      _isConfirmPasswordObscured
                                          ? Icons
                                              .visibility_outlined
                                          : Icons
                                              .visibility_off_outlined,
                                      color: textMuted,
                                    ),
                                  ),
                                ),
                              ),

                              // ==================================================
                              // ERROR
                              // ==================================================

                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                    color:
                                        errorColor.withAlpha(15),
                                    borderRadius:
                                        BorderRadius.circular(13),
                                    border: Border.all(
                                      color:
                                          errorColor.withAlpha(45),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons
                                            .error_outline_rounded,
                                        color: errorColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style:
                                              const TextStyle(
                                            color: errorColor,
                                            fontSize: 12.5,
                                            height: 1.4,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 20),

                              // ==================================================
                              // REGISTER BUTTON
                              // ==================================================

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    disabledBackgroundColor:
                                        primary.withAlpha(100),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<
                                                    Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .center,
                                          children: [
                                            Icon(
                                              Icons
                                                  .person_add_alt_1_rounded,
                                              size: 20,
                                            ),
                                            SizedBox(width: 9),
                                            Text(
                                              'Daftar Sekarang',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 17),

                              // ==================================================
                              // INFO
                              // ==================================================

                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFF8FAFC),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                    color: borderColor,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.shield_outlined,
                                      color: primary,
                                      size: 19,
                                    ),
                                    SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        'Data akun digunakan untuk '
                                        'proses login aplikasi.',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          height: 1.35,
                                          color: textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // LOGIN
                      // ==================================================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Sudah punya akun?',
                            style: TextStyle(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: primary,
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                            ),
                            child: const Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      const Text(
                        'SMK Negeri 1 Beringin • PPLG',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
