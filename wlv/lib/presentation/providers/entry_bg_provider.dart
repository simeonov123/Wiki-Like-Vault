// lib/presentation/providers/entry_bg_provider.dart
//
// Holds the image chosen as the Entries page background.
// (You can persist this later; for now it’s in-memory only.)

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `null`  → no custom background yet
/// `File` → image picked from gallery
final entryBgProvider = StateProvider<File?>((_) => null);
