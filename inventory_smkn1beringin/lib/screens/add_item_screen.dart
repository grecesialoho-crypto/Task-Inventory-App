import 'package:flutter/material.dart';

import '../models/item_model.dart';

class AddItemScreen extends StatefulWidget {
  final UserAccount user;
  final String defaultType;
  final ItemModel? existingItem;

  const AddItemScreen({
    super.key,
    required this.user,
    this.defaultType = AppOptions.inventory,
    this.existingItem,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  static const Color _ink = Color(0xFF172B4D);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _fill = Color(0xFFF7F9FC);
  static const Color _red = Color(0xFFDC2626);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _picController;

  String _deadline = '';

  late String _type;
  late String _category;
  late String _status;

  late final String _initialSignature;

  bool _loading = false;

  bool get _isEditing => widget.existingItem != null;

  bool get _isTask => _type == AppOptions.task;

  // Tugas buatan Admin otomatis diberikan ke semua user.
  // Statusnya tidak dipilih di sini, tapi dinilai per user
  // setelah user mengumpulkan.
  bool get _isAssignedTask {
    if (!_isTask || !widget.user.canChangeStatus) return false;

    final old = widget.existingItem;
    return old == null ? true : ItemStore.isAssigned(old);
  }

  List<String> get _categories =>
      AppOptions.categoriesFor(_type);

  List<String> get _statuses =>
      AppOptions.statusesFor(_type);

  Color get _color =>
      AppOptions.typeColor(_type);

  String get _previewCode =>
      widget.existingItem?.kode ??
      ItemStore.nextCode(_type);

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    return AppOptions.statusColor(status);
  }

  IconData _statusIcon(String status) {
    return AppOptions.statusIcon(status);
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    final item = widget.existingItem;

    _type = item?.jenisData ?? widget.defaultType;

    if (!AppOptions.dataTypes.contains(_type)) {
      _type = AppOptions.inventory;
    }

    _nameController = TextEditingController(
      text: item?.nama ?? '',
    );

    _descriptionController = TextEditingController(
      text: item?.deskripsi ?? '',
    );

    _locationController = TextEditingController(
      text: item?.lokasi ?? '',
    );

    _picController = TextEditingController(
      text: item?.pic ?? widget.user.name,
    );

    _deadline = item?.deadline ?? '';

    _category =
        item?.kategori ??
        AppOptions.defaultCategoryFor(_type);

    // User biasa: data baru selalu Pending dan status tidak bisa diubah.
    _status = item?.status ??
        (widget.user.canChangeStatus
            ? AppOptions.defaultStatusFor(_type)
            : AppOptions.statusPending);

    if (!_categories.contains(_category)) {
      _category = _categories.first;
    }

    if (!_statuses.contains(_status)) {
      _status = _statuses.first;
    }

    _initialSignature = _signature();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _picController.dispose();

    super.dispose();
  }

  // ============================================================
  // STATE
  // ============================================================

  String _signature() {
    return [
      _type,
      _nameController.text.trim(),
      _category,
      _status,
      _descriptionController.text.trim(),
      _locationController.text.trim(),
      _picController.text.trim(),
      _deadline,
    ].join('|');
  }

  bool get _isDirty =>
      _signature() != _initialSignature;

  void _changeType(String value) {
    if (value == _type) return;

    setState(() {
      _type = value;

      _category =
          AppOptions.defaultCategoryFor(_type);

      _status = widget.user.canChangeStatus
          ? AppOptions.defaultStatusFor(_type)
          : AppOptions.statusPending;

      _deadline = '';
    });
  }

  // ============================================================
  // DEADLINE
  // ============================================================

  Future<void> _pickDeadline() async {
    final now = DateTime.now();

    final current = DateText.parse(_deadline);

    final initial = current ?? now;

    var first = DateTime(now.year - 1);

    var last = DateTime(
      now.year + 5,
      12,
      31,
    );

    if (initial.isBefore(first)) {
      first = DateTime(initial.year);
    }

    if (initial.isAfter(last)) {
      last = DateTime(
        initial.year,
        12,
        31,
      );
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Pilih deadline',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (picked != null && mounted) {
      setState(() {
        _deadline = DateText.iso(picked);
      });
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // CONFIRM EXIT
  // ============================================================

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Buang perubahan?',
          ),
          content: const Text(
            'Data yang sudah diisi belum disimpan '
            'dan akan hilang.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Lanjut mengisi',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _red,
              ),
              child: const Text(
                'Buang',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final deadline = _isTask ? _deadline : '';

    final error = ItemModel.validate(
      nama: _nameController.text,
      kategori: _category,
      status: _status,
      jenisData: _type,
      deadline: deadline,
    );

    if (error != null) {
      _showMessage(error);
      return;
    }

    setState(() {
      _loading = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 250),
    );

    if (!mounted) return;

    final nama = _nameController.text.trim();

    final deskripsi =
        _descriptionController.text.trim();

    final lokasi = _isTask
        ? ''
        : _locationController.text.trim();

    final pic = _picController.text.trim().isEmpty
        ? widget.user.name
        : _picController.text.trim();

    final oldItem = widget.existingItem;

    // Pengaman: user biasa tidak bisa menentukan status.
    if (!widget.user.canChangeStatus) {
      _status = oldItem?.status ?? AppOptions.statusPending;
    }

    // Tugas Admin: status master selalu Pending.
    if (_isAssignedTask) {
      _status = AppOptions.statusPending;
    }

    final ItemModel item;

    if (oldItem != null) {
      item = oldItem.copyWith(
        nama: nama,
        kategori: _category,
        status: _status,
        deskripsi: deskripsi,
        lokasi: lokasi,
        pic: pic,
        deadline: deadline,
      );
    } else {
      item = ItemModel.create(
        nama: nama,
        kategori: _category,
        status: _status,
        jenisData: _type,
        deskripsi: deskripsi,
        lokasi: lokasi,
        pic: pic,
        deadline: deadline,
        createdBy: widget.user.username,
      );
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    Navigator.pop(
      context,
      item,
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _decoration(
    String label,
    String hint,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    OutlineInputBorder outline(
      Color color, [
      double width = 1,
    ]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: color,
          width: width,
        ),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _fill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: outline(_border),
      enabledBorder: outline(_border),
      focusedBorder: outline(
        _color,
        1.6,
      ),
      errorBorder: outline(
        _red,
      ),
      focusedErrorBorder: outline(
        _red,
        1.6,
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    String text,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: _color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card({
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            _color,
            _color.withAlpha(190),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(45),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Icon(
              AppOptions.typeIcon(_type),
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'Perbarui informasi'
                      : 'Data baru',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Lengkapi informasi di bawah ini.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(45),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Text(
              _previewCode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TYPE SELECTOR
  // ============================================================

  Widget _typeSelector() {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment<String>(
          value: AppOptions.inventory,
          icon: const Icon(
            Icons.inventory_2_rounded,
            size: 18,
          ),
          label: const Text(
            'Inventory',
          ),
        ),
        ButtonSegment<String>(
          value: AppOptions.task,
          icon: const Icon(
            Icons.task_alt_rounded,
            size: 18,
          ),
          label: const Text(
            'Tugas',
          ),
        ),
      ],
      selected: {_type},
      onSelectionChanged: _isEditing
          ? null
          : (value) {
              if (value.isNotEmpty) {
                _changeType(
                  value.first,
                );
              }
            },
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
        backgroundColor:
            WidgetStateProperty.resolveWith(
          (states) {
            return states.contains(
              WidgetState.selected,
            )
                ? _color.withAlpha(28)
                : _fill;
          },
        ),
        foregroundColor:
            WidgetStateProperty.resolveWith(
          (states) {
            return states.contains(
              WidgetState.selected,
            )
                ? _color
                : _muted;
          },
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(
            color: _border,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  // User biasa hanya melihat status, tidak bisa mengubahnya.
  Widget _lockedStatusInfo() {
    final color = _statusColor(_status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isEditing
                  ? 'Status: $_status. Hanya Admin yang dapat mengubah status.'
                  : 'Status otomatis Pending. Hanya Admin yang dapat mengubah status.',
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Info untuk Admin saat membuat / mengedit tugas untuk semua user.
  Widget _assignedInfo() {
    const color = Color(0xFF0F9D85);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.groups_rounded, size: 18, color: color),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tugas ini otomatis muncul di semua akun User '
              '(termasuk akun yang mendaftar nanti). Status Pending '
              'sampai user mengumpulkan; Proses / Selesai kamu atur '
              'per user dari daftar pengumpulan.',
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _statuses.map(
        (value) {
          final selected =
              value == _status;

          final color =
              _statusColor(value);

          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            avatar: Icon(
              _statusIcon(value),
              size: 18,
              color: selected
                  ? Colors.white
                  : color,
            ),
            label: Text(value),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : color,
            ),
            selectedColor: color,
            backgroundColor:
                color.withAlpha(24),
            side: BorderSide(
              color: color.withAlpha(
                selected ? 255 : 70,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
            onSelected: (_) {
              setState(() {
                _status = value;
              });
            },
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // DEADLINE
  // ============================================================

  Widget _deadlineField() {
    final parsed =
        DateText.parse(_deadline);

    final hasValue =
        _deadline.trim().isNotEmpty;

    final display = parsed != null
        ? DateText.format(parsed)
        : hasValue
            ? _deadline
            : 'Pilih tanggal deadline';

    return InkWell(
      borderRadius:
          BorderRadius.circular(14),
      onTap: _pickDeadline,
      child: InputDecorator(
        decoration: _decoration(
          'Deadline',
          '',
          Icons.calendar_month_outlined,
          suffixIcon: hasValue
              ? IconButton(
                  tooltip:
                      'Hapus deadline',
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _deadline = '';
                    });
                  },
                )
              : const Icon(
                  Icons.arrow_drop_down_rounded,
                ),
        ),
        child: Text(
          display,
          style: TextStyle(
            fontSize: 16,
            color: hasValue
                ? _ink
                : _muted,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _saveButton() {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: _loading
            ? null
            : _save,
        style: FilledButton.styleFrom(
          backgroundColor: _color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.save_rounded,
              ),
        label: Text(
          _loading
              ? 'Menyimpan...'
              : _isEditing
                  ? 'Simpan Perubahan'
                  : 'Simpan Data',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty || _loading,
      onPopInvokedWithResult:
          (didPop, result) async {
        if (didPop) return;

        final discard =
            await _confirmDiscard();

        if (discard && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor:
            const Color(0xFFF4F7FB),

        appBar: AppBar(
          title: Text(
            _isEditing
                ? 'Edit Data'
                : 'Tambah Data',
          ),
          backgroundColor:
              Colors.white,
          foregroundColor: _ink,
          elevation: 0,
          scrolledUnderElevation: 0.5,
        ),

        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(18),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior
                      .onDrag,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 620,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [

                      // HEADER
                      _header(),

                      const SizedBox(
                        height: 16,
                      ),

                      // JENIS DATA
                      _card(
                        children: [
                          _sectionTitle(
                            'Jenis Data',
                            Icons.category_outlined,
                          ),

                          _typeSelector(),

                          if (_isEditing)
                            const Padding(
                              padding:
                                  EdgeInsets.only(
                                top: 8,
                              ),
                              child: Text(
                                'Jenis data tidak dapat diubah saat mengedit.',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // INFORMASI UTAMA
                      _card(
                        children: [
                          _sectionTitle(
                            'Informasi Utama',
                            Icons.edit_note_rounded,
                          ),

                          TextFormField(
                            controller:
                                _nameController,
                            textCapitalization:
                                TextCapitalization
                                    .words,
                            textInputAction:
                                TextInputAction.next,
                            maxLength: 60,
                            decoration:
                                _decoration(
                              'Nama Data',
                              _isTask
                                  ? 'Contoh: Tugas UI Login Screen'
                                  : 'Contoh: ASUS VivoBook 14',
                              Icons.edit_note_rounded,
                            ).copyWith(
                              counterText: '',
                            ),
                            validator:
                                (value) {
                              if (value ==
                                      null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return 'Nama data wajib diisi.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          DropdownButtonFormField<
                              String>(
                            key: ValueKey(
                              'category-$_type',
                            ),
                            initialValue: _category,
                            isExpanded: true,
                            decoration:
                                _decoration(
                              'Kategori',
                              'Pilih kategori',
                              Icons.widgets_outlined,
                            ),
                            items: _categories
                                .map(
                              (value) {
                                return DropdownMenuItem<
                                    String>(
                                  value: value,
                                  child: Text(
                                    value,
                                  ),
                                );
                              },
                            ).toList(),
                            onChanged:
                                (value) {
                              if (value !=
                                  null) {
                                setState(
                                  () {
                                    _category =
                                        value;
                                  },
                                );
                              }
                            },
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                                  FontWeight.w700,
                              color: _muted,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          if (!widget.user.canChangeStatus)
                            _lockedStatusInfo()
                          else if (_isAssignedTask)
                            _assignedInfo()
                          else
                            _statusChips(),
                        ],
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // DETAIL
                      _card(
                        children: [
                          _sectionTitle(
                            'Detail',
                            Icons.notes_rounded,
                          ),

                          TextFormField(
                            controller:
                                _descriptionController,
                            maxLines: 3,
                            maxLength: 250,
                            textCapitalization:
                                TextCapitalization
                                    .sentences,
                            decoration:
                                _decoration(
                              'Deskripsi',
                              'Tambahkan keterangan data',
                              Icons.notes_rounded,
                            ),
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          if (!_isTask) ...[
                            TextFormField(
                              controller:
                                  _locationController,
                              textInputAction:
                                  TextInputAction.next,
                              textCapitalization:
                                  TextCapitalization
                                      .words,
                              decoration:
                                  _decoration(
                                'Lokasi',
                                'Contoh: Lab PPLG',
                                Icons
                                    .location_on_outlined,
                              ),
                            ),

                            const SizedBox(
                              height: 16,
                            ),
                          ],

                          TextFormField(
                            controller:
                                _picController,
                            textInputAction:
                                TextInputAction.done,
                            textCapitalization:
                                TextCapitalization
                                    .words,
                            decoration:
                                _decoration(
                              'PIC / Penanggung Jawab',
                              'Nama penanggung jawab',
                              Icons
                                  .person_outline_rounded,
                            ),
                          ),

                          if (_isTask) ...[
                            const SizedBox(
                              height: 16,
                            ),
                            _deadlineField(),
                          ],
                        ],
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // SIMPAN
                      _saveButton(),

                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FORM PENGUMPULAN TUGAS (dibuka dari tombol "Kumpulkan" di user)
// ============================================================

// Form pengumpulan tugas (dibuka saat user menekan "Kumpulkan").
// Hasilnya berupa Map dengan kunci: title, note, link.
class SubmitTaskScreen extends StatefulWidget {
  final ItemModel task;
  final UserAccount user;

  const SubmitTaskScreen({
    super.key,
    required this.task,
    required this.user,
  });

  @override
  State<SubmitTaskScreen> createState() => _SubmitTaskScreenState();
}

class _SubmitTaskScreenState extends State<SubmitTaskScreen> {
  static const Color _ink = Color(0xFF172B4D);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _fill = Color(0xFFF7F9FC);
  static const Color _red = Color(0xFFDC2626);
  static const Color _green = Color(0xFF0F9D85);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(context, <String, String>{
      'title': _titleController.text.trim(),
      'note': _noteController.text.trim(),
      'link': _linkController.text.trim(),
    });
  }

  InputDecoration _decoration(String label, String hint, IconData icon) {
    OutlineInputBorder outline(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 21),
      filled: true,
      fillColor: _fill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: outline(_border),
      enabledBorder: outline(_border),
      focusedBorder: outline(_green, 1.6),
      errorBorder: outline(_red),
      focusedErrorBorder: outline(_red, 1.6),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _ink.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _header() {
    final task = widget.task;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [_green, _green.withAlpha(190)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.upload_file_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tugas yang dikumpulkan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  task.nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${task.kode} • Deadline ${task.deadlineLabel}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
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

  @override
  Widget build(BuildContext context) {
    final desc = widget.task.deskripsi.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Kumpulkan Tugas'),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _card(
                        children: [
                          const Text(
                            'Perintah tugas',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            desc,
                            style: const TextStyle(
                              color: _muted,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    _card(
                      children: [
                        const Text(
                          'Isi Pengumpulan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _titleController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          maxLength: 80,
                          decoration: _decoration(
                            'Tugas yang dikumpulkan',
                            'Contoh: Login Screen Flutter',
                            Icons.assignment_rounded,
                          ).copyWith(counterText: ''),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Isi tugas yang dikumpulkan.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _noteController,
                          maxLines: 4,
                          maxLength: 300,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _decoration(
                            'Keterangan',
                            'Jelaskan hasil pekerjaanmu',
                            Icons.notes_rounded,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Keterangan wajib diisi.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _linkController,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          textInputAction: TextInputAction.done,
                          decoration: _decoration(
                            'Link hasil (opsional)',
                            'Contoh: link GitHub / Google Drive',
                            Icons.link_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _green.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _green.withAlpha(70)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: _green,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Setelah dikumpulkan, status tetap Pending '
                              'sampai Admin selesai mengoreksi.',
                              style: TextStyle(
                                color: _green,
                                fontSize: 12.5,
                                height: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.upload_rounded),
                        label: const Text(
                          'Kumpulkan Tugas',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
