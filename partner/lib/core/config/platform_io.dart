import 'dart:io' show Platform;

/// True on an Android host (emulator reaches the dev machine via 10.0.2.2).
bool get isAndroidHost => Platform.isAndroid;
