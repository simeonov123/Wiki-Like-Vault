// lib/presentation/providers/entry_bg_provider.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final entryBgProvider =
    StateNotifierProvider<EntryBgNotifier, File?>((ref) {
  final notifier = EntryBgNotifier();
  notifier.loadFromPrefs();
  return notifier;
});

class EntryBgNotifier extends StateNotifier<File?> {
  EntryBgNotifier() : super(null);

  static const _prefsKey = 'entry_bg_path';

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefsKey);
    if (path != null) {
      final f = File(path);
      if (await f.exists()) {
        state = f;
      } else {
        await prefs.remove(_prefsKey);
        state = null;
      }
    }
  }

  Future<void> setBackgroundFromPath(String sourcePath) async {
    final src = File(sourcePath);
    if (!await src.exists()) return;

    // 1️⃣ Update state immediately so UI refreshes
    state = src;

    final prefs = await SharedPreferences.getInstance();
    final oldPath = prefs.getString(_prefsKey);

    final docsDir = await getApplicationDocumentsDirectory();
    await Directory(docsDir.path).create(recursive: true);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destPath = '${docsDir.path}/entry_bg_$timestamp.jpg';
    final dest = await src.copy(destPath);

    // 2️⃣ Persist new path
    await prefs.setString(_prefsKey, dest.path);

    // 3️⃣ Delete old saved file if different
    if (oldPath != null && oldPath != dest.path) {
      final oldFile = File(oldPath);
      if (await oldFile.exists()) {
        try { await oldFile.delete(); } catch (_) {}
      }
    }

    // 4️⃣ Ensure state points to saved file for persistence
    state = dest;
  }

  Future<void> clearBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_prefsKey);
    if (path != null) {
      final f = File(path);
      if (await f.exists()) {
        try { await f.delete(); } catch (_) {}
      }
      await prefs.remove(_prefsKey);
    }
    state = null;
  }
}
