import 'package:aplikasi/screens/history/history_page.dart';
import 'package:aplikasi/screens/home/home_page.dart';
import 'package:aplikasi/screens/meds/medicine_page.dart';
import 'package:aplikasi/screens/profile/profile_page.dart';
import 'package:aplikasi/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return HomePage(
          onAddMedTap: () {
            setState(() {
              _selectedIndex = 2; // Navigate to Meds
            });
          },
          onHistoryTap: () {
            setState(() {
              _selectedIndex = 1; // Navigate to History
            });
          },
          onFamilyTap: () {
            setState(() {
              _selectedIndex = 3; // Navigate to Profile
            });
          },
        );
      case 1:
        return const HistoryPage();
      case 2:
        return const MedsPage();
      case 3:
        return const ProfilePage();
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          'JagaDosis',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppColors.medicalBlue,
          ),
        ),
      ),
      body: _getPage(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 16.0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.home_rounded,
                  Icons.home_outlined,
                  'Home',
                ),
                _buildNavItem(
                  1,
                  Icons.history_rounded,
                  Icons.history_outlined,
                  'History',
                ),
                _buildNavItem(
                  2,
                  Icons.medical_services_rounded,
                  Icons.medical_services_outlined,
                  'Meds',
                ),
                _buildNavItem(
                  3,
                  Icons.person_rounded,
                  Icons.person_outline_rounded,
                  'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final bool isActive = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryContainer.withAlpha(50)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppColors.medicalBlue : AppColors.textGrey,
              size: 24.0,
            ),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.0,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.medicalBlue : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
