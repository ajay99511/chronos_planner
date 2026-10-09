import 'dart:io';

import 'package:flutter/services.dart' show MissingPluginException;
import 'package:just_audio/just_audio.dart';
import 'package:window_manager/window_manager.dart';

/// Why a sound could not be heard.
///
/// Distinguished because the remedies differ entirely: the user can re-pick a
/// missing file, but there is nothing they can do about a platform with no
/// audio plugin, and telling them "the file may have moved" in that case sends
/// them looking for a problem that is not theirs.
enum SoundFailure {
  /// The configured file no longer exists.
  fileMissing,

  /// This platform has no audio implementation compiled in.
  ///
  /// `just_audio` declares android, ios, macos and web only — so on Windows and
  /// Linux, which this app also targets and where `window_manager` runs, any
  /// playback attempt fails with [MissingPluginException].
  unsupportedPlatform,

  /// Anything else: an unreadable codec, a device in use, a decode error.
  playbackFailed,
}

/// Thrown by [AlarmOutput.playLooping] when a sound cannot be played.
class SoundException implements Exception {
  const SoundException(this.reason, [this.cause]);

  final SoundFailure reason;
  final Object? cause;

  @override
  String toString() => 'SoundException(${reason.name})'
      '${cause == null ? '' : ': $cause'}';
}

/// True on platforms where `just_audio` has no implementation.
///
/// Checked up front rather than discovered by catching, so the app can tell a
/// user their sound will not play *before* they rely on it.
bool get audioSupportedOnThisPlatform =>
    !(Platform.isWindows || Platform.isLinux);

/// Everything a firing alarm needs from the outside world: a looping sound and
/// the user's attention.
///
/// A seam at the I/O boundary, as `stack-appendices.md` §4 recommends for
/// third-party SDK calls. It also makes [AlarmSchedulerService] testable at
/// all: `just_audio` and `window_manager` both need platform channels, so
/// nothing about firing an alarm could be exercised before this existed.
abstract class AlarmOutput {
  /// Starts [path] looping.
  ///
  /// Throws [SoundException] with a reason the caller can report.
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
    if (!audioSupportedOnThisPlatform) {
      throw const SoundException(SoundFailure.unsupportedPlatform);
    }
    // Checked explicitly rather than relying on setFilePath to throw: an audio
    // file chosen months ago is routinely moved or deleted, and that needs to
    // read as "your sound is gone" rather than a generic decode failure.
    if (!await File(path).exists()) {
      throw const SoundException(SoundFailure.fileMissing);
    }
    try {
      await _player.setFilePath(path);
      await _player.setLoopMode(LoopMode.one);
      await _player.play();
    } on MissingPluginException catch (e) {
      // Belt and braces: reachable if the platform list changes under us.
      throw SoundException(SoundFailure.unsupportedPlatform, e);
    } catch (e) {
      throw SoundException(SoundFailure.playbackFailed, e);
    }
  }

  @override
  Future<void> stop() async {
    // Nothing was ever started on an unsupported platform, and calling through
    // would throw MissingPluginException on the dismissal path.
    if (!audioSupportedOnThisPlatform) return;
    await _player.stop();
  }

  @override
  Future<void> bringToFront() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  Future<void> dispose() => _player.dispose();
}
