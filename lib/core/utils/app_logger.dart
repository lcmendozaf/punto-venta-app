import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

class AppLogger {
  static File? _file;
  static String logPath = '';
  static bool _stdoutUsable = false;
  static Timer? _heartbeat;

  static Future<void> init() async {
    final candidates = <File>[
      File('${Directory.systemTemp.path}${Platform.pathSeparator}punto_venta_app.log'),
      File(
        '${File(Platform.resolvedExecutable).parent.path}${Platform.pathSeparator}punto_venta_app.log',
      ),
    ];

    for (final candidate in candidates) {
      try {
        await candidate.writeAsString(
          '\n===== sesión ${DateTime.now().toIso8601String()} =====\n',
          mode: FileMode.append,
          flush: true,
        );
        _file = candidate;
        logPath = candidate.path;
        break;
      } catch (_) {
        continue;
      }
    }

    // En builds release sin consola adjunta, escribir a stdout lanza
    // FileSystemException asíncrona (handle inválido).
    try {
      _stdoutUsable = stdout.hasTerminal;
    } catch (_) {
      _stdoutUsable = false;
    }

    info('Logger iniciado. Archivo: ${logPath.isEmpty ? '(solo consola)' : logPath}');
  }

  /// Latido periódico: si el log se corta sin más latidos, el proceso murió
  /// (crash nativo). Si los latidos siguen, la app quedó colgada.
  static void startHeartbeat({Duration interval = const Duration(seconds: 5)}) {
    _heartbeat?.cancel();
    /*_heartbeat = Timer.periodic(interval, (timer) {
      _write('BEAT', 'app viva (${timer.tick * interval.inSeconds}s)');
    });*/
  }

  static void stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  static void info(String message) => _write('INFO', message);

  static void warn(String message) => _write('WARN', message);

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _write('ERROR', message);
    if (error != null) {
      _write('ERROR', 'detalle: $error');
    }
    if (stackTrace != null) {
      _write('ERROR', stackTrace.toString());
    }
  }

  static void _write(String level, String message) {
    final line = '[${DateTime.now().toIso8601String()}] [$level] $message';
    debugPrint(line);
    if (_stdoutUsable) {
      try {
        stdout.writeln(line);
      } catch (_) {}
    }
    try {
      _file?.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }
}
