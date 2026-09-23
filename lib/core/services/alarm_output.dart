import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:window_manager/window_manager.dart';

/// Everything a firing alarm needs from the outside world: a looping sound and
/// the user's attention.
///
/// A seam at the I/O boundary, as `stack-appendices.md` §4 recommends for
/// third-party SDK calls. It also makes [AlarmSchedulerService] testable at
/// all: `just_audio` and `window_manager` both need platform channels, so
/// nothing about firing an alarm could be exercised before this existed.
abstract class AlarmOutput {
  /// Starts [path] looping. Throws if the file is missing or undecodable.
  Future<void> playLooping(String path);

  /// Stops any sound currently playing.
  Future<void> stop();

  /// Brings the app window forward, where the platform supports it.
  Future<void> bringToFront();

  Future<void> dispose();
}

/// Production implementation over `just_audio` and `window_manager`.
class PlatformAlarmOutput implements AlarmOutput {
  PlatformAlarmOutput({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> playLooping(String path) async {
    // Checked explicitly rather than relying on setFilePath to throw: an
    // audio file chosen months ago is routinely moved or deleted, and that
    // needs to read as "your sound is gone", not a generic decode failure.
    if (!await File(path).exists()) {
      throw FileSystemException('Alarm sound is missing', path);
    }
    await _player.setFilePath(path);
    await _player.setLoopMode(LoopMode.one);
    await _player.play();
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> bringToFront() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  Future<void> dispose() => _player.dispose();
}
