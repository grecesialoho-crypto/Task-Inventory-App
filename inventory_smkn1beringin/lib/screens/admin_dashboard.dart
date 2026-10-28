import 'package:flutter/material.dart';

import '../models/item_model.dart';
import 'add_item_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserAccount user;

  const AdminDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  // ============================================================
  // WARNA
  // ============================================================

  static const Color navy = Color(0xFF172B4D);
  static const Color green = Color(0xFF0F9D85);
  static const Color blue = Color(0xFF2563EB);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color red = Color(0xFFDC2626);
  static const Color muted = Color(0xFF64748B);
  static const Color background = Color(0xFFF5F7FB);
  static const Color border = Color(0xFFE8EDF4);

  static const String adminEmail =
      'grecefitriyanihaloho@gmail.com';

  static const String all = 'Semua';

  // ============================================================
  // CONTROLLER & STATE
  // ============================================================

  final TextEditingController searchController =
      TextEditingController();

  int selectedIndex = 0;

  // Halaman Persetujuan dibuka dari kotak di Dashboard.
  bool showApproval = false;

  // Halaman Notifikasi Tugas dibuka dari kotak di Dashboard.
  bool showNotices = false;

  String search = '';

  String statusFilter = all;

  ItemSort sort = ItemSort.terbaru;

  // Memakai daftar status resmi (huruf besar-kecil sama dengan data).
  // (Di Pinjam, Proses, Pending, Selesai) untuk filter daftar.
  final List<String> availableStatuses = AppOptions.inventoryStatuses;

  // ============================================================
  // SNACKBAR
  // ============================================================

  void showMessage(
    String message, {
    Color color = green,
  }) {
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
  // NAVIGASI BOTTOM
  // ============================================================

  void goTo(int index) {
    setState(() {
      selectedIndex = index;
      showApproval = false;
      showNotices = false;
      search = '';
      statusFilter = all;
      sort = ItemSort.terbaru;
    });

    searchController.clear();
  }

  // ============================================================
  // TAMBAH DATA
  // ============================================================

  Future<void> openAdd({
    String type = AppOptions.inventory,
  }) async {
    final result = await Navigator.push<ItemModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(
          user: widget.user,
          defaultType: type,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      ItemStore.add(result, by: widget.user);
    });

    showMessage(
      result.isTask
          ? 'Tugas berhasil ditambahkan dan langsung muncul di semua akun User.'
          : 'Data berhasil ditambahkan.',
    );
  }

  // ============================================================
  // EDIT DATA
  // ============================================================

  Future<void> editItem(
    ItemModel item,
  ) async {
    final result = await Navigator.push<ItemModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(
          user: widget.user,
          defaultType: item.jenisData,
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

    showMessage(
      'Data berhasil diperbarui.',
    );
  }

  // ============================================================
  // UBAH STATUS
  // ============================================================

  void changeStatus(
    ItemModel item,
    String status,
  ) {
    if (item.status == status) {
      return;
    }

    late final bool changed;

    setState(() {
      changed = ItemStore.changeStatus(
        item.id,
        status,
        by: widget.user,
      );
    });

    showMessage(
      changed
          ? 'Status berhasil diubah menjadi $status.'
          : 'Anda tidak berhak mengubah status.',
    );
  }

  // ============================================================
  // HAPUS DATA
  // ============================================================

  Future<void> deleteItem(
    ItemModel item,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Hapus Data?',
          ),
          content: Text(
            ItemStore.isAssigned(item)
                ? 'Yakin ingin menghapus "${item.nama}"?\n\n'
                    'Tugas ini juga akan hilang dari semua akun User '
                    'beserta data pengumpulannya.'
                : 'Yakin ingin menghapus "${item.nama}"?',
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
              style: FilledButton.styleFrom(
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

    final wasAssigned = ItemStore.isAssigned(item);

    setState(() {
      ItemStore.remove(item.id, by: widget.user);
    });

    showMessage(
      wasAssigned
          ? 'Tugas dihapus dan ikut hilang dari semua akun User.'
          : 'Data berhasil dihapus.',
      color: red,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: Color(0xFFDC2626),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text('Keluar dari akun?'),
            ),
          ],
        ),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun Admin?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
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

  // Hapus semua halaman sebelumnya dan kembali ke login.
  Navigator.of(context).pushNamedAndRemoveUntil(
    '/login',
    (route) => false,
  );
}

  // ============================================================
  // BUILD UTAMA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final stats = ItemStore.stats();
    final unreadNotices = ItemStore.unreadNoticeCount;

    final Widget page;

    if (showApproval && widget.user.canApproveAccounts) {
      page = accountApprovalPage();
    } else if (showNotices) {
      page = noticePage();
    } else {
      switch (selectedIndex) {
        case 1:
          page = listPage();
          break;

        case 2:
          page = profilePage(
            stats,
          );
          break;

        default:
          page = dashboardPage(
            stats,
          );
      }
    }

    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 760,
            ),
            child: AnimatedSwitcher(
              duration:
                  const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(
                  (showApproval && widget.user.canApproveAccounts)
                      ? 99
                      : showNotices
                          ? 98
                          : selectedIndex,
                ),
                child: page,
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar:
          NavigationBar(
        selectedIndex:
            selectedIndex,

        onDestinationSelected:
            goTo,

        backgroundColor:
            Colors.white,

        indicatorColor:
            const Color(0xFFDDF5EF),

        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadNotices > 0,
              label: Text('$unreadNotices'),
              child: const Icon(
                Icons.dashboard_outlined,
              ),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadNotices > 0,
              label: Text('$unreadNotices'),
              child: const Icon(
                Icons.dashboard_rounded,
              ),
            ),
            label: 'Dashboard',
          ),

          NavigationDestination(
            icon: Badge(
              isLabelVisible:
                  stats.overdue > 0,
              label: Text(
                '${stats.overdue}',
              ),
              child: const Icon(
                Icons.task_alt_outlined,
              ),
            ),
            selectedIcon:
                const Icon(
              Icons.task_alt_rounded,
            ),
            label: 'Tugas',
          ),

          const NavigationDestination(
            icon: Icon(
              Icons.person_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.person_rounded,
            ),
            label: 'My Profil',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KERANGKA HALAMAN
  // ============================================================

  Widget pageFrame({
    required String title,
    required String subtitle,
    required List<Widget> children,
    Widget? action,
    VoidCallback? onBack,
  }) {
    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            18,
          ),
          color: Colors.white,
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                  ),
                  color: navy,
                  tooltip: 'Kembali',
                ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        color: navy,
                        fontSize: 23,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null)
                action,
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.all(18),
            children: children,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARD DECORATION
  // ============================================================

  BoxDecoration cardDecoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(radius),
      border: Border.all(
        color: border,
      ),
      boxShadow: [
        BoxShadow(
          color:
              Colors.black.withAlpha(10),
          blurRadius: 15,
          offset:
              const Offset(0, 5),
        ),
      ],
    );
  }

  // ============================================================
  // LOGO SEKOLAH
  // ============================================================

  Widget schoolLogo({
    double size = 76,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/image/logo_smkn1_beringin.png',
cacheWidth: 300,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality:
            FilterQuality.high,
        errorBuilder:
            (
          context,
          error,
          stackTrace,
        ) {
          return Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: size * .6,
          );
        },
      ),
    );
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Widget dashboardPage(
    ItemStats stats,
  ) {
    final recent =
        ItemStore.query()
            .take(4)
            .toList();

    return pageFrame(
      title: 'Dashboard',
      subtitle:
          'Pusat Pengelolaan Inventaris & Tugas Sekolah',

      children: [
        // --------------------------------------------------------
        // HERO
        // --------------------------------------------------------

        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(21),

          decoration:
              BoxDecoration(
            gradient:
                const LinearGradient(
              begin:
                  Alignment.topLeft,
              end:
                  Alignment.bottomRight,
              colors: [
                Color(0xFF123F59),
                Color(0xFF0F9D85),
              ],
            ),
            borderRadius:
                BorderRadius.circular(23),
            boxShadow: [
              BoxShadow(
                color:
                    green.withAlpha(45),
                blurRadius: 18,
                offset:
                    const Offset(0, 8),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  schoolLogo(
                    size: 76,
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELAMAT DATANG DI',
                          style:
                              TextStyle(
                            color:
                                Colors.white70,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w700,
                            letterSpacing:
                                1.1,
                          ),
                        ),

                        SizedBox(
                          height: 7,
                        ),

                        Text(
                          'SMKN 1 BERINGIN',
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontSize: 21,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),

                        SizedBox(
                          height: 6,
                        ),

                        Text(
                          'Pusat Pengelolaan Inventaris & Tugas Sekolah',
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  // Lonceng notifikasi pengumpulan tugas
                  Badge(
                    isLabelVisible:
                        ItemStore.unreadNoticeCount > 0,
                    label: Text(
                      '${ItemStore.unreadNoticeCount}',
                    ),
                    child: IconButton(
                      tooltip: 'Notifikasi Tugas',
                      onPressed: () {
                        setState(() {
                          showNotices = true;
                        });
                      },
                      icon: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            Colors.white.withAlpha(40),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 23,
        ),

        // --------------------------------------------------------
        // PERSETUJUAN AKUN (kotak yang bisa diklik)
        // --------------------------------------------------------

        // Admin biasa tidak melihat kotak ini sama sekali.
        if (widget.user.canApproveAccounts) ...[
          approvalBox(),

          const SizedBox(
            height: 20,
          ),
        ],

        // --------------------------------------------------------
        // DATA TERBARU
        // --------------------------------------------------------

        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
          children: [
            const Text(
              'Data Terbaru',
              style:
                  TextStyle(
                color: navy,
                fontSize: 17,
                fontWeight:
                    FontWeight.w900,
              ),
            ),

            TextButton(
              onPressed:
                  () => goTo(1),
              child:
                  const Text(
                'Lihat semua',
              ),
            ),
          ],
        ),

        if (recent.isEmpty)
          emptyState(
            'Belum ada data.',
          )
        else
          ...recent.map(
            itemCard,
          ),
      ],
    );
  }

  // ============================================================
  // KOTAK PERSETUJUAN AKUN (di Dashboard)
  // ============================================================

  Widget approvalBox() {
    final int pending = AuthService.pendingAccounts.length;
    final bool hasPending = pending > 0;
    final bool canDecide = widget.user.canApproveAccounts;

    final Color accent = hasPending ? red : green;

    final String subtitle = !hasPending
        ? 'Tidak ada akun yang menunggu'
        : canDecide
            ? '$pending akun menunggu keputusan Anda'
            : '$pending akun menunggu Admin Utama';

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hasPending ? accent.withAlpha(80) : border,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha(24),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            setState(() {
              showApproval = true;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent,
                        accent.withAlpha(190),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Persetujuan Akun',
                        style: TextStyle(
                          color: navy,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasPending ? accent : muted,
                          fontSize: 12,
                          fontWeight: hasPending
                              ? FontWeight.w700
                              : FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                if (hasPending) ...[
                  const SizedBox(
                    width: 8,
                  ),

                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 30,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$pending',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],

                const SizedBox(
                  width: 6,
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: muted,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INVENTORY / TUGAS
  // ============================================================

  // isTask == null berarti tampilkan semua data (tugas dan inventory).
  Widget listPage({
    bool? isTask,
  }) {
    final String? type = isTask == null
        ? null
        : (isTask
            ? AppOptions.task
            : AppOptions.inventory);

    final source =
        ItemStore.query(
      jenisData: type,
    );

    final filtered =
        ItemStore.query(
      search: search,
      jenisData: type,
      status:
          statusFilter == all
              ? null
              : statusFilter,
      sort: sort,
    );

    return pageFrame(
      title: 'Tugas',

      subtitle:
          'Kelola tugas dan inventory sekolah',

      action:
          IconButton.filled(
        onPressed:
            () => openAdd(
          type: type ?? AppOptions.task,
        ),
        icon:
            const Icon(
          Icons.add_rounded,
        ),
        style:
            IconButton.styleFrom(
          backgroundColor:
              green,
          foregroundColor:
              Colors.white,
        ),
      ),

      children: [
        // --------------------------------------------------------
        // SEARCH
        // --------------------------------------------------------

        TextField(
          controller:
              searchController,

          onChanged:
              (value) {
            setState(() {
              search = value;
            });
          },

          decoration:
              InputDecoration(
            hintText:
                'Cari tugas atau inventory...',

            prefixIcon:
                const Icon(
              Icons.search,
            ),

            suffixIcon:
                search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController
                              .clear();

                          setState(() {
                            search =
                                '';
                          });
                        },
                        icon:
                            const Icon(
                          Icons
                              .close_rounded,
                        ),
                      ),

            filled: true,

            fillColor:
                Colors.white,

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
                color: blue,
                width: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        const Text(
          'Filter Status',
          style:
              TextStyle(
            color: navy,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        const SizedBox(
          height: 9,
        ),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            filterChip(
              all,
            ),
            ...availableStatuses.map(
              filterChip,
            ),
          ],
        ),

        const SizedBox(
          height: 15,
        ),

        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
          children: [
            Text(
              '${filtered.length} data ditemukan',
              style:
                  const TextStyle(
                color: muted,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            PopupMenuButton<ItemSort>(
              initialValue:
                  sort,

              onSelected:
                  (value) {
                setState(() {
                  sort = value;
                });
              },

              itemBuilder:
                  (_) =>
                      ItemSort.values
                          .map(
                            (
                              value,
                            ) =>
                                PopupMenuItem(
                              value:
                                  value,
                              child:
                                  Text(
                                value.label,
                              ),
                            ),
                          )
                          .toList(),

              child:
                  const Row(
                children: [
                  Icon(
                    Icons.sort,
                    size: 19,
                    color: navy,
                  ),
                  SizedBox(
                    width: 4,
                  ),
                  Text(
                    'Urutkan',
                    style:
                        TextStyle(
                      color: navy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        if (source.isEmpty)
          emptyState(
            'Belum ada data.',
          )
        else if (filtered.isEmpty)
          emptyState(
            'Data tidak ditemukan.',
          )
        else
          ...filtered.map(
            itemCard,
          ),
      ],
    );
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget filterChip(
    String value,
  ) {
    final selected =
        statusFilter == value;

    return ChoiceChip(
      label:
          Text(value),

      selected:
          selected,

      onSelected:
          (_) {
        setState(() {
          statusFilter =
              value;
        });
      },

      selectedColor:
          const Color(
        0xFFDDF5EF,
      ),

      labelStyle:
          TextStyle(
        color:
            selected
                ? green
                : muted,
        fontWeight:
            FontWeight.w700,
        fontSize: 11,
      ),

      side:
          BorderSide(
        color:
            selected
                ? green
                : border,
      ),
    );
  }

  // ============================================================
  // DETAIL DATA
  // ============================================================

  void showItemDetail(
    ItemModel item,
  ) {
    final assigned = ItemStore.isAssigned(item);

    final status = assigned
        ? 'Untuk semua user'
        : AppOptions.normalizeStatus(
            item.status,
          );

    final statusColor = assigned
        ? blue
        : AppOptions.statusColor(
            status,
          );
    final typeColor =
        AppOptions.typeColor(
      item.jenisData,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(
                      sheetContext,
                    ).size.height *
                    0.88,
          ),
          padding:
              const EdgeInsets.fromLTRB(
            22,
            18,
            22,
            22,
          ),
          decoration:
              const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
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
                    height: 20,
                  ),

                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration:
                            BoxDecoration(
                          color: typeColor
                              .withAlpha(
                            28,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),
                        child: Icon(
                          AppOptions
                              .typeIcon(
                            item.jenisData,
                          ),
                          color:
                              typeColor,
                          size: 28,
                        ),
                      ),

                      const SizedBox(
                        width: 13,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              item.nama,
                              maxLines: 2,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                color: navy,
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

                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    10,
                                vertical:
                                    4,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: statusColor
                                    .withAlpha(
                                  25,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                              ),
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,
                                children: [
                                  Icon(
                                    AppOptions
                                        .statusIcon(
                                      status,
                                    ),
                                    size: 13,
                                    color:
                                        statusColor,
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                    status,
                                    style:
                                        TextStyle(
                                      color:
                                          statusColor,
                                      fontSize:
                                          11.5,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  detailLine(
                    'Kode',
                    item.kode,
                  ),

                  detailLine(
                    'Jenis',
                    item.isTask
                        ? 'Tugas'
                        : 'Inventory',
                  ),

                  detailLine(
                    'Kategori',
                    item.kategori,
                  ),

                  detailLine(
                    'PIC',
                    item.pic,
                  ),

                  if (item.isTask)
                    detailLine(
                      'Deadline',
                      item.deadlineLabel,
                    )
                  else
                    detailLine(
                      'Lokasi',
                      item.lokasi,
                    ),

                  detailLine(
                    'Dibuat',
                    item.formattedDate,
                  ),

                  detailLine(
                    'Dibuat oleh',
                    item.createdBy,
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  const Text(
                    'Deskripsi',
                    style: TextStyle(
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

                  if (assigned) ...[
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      showSubmissions(item);
                    },
                    icon: const Icon(
                      Icons.fact_check_outlined,
                    ),
                    label: Text(
                      'Lihat & Nilai Pengumpulan '
                      '(${ItemStore.submittedCount(item.id)}/'
                      '${ItemStore.assignees.length})',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: blue,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                Row(
                    children: [
                      Expanded(
                        child:
                            OutlinedButton
                                .icon(
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                            );
                            deleteItem(
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

                      Expanded(
                        child:
                            FilledButton
                                .icon(
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                            );
                            editItem(
                              item,
                            );
                          },
                          icon:
                              const Icon(
                            Icons
                                .edit_outlined,
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

  Widget detailLine(
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

          const Text(': '),

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
  // ITEM CARD
  // ============================================================

  Widget itemCard(
    ItemModel item,
  ) {
    final statusColor =
        AppOptions.statusColor(
      item.status,
    );

    // Status yang berlaku untuk jenis data ini
    // (tugas tidak punya "Di Pinjam").
    final options =
        AppOptions.statusesFor(
      item.jenisData,
    );

    final selectedStatus =
        options.contains(
      item.status,
    )
            ? item.status
            : options.first;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(15),

      decoration:
          cardDecoration(),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ------------------------------------------------------
          // JUDUL ITEM
          // ------------------------------------------------------

          Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Container(
                width: 44,
                height: 44,

                decoration:
                    BoxDecoration(
                  color: item
                      .categoryColor
                      .withAlpha(25),
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),

                child:
                    Icon(
                  item.iconKategori,
                  color:
                      item.categoryColor,
                ),
              ),

              const SizedBox(
                width: 12,
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
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color: navy,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w900,
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
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                onSelected:
                    (value) {
                  if (value ==
                      'detail') {
                    showItemDetail(
                      item,
                    );
                  } else if (value ==
                      'edit') {
                    editItem(
                      item,
                    );
                  } else if (value ==
                      'delete') {
                    deleteItem(
                      item,
                    );
                  }
                },

                itemBuilder:
                    (_) => const [
                  PopupMenuItem(
                    value: 'detail',
                    child:
                        Text(
                      'Lihat detail',
                    ),
                  ),

                  PopupMenuItem(
                    value: 'edit',
                    child:
                        Text(
                      'Edit data',
                    ),
                  ),

                  PopupMenuItem(
                    value:
                        'delete',
                    child:
                        Text(
                      'Hapus data',
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          // Tugas dari Admin: status dinilai per user.
          if (ItemStore.isAssigned(item))
            assignedSummary(item)
          else ...[
          // ------------------------------------------------------
          // STATUS
          // ------------------------------------------------------

          Row(
            children: [
              const Text(
                'Status',
                style:
                    TextStyle(
                  color: muted,
                  fontSize: 11,
                ),
              ),

              const Spacer(),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      statusColor
                          .withAlpha(
                    25,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child: Text(
                  item.status,
                  style:
                      TextStyle(
                    color:
                        statusColor,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          // ------------------------------------------------------
          // UBAH STATUS
          // ------------------------------------------------------

          DropdownButtonFormField<String>(
            initialValue:
                selectedStatus,

            decoration:
                InputDecoration(
              labelText:
                  'Ubah status',

              contentPadding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 12,
                vertical: 9,
              ),

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
            ),

            items:
                options
                    .map(
                      (
                        status,
                      ) =>
                          DropdownMenuItem<
                              String>(
                        value:
                            status,
                        child:
                            Text(
                          status,
                        ),
                      ),
                    )
                    .toList(),

            onChanged:
                (value) {
              if (value !=
                  null) {
                changeStatus(
                  item,
                  value,
                );
              }
            },
          ),

          ],

          // ------------------------------------------------------
          // DESKRIPSI
          // ------------------------------------------------------

          if (item
              .deskripsi
              .isNotEmpty) ...[
            const SizedBox(
              height: 10,
            ),

            Text(
              item.deskripsi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color: muted,
                fontSize: 12,
              ),
            ),
          ],

          // ------------------------------------------------------
          // LOKASI
          // ------------------------------------------------------

          if (item
              .lokasi
              .isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),

            Row(
              children: [
                const Icon(
                  Icons
                      .location_on_outlined,
                  size: 15,
                  color: muted,
                ),

                const SizedBox(
                  width: 5,
                ),

                Expanded(
                  child:
                      Text(
                    item.lokasi,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      color: muted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ------------------------------------------------------
          // DEADLINE
          // ------------------------------------------------------

          if (item.isTask &&
              item.deadline
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),

            Row(
              children: [
                const Icon(
                  Icons
                      .calendar_month_outlined,
                  size: 15,
                  color: muted,
                ),

                const SizedBox(
                  width: 5,
                ),

                Expanded(
                  child:
                      Text(
                    'Deadline: ${DateText.format(item.deadline)}',
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      color: muted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget emptyState(
    String message,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(25),

      decoration:
          cardDecoration(),

      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 42,
            color: muted,
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            message,
            style:
                const TextStyle(
              color: muted,
              fontSize: 13,
            ),
            textAlign:
                TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MY PROFIL
  // ============================================================

  // ============================================================
  // PERSETUJUAN AKUN BARU
  // ============================================================

  // ============================================================
  // CHIP KECIL
  // ============================================================

  Widget miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // RINGKASAN TUGAS ADMIN (di kartu)
  // ============================================================

  Widget assignedSummary(ItemModel item) {
    final total = ItemStore.assignees.length;
    final submitted = ItemStore.submittedCount(item.id);
    final done = ItemStore.doneCount(item.id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.groups_rounded,
                size: 18,
                color: blue,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tugas untuk semua user',
                  style: TextStyle(
                    color: navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              miniChip('$submitted/$total dikumpulkan', blue),
              miniChip('$done selesai', green),
              miniChip(
                '${total - submitted} belum mengumpulkan',
                muted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => showSubmissions(item),
              icon: const Icon(
                Icons.fact_check_outlined,
                size: 18,
              ),
              label: const Text('Lihat & Nilai Pengumpulan'),
              style: FilledButton.styleFrom(
                backgroundColor: blue,
                minimumSize: const Size.fromHeight(42),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DAFTAR PENGUMPULAN PER USER (admin menilai di sini)
  // ============================================================

  void showSubmissions(ItemModel item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final users = ItemStore.assignees;
            final submitted = ItemStore.submittedCount(item.id);
            final done = ItemStore.doneCount(item.id);

            void refresh() {
              setSheetState(() {});
              if (mounted) {
                setState(() {});
              }
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(sheetContext).size.height * 0.88,
              ),
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      item.nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.kode} • Deadline ${item.deadlineLabel}',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        miniChip(
                          '$submitted/${users.length} dikumpulkan',
                          blue,
                        ),
                        miniChip('$done selesai', green),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: users.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 24,
                              ),
                              child: Text(
                                'Belum ada akun User yang terdaftar.',
                                style: TextStyle(color: muted),
                              ),
                            )
                          : ListView(
                              shrinkWrap: true,
                              children: users
                                  .map(
                                    (account) => submissionTile(
                                      item,
                                      account,
                                      refresh,
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget submissionTile(
    ItemModel item,
    UserAccount account,
    VoidCallback refresh,
  ) {
    final sub = ItemStore.submissionOf(item.id, account.username);
    final submitted = sub != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: blue.withAlpha(22),
                child: Text(
                  account.initials,
                  style: const TextStyle(
                    color: blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '@${account.username}',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              miniChip(
                submitted ? 'Dikumpulkan' : 'Belum mengumpulkan',
                submitted ? blue : muted,
              ),
            ],
          ),
          if (sub != null) ...[
            const SizedBox(height: 10),
            Text(
              'Dikumpulkan ${_formatDateTime(sub.submittedAt)}',
              style: const TextStyle(
                color: muted,
                fontSize: 11.5,
              ),
            ),
            if (sub.title.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                sub.title,
                style: const TextStyle(
                  color: navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            if (sub.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                sub.note,
                style: const TextStyle(
                  color: muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
            if (sub.link.isNotEmpty) ...[
              const SizedBox(height: 4),
              SelectableText(
                sub.link,
                style: const TextStyle(
                  color: blue,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppOptions.taskStatuses.map((status) {
                final selected = sub.status == status;
                final color = AppOptions.statusColor(status);

                return ChoiceChip(
                  selected: selected,
                  showCheckmark: false,
                  avatar: Icon(
                    AppOptions.statusIcon(status),
                    size: 16,
                    color: selected ? Colors.white : color,
                  ),
                  label: Text(status),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: selected ? Colors.white : color,
                  ),
                  selectedColor: color,
                  backgroundColor: color.withAlpha(24),
                  side: BorderSide(
                    color: color.withAlpha(selected ? 255 : 70),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (_) {
                    if (selected) return;

                    final ok = ItemStore.setSubmissionStatus(
                      item.id,
                      account.username,
                      status,
                      by: widget.user,
                    );

                    if (ok) {
                      refresh();
                    }
                  },
                );
              }).toList(),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Status baru bisa dinilai setelah user mengumpulkan.',
                style: TextStyle(
                  color: muted,
                  fontSize: 11.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // HALAMAN NOTIFIKASI TUGAS
  // ============================================================

  Widget noticePage() {
    final notices = ItemStore.notices;
    final unread = ItemStore.unreadNoticeCount;

    return pageFrame(
      onBack: () {
        setState(() {
          showNotices = false;
        });
      },
      title: 'Notifikasi Tugas',
      subtitle: 'Pengumpulan tugas dari user',
      action: unread > 0
          ? TextButton(
              onPressed: () {
                setState(() {
                  ItemStore.markAllNoticesRead();
                });
              },
              child: const Text('Tandai dibaca'),
            )
          : null,
      children: [
        if (notices.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 34,
              horizontal: 20,
            ),
            decoration: cardDecoration(),
            child: const Column(
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 48,
                  color: muted,
                ),
                SizedBox(height: 12),
                Text(
                  'Belum ada notifikasi',
                  style: TextStyle(
                    color: navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Notifikasi muncul saat user mengumpulkan tugas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, height: 1.4),
                ),
              ],
            ),
          )
        else
          ...notices.map(noticeTile),
      ],
    );
  }

  Widget noticeTile(AppNotice notice) {
    final unread = !notice.read;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: unread ? const Color(0xFFF3F8FF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unread ? blue.withAlpha(70) : border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            ItemStore.markNoticeRead(notice.id);
          });

          ItemModel? task;
          for (final candidate in ItemStore.all) {
            if (candidate.id == notice.taskId) {
              task = candidate;
              break;
            }
          }

          if (task == null) return;

          if (ItemStore.isAssigned(task)) {
            showSubmissions(task);
          } else {
            showItemDetail(task);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: blue.withAlpha(unread ? 30 : 16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.assignment_turned_in_rounded,
                  color: unread ? blue : muted,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      style: TextStyle(
                        color: navy,
                        fontSize: 13.5,
                        fontWeight: unread
                            ? FontWeight.w900
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notice.message,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatDateTime(notice.createdAt),
                      style: const TextStyle(
                        color: muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // KOTAK ADMIN UTAMA (di Profil)
  // ============================================================

  Widget adminRoleBox() {
    final isMain = widget.user.isSuperAdmin;
    final color = isMain ? green : blue;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isMain
                  ? Icons.workspace_premium_rounded
                  : Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMain ? 'Admin Utama' : 'Admin',
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isMain
                      ? 'Dapat menyetujui & menolak akun baru'
                      : 'Mengelola tugas dan inventory',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget accountApprovalPage() {
    final pending = AuthService.pendingAccounts;
    final canDecide = widget.user.canApproveAccounts;
    final history = AuthService.history;

    return pageFrame(
      onBack: () {
        setState(() {
          showApproval = false;
        });
      },
      title: 'Persetujuan Akun',
      subtitle: canDecide
          ? 'Periksa pendaftaran baru sebelum akun dapat digunakan.'
          : 'Hanya Admin Utama yang dapat menyetujui akun.',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD5E4FF)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: blue, size: 27),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pending.isEmpty
                      ? 'Belum ada akun yang menunggu persetujuan.'
                      : canDecide
                          ? 'Ada ${pending.length} akun yang menunggu pemeriksaan Admin Utama.'
                          : 'Ada ${pending.length} akun menunggu. Hanya Admin Utama yang dapat menyetujui atau menolak.',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (pending.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
            decoration: cardDecoration(),
            child: const Column(
              children: [
                Icon(Icons.mark_email_read_outlined, size: 48, color: muted),
                SizedBox(height: 12),
                Text(
                  'Semua beres!',
                  style: TextStyle(
                    color: navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Akun baru akan muncul di sini setelah pengguna mendaftar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, height: 1.4),
                ),
              ],
            ),
          )
        else
          ...pending.map((account) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 23,
                        backgroundColor: blue.withAlpha(22),
                        child: Text(
                          account.initials,
                          style: const TextStyle(
                            color: blue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: navy,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '@${account.username}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: account.isAdmin
                              ? const Color(0xFFF3E8FF)
                              : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          account.role,
                          style: TextStyle(
                            color: account.isAdmin
                                ? purple
                                : blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 16, color: muted),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          account.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (canDecide) ...[
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final removed = AuthService.rejectAccount(
                              account.username,
                              by: widget.user,
                            );
                            if (!mounted) return;
                            setState(() {});
                            showMessage(
                              removed
                                  ? 'Pendaftaran ${account.username} ditolak.'
                                  : 'Akun sudah tidak tersedia.',
                              color: red,
                            );
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Tolak'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: red,
                            side: const BorderSide(color: Color(0xFFFECACA)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            final approved = AuthService.approveAccount(
                              account.username,
                              by: widget.user,
                            );
                            if (!mounted) return;
                            setState(() {});
                            showMessage(
                              approved
                                  ? 'Akun ${account.username} disetujui dan sekarang bisa login.'
                                  : 'Akun sudah tidak tersedia.',
                              color: green,
                            );
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Setujui'),
                          style: FilledButton.styleFrom(
                            backgroundColor: green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ] else
                    const Text(
                      'Menunggu keputusan Admin Utama.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            );
          }),
        const SizedBox(height: 20),
        const Text(
          'Riwayat Persetujuan',
          style: TextStyle(
            color: navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: cardDecoration(),
            child: const Text(
              'Belum ada riwayat persetujuan akun.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
          )
        else
          ...history.map(_approvalHistoryTile),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  Widget _approvalHistoryTile(ApprovalRecord record) {
    final color = record.isApproved ? green : red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withAlpha(25),
            child: Icon(
              record.isApproved
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      record.action,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '@${record.username} • ${record.role}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                Text(
                  record.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  'Oleh ${record.decidedByName} (@${record.decidedBy}) • '
                  '${_formatDateTime(record.decidedAt)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget profilePage(
    ItemStats stats,
  ) {
    return pageFrame(
      title: 'My Profil',
      subtitle:
          'Informasi akun dan sekolah',

      children: [
        Container(
          width:
              double.infinity,

          padding:
              const EdgeInsets.all(
            22,
          ),

          decoration:
              cardDecoration(
            radius: 21,
          ),

          child: Column(
            children: [
              schoolLogo(
                size: 90,
              ),

              const SizedBox(
                height: 15,
              ),

              const Text(
                'SMKN 1 BERINGIN',
                style:
                    TextStyle(
                  color: navy,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 7,
              ),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 13,
                  vertical: 6,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFDDF5EF,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child:
                    const Text(
                  'PUSAT PENGELOLAAN SEKOLAH',
                  style:
                      TextStyle(
                    color: green,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 15,
        ),

        adminRoleBox(),

        profileInfo(
          'Username',
          widget.user.username,
          Icons.person_outline,
        ),

        profileInfo(
          'Email',
          widget.user.isSuperAdmin
              ? adminEmail
              : widget.user.email,
          Icons.email_outlined,
        ),

        const SizedBox(
          height: 15,
        ),

        // --------------------------------------------------------
        // TENTANG APLIKASI
        // --------------------------------------------------------

        Container(
          padding:
              const EdgeInsets.all(18),

          decoration:
              cardDecoration(),

          child:
              const Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Tentang Aplikasi',
                style:
                    TextStyle(
                  color: navy,
                  fontWeight:
                      FontWeight.w900,
                  fontSize: 15,
                ),
              ),

              SizedBox(
                height: 12,
              ),

              Text(
                'SMKN 1 BERINGIN',
                style:
                    TextStyle(
                  color: green,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              SizedBox(
                height: 5,
              ),

              Text(
                'Task & Inventory Manager • Versi 1.0.0',
                style:
                    TextStyle(
                  color: muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 18,
        ),

        // --------------------------------------------------------
        // LOGOUT
        // --------------------------------------------------------

        SizedBox(
          width:
              double.infinity,

          child:
              OutlinedButton.icon(
            onPressed:
                logout,

            icon:
                const Icon(
              Icons.logout_rounded,
            ),

            label:
                const Text(
              'Logout',
            ),

            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  red,

              padding:
                  const EdgeInsets
                      .symmetric(
                vertical: 14,
              ),

              side:
                  const BorderSide(
                color: red,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MINI STAT
  // ============================================================

  // ============================================================
  // PROFILE INFO
  // ============================================================

  Widget profileInfo(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
          const EdgeInsets.all(15),

      decoration:
          cardDecoration(),

      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF0F4F8,
              ),
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),

            child: Icon(
              icon,
              color: navy,
              size: 19,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(
                    color: muted,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value.isEmpty
                      ? '-'
                      : value,
                  maxLines: 2,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color: navy,
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}