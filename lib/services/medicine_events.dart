import 'package:flutter/foundation.dart';

/// Bumped whenever a medicine's dose state changes from *outside* the widget
/// that currently owns the list — most notably when a dose is confirmed from
/// the full-screen alarm ring screen. Screens like HomePage listen to this and
/// reload, so the "jadwal terdekat" updates immediately without the user having
/// to switch bottom-navigation tabs to force a rebuild.
final ValueNotifier<int> medicineDataRevision = ValueNotifier<int>(0);

/// Signals that medicine/dose data changed and open screens should refresh.
void notifyMedicineDataChanged() => medicineDataRevision.value++;
