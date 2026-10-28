import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// APP OPTIONS
// ============================================================

class AppOptions {
  static const String inventory = 'Inventory Lab';
  static const String task = 'Tugas / Task';

  static const List<String> dataTypes = [
    inventory,
    task,
  ];

  // STATUS
  static const String statusDipinjam = 'Di Pinjam';
  static const String statusProses = 'Proses';
  static const String statusPending = 'Pending';
  static const String statusSelesai = 'Selesai';

  // 4 STATUS UTAMA
  static const List<String> inventoryStatuses = [
    statusDipinjam,
    statusProses,
    statusPending,
    statusSelesai,
  ];

  // Tugas tidak punya status "Di Pinjam".
  // Default tugas = Pending, lalu Admin yang menilai (Proses / Selesai).
  static const List<String> taskStatuses = [
    statusPending,
    statusProses,
    statusSelesai,
  ];

  // Semua status yang masih dikenali model
  static const List<String> statuses = [
    statusDipinjam,
    statusProses,
    statusPending,
    statusProses,
    statusSelesai,
  ];

  // KATEGORI INVENTORY
  static const List<String> inventoryCategories = [
    'Laptop ASUS',
    'Buku Pemrograman',
    'Komputer',
    'Inventaris',
  ];

  // KATEGORI TUGAS
  static const List<String> taskCategories = [
    'Task',
    'Tugas',
    'Project Flutter',
  ];

  static const List<String> categories = [
    ...inventoryCategories,
    ...taskCategories,
  ];

  static List<String> categoriesFor(String type) {
    return type == task
        ? taskCategories
        : inventoryCategories;
  }

  static List<String> statusesFor(String type) {
    return type == task
        ? taskStatuses
        : inventoryStatuses;
  }

  static String defaultCategoryFor(String type) {
    return categoriesFor(type).first;
  }

  static String defaultStatusFor(String type) {
    return statusesFor(type).first;
  }

  static Color typeColor(String type) {
    if (type == task) {
      return const Color(0xFF0F9D85);
    }

    return const Color(0xFF2563EB);
  }

  static IconData typeIcon(String type) {
    if (type == task) {
      return Icons.task_alt_rounded;
    }

    return Icons.inventory_2_rounded;
  }

  // Satu sumber warna & ikon status untuk semua layar.
  static Color statusColor(String status) {
    switch (normalizeStatus(status).toLowerCase()) {
      case 'di pinjam':
        return const Color(0xFF7C3AED); // ungu

      case 'proses':
        return const Color(0xFF2563EB); // biru

      case 'pending':
        return const Color(0xFFD97706); // kuning tua

      case 'selesai':
        return const Color(0xFF16A34A); // hijau

      default:
        return const Color(0xFF64748B); // abu-abu
    }
  }

  static IconData statusIcon(String status) {
    switch (normalizeStatus(status).toLowerCase()) {
      case 'di pinjam':
        return Icons.inventory_2_outlined;

      case 'proses':
        return Icons.autorenew_rounded;

      case 'pending':
        return Icons.hourglass_top_rounded;

      case 'selesai':
        return Icons.task_alt_rounded;

      default:
        return Icons.info_outline_rounded;
    }
  }

  // User biasa hanya boleh melihat dua status:
  // Selesai (jika Admin sudah selesai mengoreksi) atau Pending.
  // Proses / Di Pinjam hanya terlihat oleh Admin.
  static String userVisibleStatus(String status) {
    return normalizeStatus(status) == statusSelesai
        ? statusSelesai
        : statusPending;
  }

  static String normalizeStatus(String status) {
    final value = status.trim().toLowerCase();

    switch (value) {
      case 'tersedia':
        return statusDipinjam;

      case 'proses':
      case 'process':
        return statusProses;

      case 'pending':
      case 'panding':
        return statusPending;

      case 'selesai':
      case 'done':
        return statusSelesai;

      default:
        return status.trim();
    }
  }
}

// ============================================================
// ALIAS
// ============================================================

const List<String> inventoryCategories =
    AppOptions.inventoryCategories;

const List<String> inventoryStatuses =
    AppOptions.inventoryStatuses;

const List<String> taskCategories =
    AppOptions.taskCategories;

const List<String> taskStatuses =
    AppOptions.taskStatuses;

Color getStatusColor(String status) {
  return AppOptions.statusColor(status);
}

// ============================================================
// PENYIMPANAN LOKAL (data tetap ada setelah aplikasi ditutup)
// ============================================================

class AppStorage {
  static SharedPreferences? _prefs;

  // Cadangan di memori, dipakai bila penyimpanan perangkat gagal dibuka.
  static final Map<String, String> _memory = {};

  static bool get isReady => _prefs != null;

  static Future<void> init() async {
    for (var attempt = 0; attempt < 2 && _prefs == null; attempt++) {
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (e) {
        debugPrint('AppStorage.init gagal: $e');
      }
    }
  }

  static String? read(String key) {
    try {
      return _prefs?.getString(key) ?? _memory[key];
    } catch (_) {
      return _memory[key];
    }
  }

  static Future<void> write(String key, String value) async {
    _memory[key] = value;

    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final ok = await prefs.setString(key, value);
      if (!ok) debugPrint('AppStorage: gagal menyimpan $key');
    } catch (e) {
      debugPrint('AppStorage.write gagal: $e');
    }
  }
}

// ============================================================
// ROLE
// ============================================================

class AppRoles {
  static const String superAdmin = 'Admin Utama';
  static const String admin = 'Admin';
  static const String user = 'User';

  static String normalize(String role) {
    final value = role.trim().toLowerCase();
    if (value == 'admin utama' || value == 'super admin') {
      return superAdmin;
    }
    if (value == 'admin') return admin;
    return user;
  }
}

// ============================================================
// USER ACCOUNT
// ============================================================

class UserAccount {
  final String username;
  final String password;
  final String role;
  final String email;
  final String name;

  const UserAccount({
    required this.username,
    required this.password,
    required this.role,
    required this.email,
    required this.name,
  });

  UserAccount copyWith({
    String? username,
    String? password,
    String? role,
    String? email,
    String? name,
  }) {
    return UserAccount(
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      email: email ?? this.email,
      name: name ?? this.name,
    );
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      username: '${map['username'] ?? ''}',
      password: '${map['password'] ?? ''}',
      role: AppRoles.normalize('${map['role'] ?? ''}'),
      email: '${map['email'] ?? ''}',
      name: '${map['name'] ?? ''}',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'role': role,
      'email': email,
      'name': name,
    };
  }

  String get nama => name;

  // Admin Utama dan Admin biasa sama-sama masuk dashboard admin.
  bool get isAdmin {
    final value = AppRoles.normalize(role);
    return value == AppRoles.admin || value == AppRoles.superAdmin;
  }

  // Hanya Admin Utama yang boleh menyetujui / menolak akun.
  bool get isSuperAdmin {
    return AppRoles.normalize(role) == AppRoles.superAdmin;
  }

  bool get isUser {
    return !isAdmin;
  }

  // User biasa tidak boleh mengubah status apa pun.
  bool get canChangeStatus => isAdmin;

  // User biasa tidak boleh menghapus data.
  bool get canDelete => isAdmin;

  bool get canApproveAccounts => isSuperAdmin;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return (
      parts.first[0] +
      parts.last[0]
    ).toUpperCase();
  }
}

// ============================================================
// RIWAYAT PERSETUJUAN AKUN
// ============================================================

class ApprovalRecord {
  static const String approved = 'Disetujui';
  static const String rejected = 'Ditolak';

  final String username;
  final String name;
  final String email;
  final String role;
  final String action; // Disetujui / Ditolak
  final String decidedBy; // username admin utama
  final String decidedByName;
  final DateTime decidedAt;

  const ApprovalRecord({
    required this.username,
    required this.name,
    required this.email,
    required this.role,
    required this.action,
    required this.decidedBy,
    required this.decidedByName,
    required this.decidedAt,
  });

  bool get isApproved => action == approved;

  factory ApprovalRecord.fromMap(Map<String, dynamic> map) {
    return ApprovalRecord(
      username: '${map['username'] ?? ''}',
      name: '${map['name'] ?? ''}',
      email: '${map['email'] ?? ''}',
      role: '${map['role'] ?? ''}',
      action: '${map['action'] ?? ''}',
      decidedBy: '${map['decidedBy'] ?? ''}',
      decidedByName: '${map['decidedByName'] ?? ''}',
      decidedAt: DateTime.tryParse('${map['decidedAt'] ?? ''}') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'name': name,
      'email': email,
      'role': role,
      'action': action,
      'decidedBy': decidedBy,
      'decidedByName': decidedByName,
      'decidedAt': decidedAt.toIso8601String(),
    };
  }
}

// ============================================================
// AUTH SERVICE
// ============================================================

class AuthService {
  static const String _kAccounts = 'auth_accounts_v1';
  static const String _kPending = 'auth_pending_v1';
  static const String _kHistory = 'auth_history_v1';

  // Akun yang sudah disetujui dan dapat login.
  // admin1 adalah Admin Utama (satu-satunya yang bisa menyetujui akun).
  static final List<UserAccount> _accounts = [
    const UserAccount(
      username: 'admin1',
      password: 'password',
      role: AppRoles.superAdmin,
      email: 'admin@smkn1beringin.sch.id',
      name: 'Administrator',
    ),
    const UserAccount(
      username: 'user1',
      password: 'password',
      role: AppRoles.user,
      email: 'user@smkn1beringin.sch.id',
      name: 'User PPLG',
    ),
  ];

  // Akun baru hanya disimpan di sini sampai disetujui Admin Utama.
  static final List<UserAccount> _pendingAccounts = [];

  // Riwayat keputusan persetujuan (terbaru di paling atas).
  static final List<ApprovalRecord> _history = [];

  static List<UserAccount> get pendingAccounts =>
      List<UserAccount>.unmodifiable(_pendingAccounts);

  static List<UserAccount> get approvedAccounts =>
      List<UserAccount>.unmodifiable(_accounts);

  static List<ApprovalRecord> get history =>
      List<ApprovalRecord>.unmodifiable(_history);

  // ----------------------------------------------------------
  // LOAD / SAVE
  // ----------------------------------------------------------

  static List<Map<String, dynamic>>? _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! List) return null;
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static void load() {
    final accounts = _decodeList(AppStorage.read(_kAccounts));
    if (accounts != null && accounts.isNotEmpty) {
      _accounts
        ..clear()
        ..addAll(accounts.map(UserAccount.fromMap));
    }

    // Pastikan selalu ada minimal satu Admin Utama.
    if (!_accounts.any((a) => a.isSuperAdmin)) {
      final index = _accounts.indexWhere(
        (a) => a.username.toLowerCase() == 'admin1',
      );
      if (index >= 0) {
        _accounts[index] =
            _accounts[index].copyWith(role: AppRoles.superAdmin);
      }
    }

    final pending = _decodeList(AppStorage.read(_kPending));
    if (pending != null) {
      _pendingAccounts
        ..clear()
        ..addAll(pending.map(UserAccount.fromMap));
    }

    final history = _decodeList(AppStorage.read(_kHistory));
    if (history != null) {
      _history
        ..clear()
        ..addAll(history.map(ApprovalRecord.fromMap));
    }
  }

  static void saveNow() => _save();

  static void _save() {
    AppStorage.write(
      _kAccounts,
      jsonEncode(_accounts.map((e) => e.toMap()).toList()),
    );
    AppStorage.write(
      _kPending,
      jsonEncode(_pendingAccounts.map((e) => e.toMap()).toList()),
    );
    AppStorage.write(
      _kHistory,
      jsonEncode(_history.map((e) => e.toMap()).toList()),
    );
  }

  // ----------------------------------------------------------
  // PENCARIAN & LOGIN
  // ----------------------------------------------------------

  static UserAccount? findByUsername(String username) {
    final value = username.trim().toLowerCase();
    if (value.isEmpty) return null;

    for (final account in _accounts) {
      if (account.username.trim().toLowerCase() == value) {
        return account;
      }
    }
    return null;
  }

  static UserAccount? findByEmail(String email) {
    final value = email.trim().toLowerCase();
    if (value.isEmpty) return null;

    for (final account in _accounts) {
      if (account.email.trim().toLowerCase() == value) {
        return account;
      }
    }
    return null;
  }

  static UserAccount? findAccount(String identifier) =>
      findByUsername(identifier) ?? findByEmail(identifier);

  static bool isPending(String identifier) {
    final value = identifier.trim().toLowerCase();
    if (value.isEmpty) return false;
    return _pendingAccounts.any(
      (a) =>
          a.username.trim().toLowerCase() == value ||
          a.email.trim().toLowerCase() == value,
    );
  }

  static UserAccount? login({
    required String identifier,
    required String password,
  }) {
    // Akun pending tidak dicari di sini, sehingga tidak bisa login.
    final account = findByUsername(identifier);
    if (account == null || account.password != password) {
      return null;
    }
    return account;
  }

  // ----------------------------------------------------------
  // DAFTAR
  // ----------------------------------------------------------

  static String? register({
    required String username,
    required String password,
    required String role,
    required String email,
    required String name,
  }) {
    final cleanUsername = username.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();

    // Pendaftaran tidak boleh langsung menjadi Admin Utama.
    final cleanRole = AppRoles.normalize(role) == AppRoles.user
        ? AppRoles.user
        : AppRoles.admin;

    if (cleanUsername.isEmpty ||
        password.isEmpty ||
        cleanEmail.isEmpty ||
        cleanName.isEmpty) {
      return 'Semua data wajib diisi.';
    }
    if (cleanUsername.length < 4) {
      return 'Username minimal 4 karakter.';
    }

    final usernameKey = cleanUsername.toLowerCase();
    final emailKey = cleanEmail.toLowerCase();

    final usernameExists = _accounts.any(
          (a) => a.username.trim().toLowerCase() == usernameKey,
        ) ||
        _pendingAccounts.any(
          (a) => a.username.trim().toLowerCase() == usernameKey,
        );
    if (usernameExists) return 'Username sudah digunakan.';

    // Username yang pernah ditolak Admin Utama tidak boleh dipakai lagi.
    final wasRejected = _history.any(
      (r) =>
          !r.isApproved &&
          r.username.trim().toLowerCase() == usernameKey,
    );
    if (wasRejected) {
      return 'Username "$cleanUsername" pernah ditolak dan tidak bisa '
          'dipakai lagi. Gunakan username lain, misalnya '
          '"${_suggestUsername(cleanUsername)}".';
    }

    final emailExists = _accounts.any(
          (a) => a.email.trim().toLowerCase() == emailKey,
        ) ||
        _pendingAccounts.any(
          (a) => a.email.trim().toLowerCase() == emailKey,
        );
    if (emailExists) return 'Email sudah terdaftar.';

    _pendingAccounts.add(
      UserAccount(
        username: cleanUsername,
        password: password,
        role: cleanRole,
        email: cleanEmail,
        name: cleanName,
      ),
    );
    _save();
    return null;
  }

  // Saran username lain: grece -> grece1, grece2, ...
  static String _suggestUsername(String base) {
    bool taken(String name) {
      final key = name.toLowerCase();
      return _accounts.any((a) => a.username.toLowerCase() == key) ||
          _pendingAccounts.any((a) => a.username.toLowerCase() == key) ||
          _history.any(
            (r) => !r.isApproved && r.username.toLowerCase() == key,
          );
    }

    var n = 1;
    while (taken('$base$n')) {
      n++;
    }
    return '$base$n';
  }

  // ----------------------------------------------------------
  // PERSETUJUAN (hanya Admin Utama)
  // ----------------------------------------------------------

  static bool _decide(
    String username,
    UserAccount approver,
    String action,
  ) {
    // Dicek lagi di sini, bukan hanya di tampilan.
    if (!approver.isSuperAdmin) return false;

    final key = username.trim().toLowerCase();
    final index = _pendingAccounts.indexWhere(
      (a) => a.username.trim().toLowerCase() == key,
    );
    if (index < 0) return false;

    final account = _pendingAccounts.removeAt(index);

    if (action == ApprovalRecord.approved) {
      _accounts.add(account);
    }

    _history.insert(
      0,
      ApprovalRecord(
        username: account.username,
        name: account.name,
        email: account.email,
        role: account.role,
        action: action,
        decidedBy: approver.username,
        decidedByName: approver.name,
        decidedAt: DateTime.now(),
      ),
    );

    _save();
    return true;
  }

  static bool approveAccount(String username, {required UserAccount by}) =>
      _decide(username, by, ApprovalRecord.approved);

  static bool rejectAccount(String username, {required UserAccount by}) =>
      _decide(username, by, ApprovalRecord.rejected);
}

// ============================================================
// DATE TEXT
// ============================================================

class DateText {
  static DateTime? parse(String? value) {
    if (value == null) {
      return null;
    }

    final clean = value.trim();

    if (clean.isEmpty) {
      return null;
    }

    return DateTime.tryParse(clean);
  }

  static String iso(DateTime date) {
    final local = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return local.toIso8601String();
  }

  static String format(Object? value) {
    DateTime? date;

    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = parse(value);
    }

    if (date == null) {
      return '-';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

// ============================================================
// ITEM MODEL
// ============================================================

class ItemModel {
  final String id;
  final String kode;
  final String nama;
  final String kategori;
  final String status;
  final String jenisData;
  final String deskripsi;
  final String lokasi;
  final String pic;
  final String deadline;
  final DateTime tanggalDibuat;
  final String createdBy;

  const ItemModel({
    required this.id,
    required this.kode,
    required this.nama,
    required this.kategori,
    required this.status,
    required this.jenisData,
    required this.deskripsi,
    required this.lokasi,
    required this.pic,
    required this.deadline,
    required this.tanggalDibuat,
    required this.createdBy,
  });

  factory ItemModel.create({
    String? id,
    String? kode,
    String? nama,
    String? title,
    required String kategori,
    String? status,
    required String jenisData,
    String deskripsi = '',
    String lokasi = '',
    String pic = '',
    String deadline = '',
    DateTime? tanggalDibuat,
    DateTime? createdAt,
    String createdBy = '',
  }) {
    final finalNama =
        (nama ?? title ?? '').trim();

    final finalId =
        id ??
        DateTime.now()
            .microsecondsSinceEpoch
            .toString();

    final finalKode =
        kode ??
        ItemStore.nextCode(jenisData);

    final finalStatus = AppOptions.normalizeStatus(
      status ??
          (jenisData == AppOptions.task
              ? AppOptions.statusPending
              : AppOptions.statusDipinjam),
    );

    return ItemModel(
      id: finalId,
      kode: finalKode,
      nama: finalNama,
      kategori: kategori,
      status: finalStatus,
      jenisData: jenisData,
      deskripsi: deskripsi.trim(),
      lokasi: lokasi.trim(),
      pic: pic.trim(),
      deadline: deadline.trim(),
      tanggalDibuat:
          tanggalDibuat ??
          createdAt ??
          DateTime.now(),
      createdBy: createdBy.trim(),
    );
  }

  factory ItemModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final created =
        DateTime.tryParse(
              '${map['tanggalDibuat'] ?? map['createdAt'] ?? ''}',
            ) ??
            DateTime.now();

    return ItemModel(
      id: '${map['id'] ?? ''}',
      kode: '${map['kode'] ?? ''}',
      nama:
          '${map['nama'] ?? map['title'] ?? ''}',
      kategori:
          '${map['kategori'] ?? map['category'] ?? ''}',
      status: AppOptions.normalizeStatus(
        '${map['status'] ?? AppOptions.statusDipinjam}',
      ),
      jenisData:
          '${map['jenisData'] ?? AppOptions.inventory}',
      deskripsi:
          '${map['deskripsi'] ?? map['description'] ?? ''}',
      lokasi:
          '${map['lokasi'] ?? map['location'] ?? ''}',
      pic: '${map['pic'] ?? ''}',
      deadline:
          '${map['deadline'] ?? ''}',
      tanggalDibuat: created,
      createdBy:
          '${map['createdBy'] ?? ''}',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode': kode,
      'nama': nama,
      'kategori': kategori,
      'status': status,
      'jenisData': jenisData,
      'deskripsi': deskripsi,
      'lokasi': lokasi,
      'pic': pic,
      'deadline': deadline,
      'tanggalDibuat':
          tanggalDibuat.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  // ==========================================================
  // ALIASES
  // ==========================================================

  String get title => nama;

  String get category => kategori;

  String get description => deskripsi;

  String get location => lokasi;

  DateTime get createdAt => tanggalDibuat;

  bool get isInventory {
    return jenisData == AppOptions.inventory;
  }

  bool get isTask {
    return jenisData == AppOptions.task;
  }

  bool get isPending {
    final value =
        status.toLowerCase().trim();

    return value == 'pending' ||
        value == 'panding';
  }

  bool get isInProgress {
    return status.toLowerCase().trim() ==
        'proses';
  }

  bool get isDone {
    return status.toLowerCase().trim() ==
        'selesai';
  }

  DateTime? get deadlineDate {
    return DateText.parse(deadline);
  }

  bool get isOverdue {
    final date = deadlineDate;

    if (date == null || isDone) {
      return false;
    }

    final today = DateTime.now();

    final currentDay = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final deadlineDay = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return deadlineDay.isBefore(currentDay);
  }

  String get deadlineLabel {
    if (deadline.trim().isEmpty) {
      return '-';
    }

    final date = deadlineDate;

    if (date == null) {
      return deadline;
    }

    return DateText.format(date);
  }

  String get formattedDate {
    return DateText.format(tanggalDibuat);
  }

  IconData get iconKategori {
    switch (kategori.toLowerCase()) {
      case 'laptop asus':
        return Icons.laptop_mac_rounded;

      case 'buku pemrograman':
        return Icons.menu_book_rounded;

      case 'komputer':
        return Icons.computer_rounded;

      case 'task':
      case 'tugas':
        return Icons.task_alt_rounded;

      case 'project flutter':
        return Icons.flutter_dash_rounded;

      default:
        return isTask
            ? Icons.assignment_rounded
            : Icons.inventory_2_rounded;
    }
  }

  Color get categoryColor {
    if (isTask) {
      return const Color(0xFF0F9D85);
    }

    return const Color(0xFF2563EB);
  }

  Color get statusColor {
    return AppOptions.statusColor(status);
  }

  Color get statusBackground {
    return statusColor.withAlpha(22);
  }

  IconData get statusIcon {
    return AppOptions.statusIcon(status);
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  ItemModel copyWith({
    String? id,
    String? kode,
    String? nama,
    String? title,
    String? kategori,
    String? category,
    String? status,
    String? jenisData,
    String? deskripsi,
    String? description,
    String? lokasi,
    String? location,
    String? pic,
    String? deadline,
    DateTime? tanggalDibuat,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return ItemModel(
      id: id ?? this.id,
      kode: kode ?? this.kode,
      nama:
          nama ??
          title ??
          this.nama,
      kategori:
          kategori ??
          category ??
          this.kategori,
      status: AppOptions.normalizeStatus(
        status ?? this.status,
      ),
      jenisData:
          jenisData ??
          this.jenisData,
      deskripsi:
          deskripsi ??
          description ??
          this.deskripsi,
      lokasi:
          lokasi ??
          location ??
          this.lokasi,
      pic: pic ?? this.pic,
      deadline:
          deadline ??
          this.deadline,
      tanggalDibuat:
          tanggalDibuat ??
          createdAt ??
          this.tanggalDibuat,
      createdBy:
          createdBy ??
          this.createdBy,
    );
  }

  // ==========================================================
  // VALIDATION
  // ==========================================================

  static String? validate({
    required String nama,
    required String kategori,
    required String status,
    required String jenisData,
    String deadline = '',
  }) {
    if (nama.trim().isEmpty) {
      return 'Nama data wajib diisi.';
    }

    if (nama.trim().length < 2) {
      return 'Nama data terlalu pendek.';
    }

    if (!AppOptions.dataTypes.contains(
      jenisData,
    )) {
      return 'Jenis data tidak valid.';
    }

    if (!AppOptions.categoriesFor(
      jenisData,
    ).contains(kategori)) {
      return 'Kategori tidak valid.';
    }

    if (!AppOptions.statusesFor(
      jenisData,
    ).contains(status)) {
      return 'Status tidak valid.';
    }

    if (jenisData == AppOptions.task &&
        deadline.trim().isNotEmpty) {
      if (DateText.parse(deadline) == null) {
        return 'Format deadline tidak valid.';
      }
    }

    return null;
  }
}

// ============================================================
// PENGUMPULAN TUGAS (per user)
// ============================================================
//
// Tugas buatan Admin otomatis muncul di semua akun User.
// Tiap user punya catatan pengumpulan sendiri:
//   - belum ada catatan  -> belum dikumpulkan
//   - ada catatan        -> sudah dikumpulkan (status awal Pending)
// Status hanya bisa diubah Admin setelah user mengumpulkan.

class TaskSubmission {
  final String taskId;
  final String username;
  final DateTime submittedAt;
  final String status; // Pending / Proses / Selesai (diatur Admin)
  final String title; // tugas apa yang dikumpulkan
  final String note; // keterangan dari user
  final String link; // link hasil (opsional)

  const TaskSubmission({
    required this.taskId,
    required this.username,
    required this.submittedAt,
    required this.status,
    this.title = '',
    this.note = '',
    this.link = '',
  });

  bool get isDone => status == AppOptions.statusSelesai;

  TaskSubmission copyWith({String? status}) {
    return TaskSubmission(
      taskId: taskId,
      username: username,
      submittedAt: submittedAt,
      status: status ?? this.status,
      title: title,
      note: note,
      link: link,
    );
  }

  factory TaskSubmission.fromMap(Map<String, dynamic> map) {
    return TaskSubmission(
      taskId: '${map['taskId'] ?? ''}',
      username: '${map['username'] ?? ''}',
      submittedAt: DateTime.tryParse('${map['submittedAt'] ?? ''}') ??
          DateTime.now(),
      status: AppOptions.normalizeStatus(
        '${map['status'] ?? AppOptions.statusPending}',
      ),
      title: '${map['title'] ?? ''}',
      note: '${map['note'] ?? ''}',
      link: '${map['link'] ?? ''}',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'username': username,
      'submittedAt': submittedAt.toIso8601String(),
      'status': status,
      'title': title,
      'note': note,
      'link': link,
    };
  }
}

// ============================================================
// NOTIFIKASI ADMIN
// ============================================================

class AppNotice {
  final String id;
  final String title;
  final String message;
  final String taskId;
  final String username;
  final DateTime createdAt;
  final bool read;

  const AppNotice({
    required this.id,
    required this.title,
    required this.message,
    required this.taskId,
    required this.username,
    required this.createdAt,
    this.read = false,
  });

  AppNotice copyWith({bool? read}) {
    return AppNotice(
      id: id,
      title: title,
      message: message,
      taskId: taskId,
      username: username,
      createdAt: createdAt,
      read: read ?? this.read,
    );
  }

  factory AppNotice.fromMap(Map<String, dynamic> map) {
    return AppNotice(
      id: '${map['id'] ?? ''}',
      title: '${map['title'] ?? ''}',
      message: '${map['message'] ?? ''}',
      taskId: '${map['taskId'] ?? ''}',
      username: '${map['username'] ?? ''}',
      createdAt:
          DateTime.tryParse('${map['createdAt'] ?? ''}') ?? DateTime.now(),
      read: map['read'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'taskId': taskId,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
      'read': read,
    };
  }
}

// ============================================================
// ITEM SORT
// ============================================================

enum ItemSort {
  terbaru,
  terlama,
  deadline,
  nama,
}

extension ItemSortLabel on ItemSort {
  String get label {
    switch (this) {
      case ItemSort.terbaru:
        return 'Terbaru';

      case ItemSort.terlama:
        return 'Terlama';

      case ItemSort.deadline:
        return 'Deadline';

      case ItemSort.nama:
        return 'Nama';
    }
  }
}

// ============================================================
// ITEM STATS
// ============================================================

class ItemStats {
  final int total;
  final int inventory;
  final int tasks;
  final int available;
  final int borrowed;
  final int pending;
  final int inProgress;
  final int done;
  final int overdue;

  const ItemStats({
    required this.total,
    required this.inventory,
    required this.tasks,
    required this.available,
    required this.borrowed,
    required this.pending,
    required this.inProgress,
    required this.done,
    required this.overdue,
  });

  double get taskProgress {
    if (tasks == 0) {
      return 0;
    }

    return done / tasks;
  }
}

// ============================================================
// ITEM STORE
// ============================================================

class ItemStore {
  static final List<ItemModel> _items = [
    ItemModel(
      id: '1',
      kode: 'INV-001',
      nama: 'ASUS VivoBook 14',
      kategori: 'Laptop ASUS',
      status: AppOptions.statusDipinjam,
      jenisData: AppOptions.inventory,
      deskripsi:
          'Laptop untuk kebutuhan pembelajaran PPLG.',
      lokasi: 'Lab PPLG',
      pic: 'SMKN 1 Beringin',
      deadline: '',
      tanggalDibuat:
          DateTime(2026, 9, 20),
      createdBy: 'admin1',
    ),
    ItemModel(
      id: '2',
      kode: 'INV-002',
      nama: 'ASUS TUF Gaming F15',
      kategori: 'Laptop ASUS',
      status: AppOptions.statusDipinjam,
      jenisData: AppOptions.inventory,
      deskripsi:
          'Laptop untuk kegiatan praktik dan project.',
      lokasi: 'Lab PPLG',
      pic: 'SMKN 1 Beringin',
      deadline: '',
      tanggalDibuat:
          DateTime(2026, 9, 21),
      createdBy: 'admin1',
    ),
    ItemModel(
      id: '3',
      kode: 'INV-003',
      nama: 'Buku Pemrograman Python',
      kategori: 'Buku Pemrograman',
      status: AppOptions.statusDipinjam,
      jenisData: AppOptions.inventory,
      deskripsi:
          'Buku pembelajaran dasar Python.',
      lokasi: 'Perpustakaan',
      pic: 'SMKN 1 Beringin',
      deadline: '',
      tanggalDibuat:
          DateTime(2026, 9, 22),
      createdBy: 'admin1',
    ),
    ItemModel(
      id: '4',
      kode: 'INV-004',
      nama: 'Komputer Laboratorium',
      kategori: 'Komputer',
      status: AppOptions.statusDipinjam,
      jenisData: AppOptions.inventory,
      deskripsi:
          'Komputer untuk praktik siswa.',
      lokasi: 'Lab Komputer',
      pic: 'SMKN 1 Beringin',
      deadline: '',
      tanggalDibuat:
          DateTime(2026, 9, 23),
      createdBy: 'admin1',
    ),
    ItemModel(
      id: '5',
      kode: 'TSK-001',
      nama: 'Project Inventory Flutter',
      kategori: 'Project Flutter',
      status: AppOptions.statusPending,
      jenisData: AppOptions.task,
      deskripsi:
          'Menyelesaikan aplikasi Task & Inventory.',
      lokasi: '',
      pic: 'Administrator',
      deadline: '2026-10-10T00:00:00.000',
      tanggalDibuat:
          DateTime(2026, 9, 25),
      createdBy: 'admin1',
    ),
    ItemModel(
      id: '6',
      kode: 'TSK-002',
      nama: 'Tugas UI Login Screen',
      kategori: 'Tugas',
      status: AppOptions.statusPending,
      jenisData: AppOptions.task,
      deskripsi:
          'Membuat tampilan login aplikasi.',
      lokasi: '',
      pic: 'Administrator',
      deadline: '2026-10-08T00:00:00.000',
      tanggalDibuat:
          DateTime(2026, 9, 26),
      createdBy: 'admin1',
    ),
  ];

  static const String _kItems = 'items_v1';
  static const String _kSubmissions = 'submissions_v1';
  static const String _kNotices = 'notices_v1';

  // Catatan pengumpulan tugas (per user, per tugas).
  static final List<TaskSubmission> _submissions = [];

  // Notifikasi untuk Admin (terbaru di paling atas).
  static final List<AppNotice> _notices = [];

  static List<Map<String, dynamic>>? _decodeMaps(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! List) return null;
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static void load() {
    final items = _decodeMaps(AppStorage.read(_kItems));
    if (items != null) {
      _items
        ..clear()
        ..addAll(items.map(ItemModel.fromMap));
    }

    // Tugas tidak punya status "Di Pinjam" -> jadikan Pending.
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.isTask && item.status == AppOptions.statusDipinjam) {
        _items[i] = item.copyWith(status: AppOptions.statusPending);
      }
    }

    final subs = _decodeMaps(AppStorage.read(_kSubmissions));
    if (subs != null) {
      _submissions
        ..clear()
        ..addAll(subs.map(TaskSubmission.fromMap));
    }

    final notices = _decodeMaps(AppStorage.read(_kNotices));
    if (notices != null) {
      _notices
        ..clear()
        ..addAll(notices.map(AppNotice.fromMap));
    }

    _removeOrphans();
  }

  // Pengumpulan / notifikasi milik tugas yang sudah tidak ada ikut dibuang.
  static void _removeOrphans() {
    final ids = _items.map((e) => e.id).toSet();
    _submissions.removeWhere((s) => !ids.contains(s.taskId));
    _notices.removeWhere(
      (n) => n.taskId.isNotEmpty && !ids.contains(n.taskId),
    );
  }

  static void saveNow() => _save();

  static void _save() {
    AppStorage.write(
      _kItems,
      jsonEncode(_items.map((e) => e.toMap()).toList()),
    );
    AppStorage.write(
      _kSubmissions,
      jsonEncode(_submissions.map((e) => e.toMap()).toList()),
    );
    AppStorage.write(
      _kNotices,
      jsonEncode(_notices.map((e) => e.toMap()).toList()),
    );
  }

  static List<ItemModel> get all {
    return List.unmodifiable(_items);
  }

  // User biasa selalu menghasilkan data berstatus Pending
  // dan Admin langsung mendapat notifikasi.
  // Tugas buatan Admin berstatus Pending di sisi master;
  // status sebenarnya dinilai per user lewat pengumpulan.
  static void add(ItemModel item, {UserAccount? by}) {
    final user = by;
    final isUserAction = user != null && !user.canChangeStatus;

    final toSave = (isUserAction || (user != null && item.isTask))
        ? item.copyWith(status: AppOptions.statusPending)
        : item;

    _items.add(toSave);

    if (user != null && isUserAction && toSave.isTask) {
      _addNotice(
        title: 'Tugas baru dikumpulkan',
        message: '${user.name} mengumpulkan tugas "${toSave.nama}".',
        taskId: toSave.id,
        username: user.username,
      );
    }

    _save();
  }

  static void update(ItemModel item, {UserAccount? by}) {
    final index = _items.indexWhere(
      (element) => element.id == item.id,
    );

    if (index == -1) {
      return;
    }

    // User biasa tidak boleh mengubah status lewat edit.
    if (by != null && !by.canChangeStatus) {
      item = item.copyWith(status: _items[index].status);
    }

    _items[index] = item;
    _save();
  }

  static bool remove(String id, {UserAccount? by}) {
    if (by != null && !by.canDelete) {
      return false;
    }

    _items.removeWhere(
      (item) => item.id == id,
    );

    // Hapus juga pengumpulan & notifikasi milik tugas ini,
    // sehingga tugas ikut hilang dari semua akun user.
    _submissions.removeWhere((s) => s.taskId == id);
    _notices.removeWhere((n) => n.taskId == id);

    _save();
    return true;
  }

  // Mengembalikan false jika pengguna tidak berhak mengubah status.
  static bool changeStatus(
    String id,
    String status, {
    required UserAccount by,
  }) {
    if (!by.canChangeStatus) {
      return false;
    }

    final index = _items.indexWhere(
      (item) => item.id == id,
    );

    if (index == -1) {
      return false;
    }

    _items[index] =
        _items[index].copyWith(
      status:
          AppOptions.normalizeStatus(
        status,
      ),
    );
    _save();
    return true;
  }

  // ----------------------------------------------------------
  // TUGAS ADMIN -> OTOMATIS TAMPIL DI SEMUA USER
  // ----------------------------------------------------------

  // Tugas yang dibuat Admin = tugas untuk semua user.
  static bool isAssigned(ItemModel item) {
    if (!item.isTask) return false;
    final creator = AuthService.findByUsername(item.createdBy);
    return creator != null && creator.isAdmin;
  }

  // Semua akun User yang sudah disetujui.
  static List<UserAccount> get assignees {
    return AuthService.approvedAccounts.where((a) => a.isUser).toList();
  }

  // Tugas milik sendiri + semua tugas dari Admin.
  // Dihitung saat dibuka, jadi akun baru langsung ikut mendapat
  // tugas yang sudah dibuat Admin sebelumnya.
  static List<ItemModel> tasksVisibleTo(String username) {
    final key = username.trim().toLowerCase();
    return _items
        .where(
          (item) =>
              item.isTask &&
              (item.createdBy.trim().toLowerCase() == key ||
                  isAssigned(item)),
        )
        .toList();
  }

  static TaskSubmission? submissionOf(String taskId, String username) {
    final key = username.trim().toLowerCase();
    for (final s in _submissions) {
      if (s.taskId == taskId && s.username.trim().toLowerCase() == key) {
        return s;
      }
    }
    return null;
  }

  // Sudah dikumpulkan? Tugas buatan sendiri dianggap sudah dikumpulkan.
  static bool isSubmitted(ItemModel item, String username) {
    if (!isAssigned(item)) return true;
    return submissionOf(item.id, username) != null;
  }

  // Jumlah user yang sudah mengumpulkan tugas ini.
  static int submittedCount(String taskId) {
    return assignees
        .where((a) => submissionOf(taskId, a.username) != null)
        .length;
  }

  // Jumlah user yang tugasnya sudah dinyatakan Selesai oleh Admin.
  static int doneCount(String taskId) {
    return assignees.where((a) {
      final sub = submissionOf(taskId, a.username);
      return sub != null && sub.isDone;
    }).length;
  }

  // Salinan tugas dengan status seperti yang boleh dilihat user:
  // hanya Pending atau Selesai.
  static ItemModel viewFor(ItemModel item, String username) {
    var raw = item.status;

    if (isAssigned(item)) {
      raw = submissionOf(item.id, username)?.status ??
          AppOptions.statusPending;
    }

    final visible = AppOptions.userVisibleStatus(raw);
    return visible == item.status ? item : item.copyWith(status: visible);
  }

  static List<ItemModel> tasksOf(
    String username,
  ) {
    return tasksVisibleTo(username)
        .map((item) => viewFor(item, username))
        .toList();
  }

  // User mengumpulkan tugas dari Admin.
  // Status awal Pending, lalu Admin mendapat notifikasi.
  static bool submitTask(
    String taskId, {
    required UserAccount by,
    String title = '',
    String note = '',
    String link = '',
  }) {
    if (by.isAdmin) return false;

    final index = _items.indexWhere((item) => item.id == taskId);
    if (index == -1) return false;

    final item = _items[index];
    if (!isAssigned(item)) return false;
    if (submissionOf(taskId, by.username) != null) return false;

    _submissions.add(
      TaskSubmission(
        taskId: taskId,
        username: by.username,
        submittedAt: DateTime.now(),
        status: AppOptions.statusPending,
        title: title.trim(),
        note: note.trim(),
        link: link.trim(),
      ),
    );

    _addNotice(
      title: 'Tugas baru dikumpulkan',
      message: title.trim().isEmpty
          ? '${by.name} mengumpulkan tugas "${item.nama}".'
          : '${by.name} mengumpulkan "${title.trim()}" '
              'untuk tugas "${item.nama}".',
      taskId: taskId,
      username: by.username,
    );

    _save();
    return true;
  }

  // Admin menilai tugas milik satu user.
  // Hanya bisa setelah user mengumpulkan.
  static bool setSubmissionStatus(
    String taskId,
    String username,
    String status, {
    required UserAccount by,
  }) {
    if (!by.canChangeStatus) return false;

    final clean = AppOptions.normalizeStatus(status);
    if (!AppOptions.taskStatuses.contains(clean)) return false;

    final key = username.trim().toLowerCase();
    final index = _submissions.indexWhere(
      (s) => s.taskId == taskId && s.username.trim().toLowerCase() == key,
    );
    if (index == -1) return false;

    _submissions[index] = _submissions[index].copyWith(status: clean);
    _save();
    return true;
  }

  // ----------------------------------------------------------
  // NOTIFIKASI ADMIN
  // ----------------------------------------------------------

  static List<AppNotice> get notices =>
      List<AppNotice>.unmodifiable(_notices);

  static int get unreadNoticeCount =>
      _notices.where((n) => !n.read).length;

  static void _addNotice({
    required String title,
    required String message,
    required String taskId,
    required String username,
  }) {
    _notices.insert(
      0,
      AppNotice(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        message: message,
        taskId: taskId,
        username: username,
        createdAt: DateTime.now(),
      ),
    );

    if (_notices.length > 100) {
      _notices.removeRange(100, _notices.length);
    }
  }

  static void markNoticeRead(String id) {
    final index = _notices.indexWhere((n) => n.id == id);
    if (index == -1 || _notices[index].read) return;
    _notices[index] = _notices[index].copyWith(read: true);
    _save();
  }

  static void markAllNoticesRead() {
    for (var i = 0; i < _notices.length; i++) {
      if (!_notices[i].read) {
        _notices[i] = _notices[i].copyWith(read: true);
      }
    }
    _save();
  }

  static void clearNotices() {
    _notices.clear();
    _save();
  }

  // Tugas Admin dianggap terlambat bila ada user yang belum Selesai.
  static bool _overdueForAdmin(ItemModel item) {
    if (!isAssigned(item)) return item.isOverdue;

    final date = item.deadlineDate;
    if (date == null) return false;

    final today = DateTime.now();
    final currentDay = DateTime(today.year, today.month, today.day);
    final deadlineDay = DateTime(date.year, date.month, date.day);

    if (!deadlineDay.isBefore(currentDay)) return false;

    final users = assignees;
    if (users.isEmpty) return false;

    return users.any((u) {
      final sub = submissionOf(item.id, u.username);
      return sub == null || !sub.isDone;
    });
  }

  // Filter status untuk Admin: tugas Admin cocok bila ada
  // pengumpulan user dengan status tersebut.
  static bool _matchesStatus(
    ItemModel item,
    String status, {
    required bool includeSubmissions,
  }) {
    if (item.status == status) return true;

    if (includeSubmissions && isAssigned(item)) {
      return _submissions.any(
        (s) => s.taskId == item.id && s.status == status,
      );
    }

    return false;
  }

  static List<ItemModel> query({
    String search = '',
    String? jenisData,
    String? status,
    String? createdBy,
    String? visibleTo, // tugas milik user ini + tugas dari Admin
    ItemSort sort = ItemSort.terbaru,
  }) {
    final keyword =
        search.trim().toLowerCase();

    Iterable<ItemModel> result =
        (visibleTo != null && visibleTo.trim().isNotEmpty)
            ? tasksOf(visibleTo)
            : _items;

    if (jenisData != null &&
        jenisData.trim().isNotEmpty) {
      result = result.where(
        (item) =>
            item.jenisData == jenisData,
      );
    }

    if (status != null &&
        status.trim().isNotEmpty &&
        status != 'Semua') {
      result = result.where(
        (item) => _matchesStatus(
          item,
          status,
          includeSubmissions: visibleTo == null,
        ),
      );
    }

    if (createdBy != null &&
        createdBy.trim().isNotEmpty) {
      final owner =
          createdBy.trim().toLowerCase();

      result = result.where(
        (item) =>
            item.createdBy
                .trim()
                .toLowerCase() ==
            owner,
      );
    }

    if (keyword.isNotEmpty) {
      result = result.where(
        (item) {
          final text = [
            item.kode,
            item.nama,
            item.kategori,
            item.status,
            item.jenisData,
            item.deskripsi,
            item.lokasi,
            item.pic,
          ].join(' ').toLowerCase();

          return text.contains(keyword);
        },
      );
    }

    final list = result.toList();

    switch (sort) {
      case ItemSort.terbaru:
        list.sort(
          (a, b) =>
              b.tanggalDibuat
                  .compareTo(
                a.tanggalDibuat,
              ),
        );
        break;

      case ItemSort.terlama:
        list.sort(
          (a, b) =>
              a.tanggalDibuat
                  .compareTo(
                b.tanggalDibuat,
              ),
        );
        break;

      case ItemSort.deadline:
        list.sort(
          (a, b) {
            final ad = a.deadlineDate;
            final bd = b.deadlineDate;

            if (ad == null && bd == null) {
              return 0;
            }

            if (ad == null) {
              return 1;
            }

            if (bd == null) {
              return -1;
            }

            return ad.compareTo(bd);
          },
        );
        break;

      case ItemSort.nama:
        list.sort(
          (a, b) => a.nama
              .toLowerCase()
              .compareTo(
                b.nama.toLowerCase(),
              ),
        );
        break;
    }

    return list;
  }

  static ItemStats stats({
    List<ItemModel>? source,
  }) {
    final list = source ?? _items;

    int countStatus(String status) {
      return list
          .where(
            (item) =>
                item.status == status,
          )
          .length;
    }

    return ItemStats(
      total: list.length,
      inventory: list
          .where(
            (item) => item.isInventory,
          )
          .length,
      tasks: list
          .where(
            (item) => item.isTask,
          )
          .length,
      available:
          countStatus(
            AppOptions.statusDipinjam,
          ),
      borrowed:
          countStatus(
            AppOptions.statusDipinjam,
          ),
      pending:
          countStatus(
            AppOptions.statusPending,
          ),
      inProgress:
          countStatus(
            AppOptions.statusProses,
          ),
      done:
          countStatus(
            AppOptions.statusSelesai,
          ),
      overdue: list
          .where(
            (item) => _overdueForAdmin(item),
          )
          .length,
    );
  }

  static String nextCode(
    String jenisData,
  ) {
    final prefix =
        jenisData == AppOptions.task
            ? 'TSK'
            : 'INV';

    var maxNumber = 0;

    for (final item in _items) {
      if (!item.kode
          .toUpperCase()
          .startsWith('$prefix-')) {
        continue;
      }

      final parts =
          item.kode.split('-');

      if (parts.length != 2) {
        continue;
      }

      final number =
          int.tryParse(parts.last);

      if (number != null &&
          number > maxNumber) {
        maxNumber = number;
      }
    }

    return '$prefix-${(maxNumber + 1).toString().padLeft(3, '0')}';
  }
}
