import 'package:flutter/material.dart';

import '../models/item_model.dart';
import 'add_item_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  final UserAccount user;

  const UserDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState
    extends State<UserDashboardScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color navy = Color(0xFF172B4D);
  static const Color green = Color(0xFF0F9D85);
  static const Color blue = Color(0xFF2563EB);
  static const Color red = Color(0xFFDC2626);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE8EDF4);
  static const Color background = Color(0xFFF4F7FB);

  static const String allStatus = 'Semua';

  // ============================================================
  // CONTROLLER
  // ============================================================

  final TextEditingController _searchController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  String _search = '';
  String _filter = allStatus;
  ItemSort _sort = ItemSort.terbaru;

  // Untuk banner deadline.
  bool _deadlineFirst = false;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA TUGAS USER
  // ============================================================

  List<ItemModel> get _myTasks {
    return ItemStore.tasksOf(
      widget.user.username,
    );
  }

  List<ItemModel> get _filteredTasks {
    final result = ItemStore.query(
      search: _search,
      jenisData: AppOptions.task,
      visibleTo: widget.user.username,
      sort: _sort,
    );

    List<ItemModel> filtered;

    if (_filter == allStatus) {
      filtered = List<ItemModel>.from(result);
    } else {
      filtered = result.where((item) {
        return AppOptions.normalizeStatus(
              item.status,
            ) ==
            _filter;
      }).toList();
    }

    // Jika banner deadline ditekan,
    // tugas yang punya deadline paling dekat
    // ditampilkan lebih dahulu.
    if (_deadlineFirst) {
      filtered.sort((a, b) {
        final dateA = DateText.parse(a.deadline);
        final dateB = DateText.parse(b.deadline);

        if (dateA == null && dateB == null) {
          return 0;
        }

        if (dateA == null) {
          return 1;
        }

        if (dateB == null) {
          return -1;
        }

        return dateA.compareTo(dateB);
      });
    }

    return filtered;
  }

  // ============================================================
  // STATISTIK
  // ============================================================

  int get _totalTasks {
    return _myTasks.length;
  }

  int get _doneTasks {
    return _myTasks.where((item) {
      return AppOptions.normalizeStatus(
            item.status,
          ) ==
          AppOptions.statusSelesai;
    }).length;
  }

  int get _overdueTasks {
    return _myTasks.where((item) {
      return item.isOverdue;
    }).length;
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    return AppOptions.statusColor(status);
  }

  // ============================================================
  // STATUS ICON
  // ============================================================

  IconData _statusIcon(String status) {
    return AppOptions.statusIcon(status);
  }

  // ============================================================
  // SAPAAN
  // ============================================================

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 11) {
      return 'Selamat pagi';
    }

    if (hour < 15) {
      return 'Selamat siang';
    }

    if (hour < 18) {
      return 'Selamat sore';
    }

    return 'Selamat malam';
  }

  // ============================================================
  // FORMAT TANGGAL + JAM
  // ============================================================

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${DateText.format(date)} $hour:$minute';
  }

  // ============================================================
  // KUMPULKAN TUGAS (tugas dari Admin)
  // ============================================================

  Future<void> _submitTask(
    ItemModel item,
  ) async {
    final result =
        await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitTaskScreen(
          task: item,
          user: widget.user,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    var ok = false;

    setState(() {
      ok = ItemStore.submitTask(
        item.id,
        by: widget.user,
        title: result['title'] ?? '',
        note: result['note'] ?? '',
        link: result['link'] ?? '',
      );
    });

    _message(
      ok
          ? 'Tugas berhasil dikumpulkan. Admin sudah diberi tahu.'
          : 'Tugas tidak dapat dikumpulkan.',
      color: ok ? green : red,
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _message(
    String message, {
    Color color = green,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // TAMBAH TUGAS
  // ============================================================

  Future<void> _addTask() async {
    final result =
        await Navigator.push<ItemModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(
          user: widget.user,
          defaultType: AppOptions.task,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      ItemStore.add(result, by: widget.user);
    });

    _message(
      'Tugas berhasil dikumpulkan. Admin sudah diberi tahu.',
    );
  }

  // ============================================================
  // EDIT TUGAS
  // ============================================================

  Future<void> _editTask(
    ItemModel item,
  ) async {
    final result =
        await Navigator.push<ItemModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(
          user: widget.user,
          defaultType: AppOptions.task,
          existingItem: item,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      ItemStore.update(result, by: widget.user);
    });

    _message(
      'Tugas berhasil diperbarui.',
    );
  }

  // ============================================================
  // UBAH STATUS
  // ============================================================

  void _setStatus(
    ItemModel item,
    String status,
  ) {
    // User biasa tidak boleh mengubah status.
    if (!widget.user.canChangeStatus) {
      _message(
        'Status hanya dapat diubah oleh Admin.',
        color: red,
      );
      return;
    }

    final currentStatus =
        AppOptions.normalizeStatus(item.status);

    if (currentStatus == status) {
      return;
    }

    setState(() {
      ItemStore.changeStatus(
        item.id,
        status,
        by: widget.user,
      );
    });

    _message(
      'Status tugas berhasil diubah menjadi $status.',
    );
  }

  // ============================================================
  // PILIH STATUS
  // ============================================================

  Future<void> _pickStatus(
    ItemModel item,
  ) async {
    final currentStatus =
        AppOptions.normalizeStatus(item.status);

    final selected =
        await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            25,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFCBD5E1),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Ubah Status Tugas',
                  style: TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Pilih status terbaru untuk tugas ini.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 15),

                ...AppOptions.taskStatuses.map(
                  (status) {
                    final color =
                        _statusColor(status);

                    final selected =
                        currentStatus == status;

                    return Container(
                      margin:
                          const EdgeInsets.only(
                        bottom: 8,
                      ),
                      decoration:
                          BoxDecoration(
                        color: selected
                            ? color.withAlpha(20)
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                        border: Border.all(
                          color: selected
                              ? color
                              : border,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          alignment:
                              Alignment.center,
                          decoration:
                              BoxDecoration(
                            color:
                                color.withAlpha(20),
                            borderRadius:
                                BorderRadius.circular(
                              11,
                            ),
                          ),
                          child: Icon(
                            _statusIcon(status),
                            color: color,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          status,
                          style: TextStyle(
                            color: selected
                                ? color
                                : navy,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        trailing: selected
                            ? Icon(
                                Icons
                                    .check_circle_rounded,
                                color: color,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(
                            sheetContext,
                            status,
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      _setStatus(
        item,
        selected,
      );
    }
  }

  // ============================================================
  // HAPUS TUGAS
  // ============================================================

  Future<void> _deleteTask(
    ItemModel item,
  ) async {
    if (!widget.user.canDelete) {
      _message(
        'Hanya Admin yang dapat menghapus data.',
        color: red,
      );
      return;
    }

    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          title: const Text(
            'Hapus Tugas?',
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: Text(
            'Yakin ingin menghapus "${item.nama}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Batal',
              ),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor: red,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Hapus',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) {
      return;
    }

    setState(() {
      ItemStore.remove(item.id, by: widget.user);
    });

    _message(
      'Tugas berhasil dihapus.',
      color: navy,
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

 
Future<void> logout() async {
  final bool? confirm = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun User?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Ya, Logout'),
          ),
        ],
      );
    },
  );

  if (!mounted || confirm != true) return;

  Navigator.of(context).pushNamedAndRemoveUntil(
    '/login',
    (route) => false,
  );
}

  // ============================================================
  // RESET FILTER
  // ============================================================

  void _resetFilters() {
    _searchController.clear();

    setState(() {
      _search = '';
      _filter = allStatus;
      _sort = ItemSort.terbaru;
      _deadlineFirst = false;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final tasks = _myTasks;
    final filtered = _filteredTasks;

    final hasFilter =
        _search.trim().isNotEmpty ||
        _filter != allStatus ||
        _sort != ItemSort.terbaru ||
        _deadlineFirst;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 760,
            ),
            child: RefreshIndicator(
              color: green,
              onRefresh: () async {
                setState(() {});
                await Future.delayed(
                  const Duration(
                    milliseconds: 250,
                  ),
                );
              },
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  20,
                  18,
                  110,
                ),
                children: [
                  _header(),

                  const SizedBox(
                    height: 20,
                  ),

                  _welcomeCard(),

                  if (_overdueTasks > 0) ...[
                    const SizedBox(
                      height: 14,
                    ),
                    _overdueBanner(
                      _overdueTasks,
                    ),
                  ],

                  const SizedBox(
                    height: 20,
                  ),

                  _totalTasksCard(),

                  const SizedBox(
                    height: 27,
                  ),

                  const Text(
                    'Tugas Saya',
                    style: TextStyle(
                      color: navy,
                      fontSize: 19,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Tugas dari Admin dan tugas yang kamu buat.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _searchField(),
                      ),
                      const SizedBox(
                        width: 9,
                      ),
                      _sortButton(),
                    ],
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${filtered.length} tugas ditampilkan',
                          style:
                              const TextStyle(
                            color: muted,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                      if (hasFilter)
                        TextButton.icon(
                          onPressed:
                              _resetFilters,
                          icon: const Icon(
                            Icons
                                .filter_alt_off_rounded,
                            size: 17,
                          ),
                          label: const Text(
                            'Reset',
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  if (filtered.isEmpty)
                    _emptyState(
                      noTasks:
                          tasks.isEmpty,
                    )
                  else
                    ...filtered.map(
                      _taskCard,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ========================================================
      // FAB
      // ========================================================

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _addTask,
        backgroundColor: green,
        foregroundColor: Colors.white,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Tambah Tugas',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARD DECORATION
  // ============================================================

  BoxDecoration _cardDecoration([
    double radius = 17,
  ]) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(radius),
      border: Border.all(
        color: border,
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          padding:
              const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: border,
            ),
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(9),
            child: Image.asset(
              'assets/image/logo_smkn1_beringin.png',
cacheWidth: 300,
              fit: BoxFit.contain,
              errorBuilder:
                  (_, __, ___) {
                return const Icon(
                  Icons.school_rounded,
                  color: green,
                  size: 30,
                );
              },
            ),
          ),
        ),

        const SizedBox(width: 11),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'SMKN 1 BERINGIN',
                style: TextStyle(
                  color: navy,
                  fontWeight:
                      FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'TASK & INVENTORY MANAGER',
                style: TextStyle(
                  color: muted,
                  fontSize: 9,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),

        InkWell(
          borderRadius:
              BorderRadius.circular(14),
          onTap: _showProfile,
          child: Container(
            width: 46,
            height: 46,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xFF123F59),
                  green,
                ],
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Text(
              widget.user.initials,
              style:
                  const TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROFILE
  // ============================================================

  void _showProfile() {
    final user = widget.user;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF123F59), green],
                              ),
                              borderRadius: BorderRadius.circular(23),
                            ),
                            child: Text(
                              user.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'My Profil',
                            style: TextStyle(
                              color: navy,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _infoRow(Icons.person_outline_rounded, 'Nama', user.name),
                          _infoRow(Icons.person_pin_outlined, 'Username', user.username),
                          _infoRow(Icons.email_outlined, 'Email', user.email),
                          _infoRow(Icons.verified_user_outlined, 'Role', user.role),
                          _infoRow(Icons.task_alt_rounded, 'Total tugas', '${_myTasks.length}'),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                         Navigator.pop(sheetContext);
                         logout();
                          },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: red,
                        side: BorderSide(color: red.withAlpha(90)),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF7F9FC),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: green,
          ),

          const SizedBox(
            width: 10,
          ),

          Text(
            label,
            style:
                const TextStyle(
              color: muted,
              fontSize: 12,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Text(
              value.isEmpty
                  ? '-'
                  : value,
              textAlign:
                  TextAlign.right,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color: navy,
                fontWeight:
                    FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _welcomeCard() {
    final remaining =
        _totalTasks - _doneTasks;

    String message;

    if (_totalTasks == 0) {
      message =
          'Belum ada tugas. Yuk buat tugas pertamamu!';
    } else if (remaining <= 0) {
      message =
          'Hebat! Semua tugasmu sudah selesai.';
    } else {
      message =
          'Kamu punya $remaining tugas yang belum selesai.';

      final unsubmitted = _myTasks.where((item) {
        return !ItemStore.isSubmitted(
          item,
          widget.user.username,
        );
      }).length;

      if (unsubmitted > 0) {
        message += ' $unsubmitted di antaranya belum dikumpulkan.';
      }
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(21),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF123F59),
            green,
          ],
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
                green.withAlpha(50),
            blurRadius: 20,
            offset:
                const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  DateText.format(
                    DateTime.now(),
                  ).toUpperCase(),
                  style:
                      const TextStyle(
                    color:
                        Color(0xFFC8FFF0),
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  '$_greeting, ${widget.user.username}! 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                Text(
                  message,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          const Icon(
            Icons
                .assignment_turned_in_rounded,
            size: 45,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DEADLINE BANNER
  // ============================================================

  Widget _overdueBanner(
    int count,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(16),
      onTap: () {
        setState(() {
          _filter = allStatus;
          _deadlineFirst = true;
        });
      },
      child: Container(
        padding:
            const EdgeInsets.all(14),
        decoration:
            BoxDecoration(
          color:
              red.withAlpha(16),
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color:
                red.withAlpha(60),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons
                  .warning_amber_rounded,
              color: red,
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Text(
                '$count tugas melewati deadline. '
                'Ketuk untuk melihat deadline terdekat.',
                style:
                    const TextStyle(
                  color: red,
                  fontWeight:
                      FontWeight.w700,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOTAL TUGAS
  //
  // Angkanya = jumlah tugas milik user ini (sama dengan daftar
  // "Tugas Saya" saat filter / pencarian kosong).
  // ============================================================

  Widget _totalTasksCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  blue,
                  blue.withAlpha(185),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_totalTasks',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                const Text(
                  'Total Tugas',
                  style: TextStyle(
                    color: muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _searchField() {
    return TextField(
      controller:
          _searchController,
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
      textInputAction:
          TextInputAction.search,
      decoration:
          InputDecoration(
        hintText:
            'Cari tugas atau project...',
        hintStyle:
            const TextStyle(
          fontSize: 13,
        ),
        prefixIcon:
            const Icon(
          Icons.search_rounded,
        ),
        suffixIcon:
            _search.isEmpty
                ? null
                : IconButton(
                    tooltip:
                        'Hapus pencarian',
                    icon:
                        const Icon(
                      Icons
                          .close_rounded,
                    ),
                    onPressed: () {
                      _searchController
                          .clear();

                      setState(() {
                        _search = '';
                      });
                    },
                  ),
        filled: true,
        fillColor:
            Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(
          vertical: 14,
        ),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              const BorderSide(
            color: border,
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              const BorderSide(
            color: border,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              const BorderSide(
            color: green,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SORT
  // ============================================================

  Widget _sortButton() {
    return PopupMenuButton<ItemSort>(
      tooltip: 'Urutkan',
      initialValue: _sort,
      onSelected: (value) {
        setState(() {
          _sort = value;
          _deadlineFirst = false;
        });
      },
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),
      itemBuilder: (_) {
        return ItemSort.values.map(
          (sort) {
            return PopupMenuItem<ItemSort>(
              value: sort,
              child: Row(
                children: [
                  Icon(
                    sort == _sort
                        ? Icons
                            .radio_button_checked_rounded
                        : Icons
                            .radio_button_off_rounded,
                    size: 18,
                    color: sort == _sort
                        ? green
                        : muted,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    sort.label,
                  ),
                ],
              ),
            );
          },
        ).toList();
      },
      child: Container(
        width: 50,
        height: 50,
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(14),
          border:
              Border.all(
            color: border,
          ),
        ),
        child:
            const Icon(
          Icons.sort_rounded,
          color: navy,
        ),
      ),
    );
  }

  // ============================================================
  // TASK CARD
  // ============================================================

  Widget _taskCard(
    ItemModel item,
  ) {
    final assigned = ItemStore.isAssigned(item);
    final submitted = ItemStore.isSubmitted(
      item,
      widget.user.username,
    );

    final displayStatus =
        AppOptions.normalizeStatus(
      item.status,
    );

    final statusColor =
        _statusColor(
      displayStatus,
    );

    final deadlineColor =
        item.isOverdue
            ? red
            : muted;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 11,
      ),
      decoration:
          _cardDecoration(),
      child: Material(
        color:
            Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(
            17,
          ),
          onTap: () =>
              _showDetail(item),
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              14,
              14,
              8,
              12,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFE6F5F1,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                      child: Icon(
                        item.iconKategori,
                        color: green,
                        size: 23,
                      ),
                    ),

                    const SizedBox(
                      width: 11,
                    ),

                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            item.nama,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                TextStyle(
                              color:
                                  navy,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize:
                                  13.5,
                              decoration:
                                  displayStatus ==
                                          AppOptions
                                              .statusSelesai
                                      ? TextDecoration
                                          .lineThrough
                                      : null,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            '${item.kode} • ${item.kategori}',
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  muted,
                              fontSize:
                                  10.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _taskMenu(item),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            statusColor
                                .withAlpha(
                          20,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                      child:
                          Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            _statusIcon(
                              displayStatus,
                            ),
                            size: 12,
                            color:
                                statusColor,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Text(
                            displayStatus,
                            style:
                                TextStyle(
                              color:
                                  statusColor,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize:
                                  10.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (assigned) ...[
                      const SizedBox(
                        width: 6,
                      ),
                      _submitChip(submitted),
                    ],

                    const SizedBox(
                      width: 9,
                    ),

                    Icon(
                      Icons
                          .calendar_month_outlined,
                      size: 13,
                      color:
                          deadlineColor,
                    ),

                    const SizedBox(
                      width: 4,
                    ),

                    Expanded(
                      child: Text(
                        item.deadlineLabel,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            TextStyle(
                          color:
                              deadlineColor,
                          fontSize:
                              10.5,
                          fontWeight:
                              item.isOverdue
                                  ? FontWeight
                                      .w700
                                  : FontWeight
                                      .w500,
                        ),
                      ),
                    ),
                  ],
                ),

                if (assigned && !submitted) ...[
                  const SizedBox(
                    height: 10,
                  ),
                  Align(
                    alignment:
                        Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () {
                        _submitTask(item);
                      },
                      icon: const Icon(
                        Icons.upload_rounded,
                        size: 17,
                      ),
                      label: const Text(
                        'Kumpulkan',
                      ),
                      style:
                          FilledButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor:
                            Colors.white,
                        minimumSize:
                            const Size(0, 38),
                        visualDensity:
                            VisualDensity.compact,
                        textStyle:
                            const TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CHIP PENGUMPULAN
  // ============================================================

  Widget _submitChip(bool submitted) {
    final color = submitted
        ? blue
        : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        submitted
            ? 'Dikumpulkan'
            : 'Belum dikumpulkan',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  // ============================================================
  // TASK MENU
  // ============================================================

  Widget _taskMenu(
    ItemModel item,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'Menu tugas',
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      onSelected:
          (value) {
        switch (value) {
          case 'detail':
            _showDetail(item);
            break;

          case 'status':
            _pickStatus(item);
            break;

          case 'edit':
            _editTask(item);
            break;

          case 'delete':
            _deleteTask(item);
            break;
        }
      },
      itemBuilder:
          (_) => [
        const PopupMenuItem(
          value: 'detail',
          child: _MenuRow(
            Icons.visibility_outlined,
            'Lihat Detail',
          ),
        ),
        if (widget.user.canChangeStatus)
          const PopupMenuItem(
            value: 'status',
            child: _MenuRow(
              Icons.swap_horiz_rounded,
              'Ubah Status',
            ),
          ),
        if (!ItemStore.isAssigned(item))
          const PopupMenuItem(
            value: 'edit',
            child: _MenuRow(
              Icons.edit_outlined,
              'Edit Tugas',
            ),
          ),
        if (widget.user.canDelete) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: _MenuRow(
              Icons.delete_outline_rounded,
              'Hapus Tugas',
              color: red,
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // DETAIL
  // ============================================================

  void _showDetail(
    ItemModel item,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder:
          (sheetContext) {
        final assigned = ItemStore.isAssigned(item);
        final submission = ItemStore.submissionOf(
          item.id,
          widget.user.username,
        );
        final submitted = ItemStore.isSubmitted(
          item,
          widget.user.username,
        );
        final done = AppOptions.normalizeStatus(
              item.status,
            ) ==
            AppOptions.statusSelesai;

        final displayStatus =
            AppOptions
                .normalizeStatus(
          item.status,
        );

        return Container(
          padding:
              const EdgeInsets.fromLTRB(
            22,
            18,
            22,
            25,
          ),
          decoration:
              const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(
                24,
              ),
            ),
          ),
          child: SafeArea(
            child:
                SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFCBD5E1,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFE6F5F1,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),
                        child: Icon(
                          item.iconKategori,
                          color: green,
                          size: 28,
                        ),
                      ),

                      const SizedBox(
                        width: 13,
                      ),

                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              item.nama,
                              maxLines:
                                  2,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                color:
                                    navy,
                                fontSize:
                                    18,
                                fontWeight:
                                    FontWeight
                                        .w900,
                              ),
                            ),

                            const SizedBox(
                              height: 7,
                            ),

                            _statusBadge(
                              displayStatus,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  _detailLine(
                    'Kode',
                    item.kode,
                  ),

                  _detailLine(
                    'Kategori',
                    item.kategori,
                  ),

                  _detailLine(
                    'PIC',
                    item.pic,
                  ),

                  _detailLine(
                    'Deadline',
                    item.deadlineLabel,
                  ),

                  _detailLine(
                    'Dibuat',
                    item.formattedDate,
                  ),

                  if (assigned)
                    _detailLine(
                      'Pengumpulan',
                      submission == null
                          ? 'Belum dikumpulkan'
                          : 'Dikumpulkan '
                              '${_formatDateTime(submission.submittedAt)}',
                    ),

                  if (submission != null &&
                      submission.title.isNotEmpty)
                    _detailLine(
                      'Yang dikumpulkan',
                      submission.title,
                    ),

                  if (submission != null &&
                      submission.link.isNotEmpty)
                    _detailLine(
                      'Link',
                      submission.link,
                    ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Text(
                    'Deskripsi',
                    style:
                        TextStyle(
                      color: navy,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    item.deskripsi.isEmpty
                        ? 'Tidak ada deskripsi.'
                        : item.deskripsi,
                    style:
                        const TextStyle(
                      color: muted,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  Row(
                    children: [
                      if (widget.user.canDelete) ...[
                      Expanded(
                        child:
                            OutlinedButton
                                .icon(
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                            );
                            _deleteTask(
                              item,
                            );
                          },
                          icon:
                              const Icon(
                            Icons
                                .delete_outline_rounded,
                          ),
                          label:
                              const Text(
                            'Hapus',
                          ),
                          style:
                              OutlinedButton
                                  .styleFrom(
                            foregroundColor:
                                red,
                            minimumSize:
                                const Size
                                    .fromHeight(
                              48,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                13,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      ],

                      if (assigned)
                        Expanded(
                          child:
                              FilledButton.icon(
                            onPressed: submitted
                                ? null
                                : () {
                                    Navigator.pop(
                                      sheetContext,
                                    );
                                    _submitTask(
                                      item,
                                    );
                                  },
                            icon: Icon(
                              submitted
                                  ? Icons
                                      .check_circle_outline_rounded
                                  : Icons
                                      .upload_rounded,
                            ),
                            label: Text(
                              done
                                  ? 'Sudah dikoreksi'
                                  : submitted
                                      ? 'Menunggu koreksi Admin'
                                      : 'Kumpulkan Tugas',
                            ),
                            style:
                                FilledButton
                                    .styleFrom(
                              backgroundColor:
                                  green,
                              minimumSize:
                                  const Size
                                      .fromHeight(
                                48,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  13,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                      Expanded(
                        child:
                            FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                            );
                            _editTask(
                              item,
                            );
                          },
                          icon:
                              const Icon(
                            Icons
                                .edit_rounded,
                          ),
                          label:
                              const Text(
                            'Edit',
                          ),
                          style:
                              FilledButton
                                  .styleFrom(
                            backgroundColor:
                                green,
                            minimumSize:
                                const Size
                                    .fromHeight(
                              48,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
    String displayStatus,
  ) {
    final color =
        _statusColor(
      displayStatus,
    );

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withAlpha(20),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            _statusIcon(
              displayStatus,
            ),
            size: 13,
            color: color,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            displayStatus,
            style:
                TextStyle(
              color: color,
              fontSize: 11,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL LINE
  // ============================================================

  Widget _detailLine(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 11,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style:
                  const TextStyle(
                color: muted,
                fontSize: 12,
              ),
            ),
          ),

          const Text(
            ': ',
          ),

          Expanded(
            child: Text(
              value.isEmpty
                  ? '-'
                  : value,
              style:
                  const TextStyle(
                color: navy,
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState({
    required bool noTasks,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(28),
      decoration:
          _cardDecoration(),
      child: Column(
        children: [
          Icon(
            noTasks
                ? Icons
                    .assignment_outlined
                : Icons
                    .search_off_rounded,
            color:
                const Color(
              0xFF94A3B8,
            ),
            size: 43,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            noTasks
                ? 'Belum ada tugas.'
                : 'Tidak ada tugas yang cocok.',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            noTasks
                ? 'Tekan tombol Tambah Tugas untuk membuat tugas baru.'
                : 'Coba ubah kata kunci atau reset filter.',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),

          if (noTasks) ...[
            const SizedBox(
              height: 16,
            ),
            FilledButton.icon(
              onPressed:
                  _addTask,
              icon:
                  const Icon(
                Icons.add_rounded,
              ),
              label:
                  const Text(
                'Buat Tugas Pertama',
              ),
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    green,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// MENU POPUP
// ============================================================

class _MenuRow
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuRow(
    this.icon,
    this.label, {
    this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color:
              color ??
                  const Color(
                0xFF475569,
              ),
        ),
        const SizedBox(
          width: 12,
        ),
        Text(
          label,
          style:
              TextStyle(
            color:
                color ??
                    const Color(
                  0xFF475569,
                ),
            fontWeight:
                FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}
