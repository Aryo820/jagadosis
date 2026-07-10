import 'package:aplikasi/models/history_model.dart';
import 'package:aplikasi/repositories/history_repository.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum CalendarViewMode { weekly, monthly, yearly }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  final HistoryRepository _historyRepo = HistoryRepository();

  DateTime _selectedDate = DateTime.now();
  List<HistoryModel> _histories = [];
  bool _isLoading = true;
  int _weeklyAdherence = 0;
  CalendarViewMode _viewMode = CalendarViewMode.weekly;

  // Untuk navigasi kalender tampilan bulanan
  late DateTime _displayedMonth;
  // Untuk navigasi tampilan tahunan
  late int _displayedYear;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _displayedYear = _selectedDate.year;

    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();

    _loadHistory();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Memuat catatan riwayat sesuai mode tampilan yang sedang aktif.
  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      List<HistoryModel> logs;

      switch (_viewMode) {
        case CalendarViewMode.weekly:
          logs = await _historyRepo.getHistoriesByDate(_selectedDate);
          break;
        case CalendarViewMode.monthly:
          logs = await _historyRepo.getHistoriesByMonth(
            _displayedMonth.year,
            _displayedMonth.month,
          );
          break;
        case CalendarViewMode.yearly:
          logs = await _historyRepo.getHistoriesByYear(_displayedYear);
          break;
      }

      // Kepatuhan harus mencerminkan periode yang sedang ditampilkan (catatan
      // yang baru diambil untuk hari/bulan/tahun ini), bukan total sepanjang
      // waktu — kalau tidak, persentasenya tidak akan cocok dengan daftar yang
      // muncul tepat di bawahnya. Kalau tidak ada catatan di periode ini, tidak
      // ada kepatuhan yang bisa dihitung, jadi ditampilkan 0% bukan 100% yang
      // menyesatkan.
      final takenCount = logs.where((log) => log.status == 'taken').length;
      final totalCount = logs.length;

      // Halaman ini di-dispose saat pindah tab (dashboard memakai switch, bukan
      // IndexedStack). Bila load masih berjalan ketika user meninggalkan tab
      // History, setState/_animController di sini akan menyentuh State yang sudah
      // mati dan melempar exception. Guard mounted mencegahnya.
      if (!mounted) return;
      setState(() {
        _histories = logs;
        _weeklyAdherence = totalCount == 0
            ? 0
            : ((takenCount / totalCount) * 100).round();
        _isLoading = false;
      });

      // Mulai ulang animasi fade
      _animController.reset();
      _animController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Fungsi bantu untuk menghitung tanggal secara dinamis
  List<DateTime> _getWeekDays() {
    // Patokan minggunya adalah tanggal yang dipilih, bukan "hari ini": saat
    // berpindah dari tampilan bulanan ke tanggal lampau, strip minggu harus
    // menampilkan minggu tanggal tersebut, sesuai catatan yang dimuat untuknya.
    final monday = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  String _getDayName(int weekday) {
    const names = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return names[weekday % 7];
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  String _getShortMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }

  String _getMonthYearName(DateTime date) {
    return '${_getMonthName(date.month)} ${date.year}';
  }

  String _getFormattedDay(DateTime date) {
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    return '${days[date.weekday % 7]}, ${date.day} ${_getMonthName(date.month)}';
  }

  void _switchViewMode(CalendarViewMode mode) {
    if (_viewMode == mode) return;
    setState(() {
      _viewMode = mode;
    });
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu ringkasan kepatuhan
            _buildAdherenceCard(),
            const SizedBox(height: 24.0),

            // Tombol pengalih mode tampilan
            _buildViewModeToggle(),
            const SizedBox(height: 16.0),

            // Bagian kalender sesuai mode tampilan
            _buildCalendarSection(),
            const SizedBox(height: 24.0),

            // Bagian data
            FadeTransition(opacity: _fadeAnim, child: _buildDataSection()),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TOMBOL PENGALIH MODE TAMPILAN
  // ==========================================

  Widget _buildViewModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(80)),
      ),
      child: Row(
        children: [
          _buildToggleButton('Mingguan', CalendarViewMode.weekly),
          _buildToggleButton('Bulanan', CalendarViewMode.monthly),
          _buildToggleButton('Tahunan', CalendarViewMode.yearly),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, CalendarViewMode mode) {
    final isActive = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchViewMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: isActive ? AppColors.medicalBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.medicalBlue.withAlpha(40),
                      blurRadius: 8.0,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // BAGIAN KALENDER

  Widget _buildCalendarSection() {
    switch (_viewMode) {
      case CalendarViewMode.weekly:
        return _buildWeeklyCalendar();
      case CalendarViewMode.monthly:
        return _buildMonthlyCalendar();
      case CalendarViewMode.yearly:
        return _buildYearlyCalendar();
    }
  }

  // --- MINGGUAN ---
  Widget _buildWeeklyCalendar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getMonthYearName(_selectedDate),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: AppColors.textDark,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime.now();
                });
                _loadHistory();
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 16.0),
              label: Text(
                'Hari Ini',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.medicalBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _getWeekDays().map((date) {
              final isSameDay =
                  date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                  _loadHistory();
                },
                child: _buildCalendarDay(
                  _getDayName(date.weekday),
                  date.day.toString(),
                  isActive: isSameDay,
                  isFuture: date.isAfter(DateTime.now()),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- BULANAN ---
  Widget _buildMonthlyCalendar() {
    final now = DateTime.now();
    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    ).weekday;
    // Senin = 1, Minggu = 7. Kita ingin Senin sebagai kolom pertama.
    final leadingBlanks = firstWeekday - 1;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bagian atas untuk navigasi bulan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _displayedMonth = DateTime(
                      _displayedMonth.year,
                      _displayedMonth.month - 1,
                    );
                  });
                  _loadHistory();
                },
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.textDark,
                ),
                splashRadius: 20.0,
              ),
              Text(
                _getMonthYearName(_displayedMonth),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: AppColors.textDark,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _displayedMonth = DateTime(
                      _displayedMonth.year,
                      _displayedMonth.month + 1,
                    );
                  });
                  _loadHistory();
                },
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textDark,
                ),
                splashRadius: 20.0,
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // Judul nama-nama hari
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                .map(
                  (d) => SizedBox(
                    width: 36.0,
                    child: Center(
                      child: Text(
                        d,
                        style: GoogleFonts.inter(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8.0),

          // Grid kalender
          ...List.generate(((leadingBlanks + daysInMonth) / 7).ceil(), (
            weekIndex,
          ) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (dayIndex) {
                  final cellIndex = weekIndex * 7 + dayIndex;
                  final dayNum = cellIndex - leadingBlanks + 1;

                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const SizedBox(width: 36.0, height: 36.0);
                  }

                  final cellDate = DateTime(
                    _displayedMonth.year,
                    _displayedMonth.month,
                    dayNum,
                  );
                  final isToday =
                      cellDate.year == now.year &&
                      cellDate.month == now.month &&
                      cellDate.day == now.day;
                  final isSelected =
                      cellDate.year == _selectedDate.year &&
                      cellDate.month == _selectedDate.month &&
                      cellDate.day == _selectedDate.day;
                  final isFuture = cellDate.isAfter(now);

                  // Cek apakah tanggal ini punya catatan
                  final hasLogs = _histories.any(
                    (h) =>
                        h.takenAt.year == cellDate.year &&
                        h.takenAt.month == cellDate.month &&
                        h.takenAt.day == cellDate.day,
                  );

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = cellDate;
                        // Beralih ke mode mingguan untuk menampilkan detail harian
                        _viewMode = CalendarViewMode.weekly;
                      });
                      _loadHistory();
                    },
                    child: Container(
                      width: 36.0,
                      height: 36.0,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.medicalBlue
                            : isToday
                            ? AppColors.medicalBlue.withAlpha(20)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNum.toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.0,
                              fontWeight: isToday || isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : isFuture
                                  ? AppColors.textDark.withAlpha(100)
                                  : isToday
                                  ? AppColors.medicalBlue
                                  : AppColors.textDark,
                            ),
                          ),
                          if (hasLogs && !isSelected)
                            Container(
                              width: 4.0,
                              height: 4.0,
                              margin: const EdgeInsets.only(top: 2.0),
                              decoration: const BoxDecoration(
                                color: AppColors.wellnessGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- TAHUNAN ---
  Widget _buildYearlyCalendar() {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bagian atas untuk navigasi tahun
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _displayedYear--;
                  });
                  _loadHistory();
                },
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.textDark,
                ),
                splashRadius: 20.0,
              ),
              Text(
                '$_displayedYear',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                  color: AppColors.textDark,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _displayedYear++;
                  });
                  _loadHistory();
                },
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textDark,
                ),
                splashRadius: 20.0,
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Grid 12 bulan (4 kolom x 3 baris)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 1.4,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isCurrentMonth =
                  _displayedYear == now.year && month == now.month;
              final isFutureMonth =
                  _displayedYear > now.year ||
                  (_displayedYear == now.year && month > now.month);

              // Hitung jumlah catatan untuk bulan ini
              final monthLogCount = _histories
                  .where(
                    (h) =>
                        h.takenAt.year == _displayedYear &&
                        h.takenAt.month == month,
                  )
                  .length;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _displayedMonth = DateTime(_displayedYear, month);
                    _viewMode = CalendarViewMode.monthly;
                  });
                  _loadHistory();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isCurrentMonth
                        ? AppColors.medicalBlue.withAlpha(20)
                        : AppColors.backgroundBlue,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isCurrentMonth
                          ? AppColors.medicalBlue
                          : AppColors.outlineVariant.withAlpha(60),
                      width: isCurrentMonth ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getShortMonthName(month),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.0,
                          fontWeight: isCurrentMonth
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isFutureMonth
                              ? AppColors.textDark.withAlpha(100)
                              : isCurrentMonth
                              ? AppColors.medicalBlue
                              : AppColors.textDark,
                        ),
                      ),
                      if (monthLogCount > 0) ...[
                        const SizedBox(height: 2.0),
                        Text(
                          '$monthLogCount',
                          style: GoogleFonts.inter(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.wellnessGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // BAGIAN DATA
  Widget _buildDataSection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: CircularProgressIndicator(color: AppColors.medicalBlue),
        ),
      );
    }

    switch (_viewMode) {
      case CalendarViewMode.weekly:
        return _buildDailyLogSection();
      case CalendarViewMode.monthly:
        return _buildGroupedLogSection(
          '${_getMonthName(_displayedMonth.month)} ${_displayedMonth.year}',
        );
      case CalendarViewMode.yearly:
        return _buildGroupedLogSection('Tahun $_displayedYear');
    }
  }

  // --- Catatan harian (mode mingguan) ---
  Widget _buildDailyLogSection() {
    final List<HistoryModel> morningLogs = [];
    final List<HistoryModel> afternoonLogs = [];
    final List<HistoryModel> nightLogs = [];

    for (final log in _histories) {
      final hour = log.takenAt.hour;
      if (hour >= 5 && hour < 12) {
        morningLogs.add(log);
      } else if (hour >= 12 && hour < 18) {
        afternoonLogs.add(log);
      } else {
        nightLogs.add(log);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getFormattedDay(_selectedDate),
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16.0),
        if (_histories.isEmpty)
          _buildEmptyState()
        else ...[
          if (morningLogs.isNotEmpty) ...[
            _buildTimeGroupHeader(
              'Pagi',
              Icons.wb_sunny_rounded,
              const Color(0xFFE65100),
            ),
            const SizedBox(height: 8.0),
            ...morningLogs.map((log) => _buildHistoryCard(log)),
            const SizedBox(height: 16.0),
          ],
          if (afternoonLogs.isNotEmpty) ...[
            _buildTimeGroupHeader(
              'Siang',
              Icons.wb_cloudy_rounded,
              AppColors.medicalBlue,
            ),
            const SizedBox(height: 8.0),
            ...afternoonLogs.map((log) => _buildHistoryCard(log)),
            const SizedBox(height: 16.0),
          ],
          if (nightLogs.isNotEmpty) ...[
            _buildTimeGroupHeader(
              'Malam',
              Icons.bedtime_rounded,
              AppColors.textGrey,
            ),
            const SizedBox(height: 8.0),
            ...nightLogs.map((log) => _buildHistoryCard(log)),
            const SizedBox(height: 24.0),
          ],
        ],
      ],
    );
  }

  // --- Catatan yang dikelompokkan (mode bulanan/tahunan) ---
  Widget _buildGroupedLogSection(String periodTitle) {
    if (_histories.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            periodTitle,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16.0),
          _buildEmptyState(),
        ],
      );
    }

    // Kelompokkan riwayat berdasarkan tanggal
    final Map<String, List<HistoryModel>> grouped = {};
    for (final log in _histories) {
      final dateKey =
          '${log.takenAt.year}-${log.takenAt.month.toString().padLeft(2, '0')}-${log.takenAt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(dateKey, () => []).add(log);
    }

    // Urutkan kunci tanggal dari yang terbaru ke terlama
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              periodTitle,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: AppColors.textDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.medicalBlue.withAlpha(20),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                '${_histories.length} catatan',
                style: GoogleFonts.inter(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.medicalBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        ...sortedKeys.map((dateKey) {
          final logs = grouped[dateKey]!;
          final date = DateTime.parse(dateKey);
          return _buildDateGroupCard(date, logs);
        }),
      ],
    );
  }

  Widget _buildDateGroupCard(DateTime date, List<HistoryModel> logs) {
    final takenCount = logs.where((l) => l.status == 'taken').length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian atas berisi tanggal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32.0,
                    height: 32.0,
                    decoration: BoxDecoration(
                      color: AppColors.medicalBlue.withAlpha(20),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text(
                        date.day.toString(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.medicalBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFormattedDay(date),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '$takenCount/${logs.length} diminum',
                        style: GoogleFonts.inter(
                          fontSize: 11.0,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Indikator kecil status kepatuhan
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: takenCount == logs.length
                      ? AppColors.wellnessGreen.withAlpha(20)
                      : const Color(0xFFEB5757).withAlpha(20),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  takenCount == logs.length ? 'Lengkap' : 'Tidak Lengkap',
                  style: GoogleFonts.inter(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                    color: takenCount == logs.length
                        ? AppColors.wellnessGreen
                        : const Color(0xFFEB5757),
                  ),
                ),
              ),
            ],
          ),
          if (logs.isNotEmpty) ...[
            const SizedBox(height: 12.0),
            const Divider(height: 1.0, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12.0),
            // Daftar obat untuk hari tersebut
            ...logs.map((log) {
              final timeString =
                  '${log.takenAt.hour.toString().padLeft(2, '0')}:${log.takenAt.minute.toString().padLeft(2, '0')}';
              final isTaken = log.status == 'taken';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(
                      isTaken
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: isTaken
                          ? AppColors.wellnessGreen
                          : const Color(0xFFEB5757),
                      size: 20.0,
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        log.medicineName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Text(
                      timeString,
                      style: GoogleFonts.inter(
                        fontSize: 11.0,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // KARTU KEPATUHAN
  // ==========================================

  Widget _buildAdherenceCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kepatuhan Total',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                'Kerja bagus menjaga kesehatan!',
                style: GoogleFonts.inter(
                  fontSize: 12.0,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8.0),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$_weeklyAdherence% ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.medicalBlue,
                      ),
                    ),
                    TextSpan(
                      text: 'Diminum tepat waktu',
                      style: GoogleFonts.inter(
                        fontSize: 12.0,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            width: 56.0,
            height: 56.0,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 50.0,
                    height: 50.0,
                    child: CircularProgressIndicator(
                      value: _weeklyAdherence / 100.0,
                      backgroundColor: AppColors.outlineVariant.withAlpha(60),
                      color: AppColors.wellnessGreen,
                      strokeWidth: 5.0,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '$_weeklyAdherence%',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                      color: AppColors.wellnessGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET BERSAMA
  // ==========================================

  Widget _buildEmptyState() {
    String message;
    switch (_viewMode) {
      case CalendarViewMode.weekly:
        message = 'Belum ada catatan konsumsi obat untuk hari ini.';
        break;
      case CalendarViewMode.monthly:
        message = 'Belum ada catatan konsumsi obat untuk bulan ini.';
        break;
      case CalendarViewMode.yearly:
        message = 'Belum ada catatan konsumsi obat untuk tahun ini.';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              size: 48.0,
              color: AppColors.textGrey,
            ),
            const SizedBox(height: 12.0),
            Text(
              'Tidak Ada Riwayat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12.0,
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(HistoryModel log) {
    final timeString =
        '${log.takenAt.hour.toString().padLeft(2, '0')}:${log.takenAt.minute.toString().padLeft(2, '0')}';
    final isMissed = log.status == 'missed';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: _buildLogCard(
        log.medicineName,
        isMissed ? 'Obat terlewat' : 'Obat diminum tepat waktu',
        log.status.toUpperCase(),
        timeString,
        isMissed ? const Color(0xFFEB5757) : AppColors.wellnessGreen,
        isMissed ? Icons.cancel_rounded : Icons.check_circle_rounded,
      ),
    );
  }


  Widget _buildCalendarDay(
    String dayName,
    String dayNumber, {
    bool isActive = false,
    bool isCompleted = false,
    bool isMissed = false,
    bool isFuture = false,
  }) {
    Color bg = AppColors.surfaceWhite;
    Color textColor = AppColors.textDark;
    Color subColor = AppColors.textGrey;

    if (isActive) {
      bg = AppColors.medicalBlue;
      textColor = AppColors.surfaceWhite;
      subColor = AppColors.surfaceWhite.withAlpha(200);
    } else if (isFuture) {
      textColor = AppColors.textDark.withAlpha(120);
      subColor = AppColors.textGrey.withAlpha(120);
    }

    return Container(
      width: 56.0,
      height: 72.0,
      margin: const EdgeInsets.only(right: 10.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isActive
              ? AppColors.medicalBlue
              : AppColors.outlineVariant.withAlpha(100),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.medicalBlue.withAlpha(60),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayName,
            style: GoogleFonts.inter(
              fontSize: 11.0,
              fontWeight: FontWeight.w500,
              color: subColor,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            dayNumber,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4.0),
          if (isCompleted)
            Container(
              width: 5.0,
              height: 5.0,
              decoration: const BoxDecoration(
                color: AppColors.wellnessGreen,
                shape: BoxShape.circle,
              ),
            )
          else if (isMissed)
            Container(
              width: 5.0,
              height: 5.0,
              decoration: const BoxDecoration(
                color: Color(0xFFEB5757),
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(height: 5.0),
        ],
      ),
    );
  }

  Widget _buildTimeGroupHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18.0),
        const SizedBox(width: 6.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10.0,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard(
    String title,
    String dosage,
    String status,
    String time,
    Color color,
    IconData icon, {
    bool isFuture = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.outlineVariant.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: isFuture
                        ? AppColors.textDark.withAlpha(150)
                        : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  dosage,
                  style: GoogleFonts.inter(
                    fontSize: 12.0,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                  color: color,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                time,
                style: GoogleFonts.inter(
                  fontSize: 11.0,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
