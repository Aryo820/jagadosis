import 'package:aplikasi/models/history_model.dart';
import 'package:aplikasi/repositories/history_repository.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final HistoryRepository _historyRepo = HistoryRepository();

  DateTime _selectedDate = DateTime.now();
  List<HistoryModel> _histories = [];
  bool _isLoading = true;
  int _weeklyAdherence = 100;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Loads the history logs for the selected date and calculates general compliance rate.
  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final dayLogs = await _historyRepo.getHistoriesByDate(_selectedDate);
      final allLogs = await _historyRepo.getAllHistories();

      // Simple weekly compliance calculation: count of taken logs out of total logs
      final takenCount = allLogs.where((log) => log.status == 'taken').length;
      final totalCount = allLogs.length;

      setState(() {
        _histories = dayLogs;
        _weeklyAdherence = totalCount == 0 ? 100 : ((takenCount / totalCount) * 100).round();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Helpers for dynamic dates
  List<DateTime> _getWeekDays() {
    final now = DateTime.now();
    // Start from Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  String _getDayName(int weekday) {
    const names = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return names[weekday % 7];
  }

  String _getMonthYearName(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getFormattedDay(DateTime date) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    // Categorize logs by time of day
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

    return Scaffold(
      backgroundColor: AppColors.backgroundBlue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Adherence summary card
            Container(
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
                  // Progress indicator circular
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
            ),
            const SizedBox(height: 24.0),

            // Horizontal calendar section
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
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),

            // Calendar Strip
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _getWeekDays().map((date) {
                  final isSameDay = date.year == _selectedDate.year &&
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
            const SizedBox(height: 24.0),

            // Daily Log Section
            Text(
              _getFormattedDay(_selectedDate),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16.0),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: CircularProgressIndicator(
                    color: AppColors.medicalBlue,
                  ),
                ),
              )
            else if (_histories.isEmpty)
              _buildEmptyState()
            else ...[
              if (morningLogs.isNotEmpty) ...[
                _buildTimeGroupHeader('Pagi', Icons.wb_sunny_rounded, const Color(0xFFE65100)),
                const SizedBox(height: 8.0),
                ...morningLogs.map((log) => _buildHistoryCard(log)),
                const SizedBox(height: 16.0),
              ],
              if (afternoonLogs.isNotEmpty) ...[
                _buildTimeGroupHeader('Siang', Icons.wb_cloudy_rounded, AppColors.medicalBlue),
                const SizedBox(height: 8.0),
                ...afternoonLogs.map((log) => _buildHistoryCard(log)),
                const SizedBox(height: 16.0),
              ],
              if (nightLogs.isNotEmpty) ...[
                _buildTimeGroupHeader('Malam', Icons.bedtime_rounded, AppColors.textGrey),
                const SizedBox(height: 8.0),
                ...nightLogs.map((log) => _buildHistoryCard(log)),
                const SizedBox(height: 24.0),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              'Belum ada catatan konsumsi obat untuk hari ini.',
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
    final timeString = '${log.takenAt.hour.toString().padLeft(2, '0')}:${log.takenAt.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: _buildLogCard(
        log.medicineName,
        'Obat diminum tepat waktu',
        log.status.toUpperCase(),
        timeString,
        AppColors.wellnessGreen,
        Icons.check_circle_rounded,
      ),
    );
  }

  Widget _buildCalendarDay(String dayName, String dayNumber,
      {bool isActive = false, bool isCompleted = false, bool isMissed = false, bool isFuture = false}) {
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
          color: isActive ? AppColors.medicalBlue : AppColors.outlineVariant.withAlpha(100),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.medicalBlue.withAlpha(60),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                )
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

  Widget _buildLogCard(String title, String dosage, String status, String time, Color color, IconData icon,
      {bool isFuture = false}) {
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
                    color: isFuture ? AppColors.textDark.withAlpha(150) : AppColors.textDark,
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
