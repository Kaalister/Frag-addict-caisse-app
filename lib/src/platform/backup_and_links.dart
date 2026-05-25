part of '../../main.dart';

Future<void> copyBackup(BuildContext context, AppController controller) async {
  try {
    final payload = await controller.fullBackupPayload();
    final content = const JsonEncoder.withIndent('  ').convert(payload);
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final fileName = 'frags-addicts-export-$timestamp.json';
    final savedFile = await _saveJsonBackupFile(fileName, content);
    final name = savedFile['name'] ?? fileName;
    if (context.mounted) {
      snack(context, 'Export enregistré dans Downloads : $name');
    }
  } on PlatformException catch (error) {
    if (context.mounted) {
      snack(context, 'Export impossible : ${error.message ?? error.code}');
    }
  } catch (error) {
    if (context.mounted) snack(context, 'Export impossible : $error');
  }
}

Future<Map<String, String>> saveRecoveryBackup(
    AppController controller, String operation) async {
  final payload = await controller.fullBackupPayload();
  final content = const JsonEncoder.withIndent('  ').convert(payload);
  final timestamp =
      DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
  return _saveJsonBackupFile(
      'frags-addicts-avant-$operation-$timestamp.json', content);
}

const _fileImportChannel = MethodChannel('frags_addicts/file_import');

Future<Map<String, String>> _saveJsonBackupFile(
    String fileName, String content) async {
  if (Platform.isAndroid) {
    final savedFile = await _fileImportChannel.invokeMapMethod<String, String>(
      'saveJsonBackup',
      {'name': fileName, 'content': content},
    );
    return savedFile ?? {'name': fileName};
  }

  final downloads = await getDownloadsDirectory();
  final directory = downloads ?? Directory.current;
  final safeName = _safeJsonFileName(fileName);
  final file = File(path.join(directory.path, safeName));
  await file.writeAsString(content, encoding: utf8, flush: true);
  return {'name': safeName, 'path': file.path};
}

String _safeJsonFileName(String name) {
  final baseName = name
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'^[-._]+|[-._]+$'), '');
  final safe = baseName.isEmpty ? 'frags-addicts-export.json' : baseName;
  return safe.toLowerCase().endsWith('.json') ? safe : '$safe.json';
}

Future<void> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) {
    throw const FormatException('Lien de mise à jour invalide');
  }

  if (Platform.isAndroid) {
    await _fileImportChannel.invokeMethod('openUrl', {'url': url});
    return;
  }

  if (Platform.isWindows) {
    await Process.run('cmd', ['/c', 'start', '', url]);
    return;
  }

  if (Platform.isMacOS) {
    await Process.run('open', [url]);
    return;
  }

  if (Platform.isLinux) {
    await Process.run('xdg-open', [url]);
    return;
  }

  throw UnsupportedError('Ouverture du lien non supportée');
}

Future<void> importBackupFromFile(
    BuildContext context, AppController controller) async {
  try {
    final file = await _pickJsonBackupFile();
    if (file == null) return;

    final content = _stripUtf8Bom(file['content']);
    final name = file['name'] ?? 'sauvegarde.json';
    if (content == null || content.trim().isEmpty) {
      throw const FormatException('Fichier vide ou illisible');
    }

    final payload = jsonDecode(content);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Format JSON invalide');
    }
    if (!context.mounted) return;
    final ok = await confirm(context,
        'Restaurer $name ? Toutes les données locales seront remplacées.');
    if (!ok) return;
    final recoveryFile = await saveRecoveryBackup(controller, 'restauration');
    await controller.importBackup(payload);
    if (context.mounted) {
      snack(context,
          'Sauvegarde restauree. Copie precedente : ${recoveryFile['name']}');
    }
  } on PlatformException catch (error) {
    if (context.mounted) {
      snack(context, 'Import impossible : ${error.message ?? error.code}');
    }
  } catch (error) {
    if (context.mounted) snack(context, 'Import impossible : $error');
  }
}

Future<Map<String, String>?> _pickJsonBackupFile() async {
  if (Platform.isAndroid) {
    return _fileImportChannel.invokeMapMethod<String, String>('pickJsonBackup');
  }

  if (Platform.isWindows) {
    return _pickJsonBackupFileWindows();
  }

  throw UnsupportedError(
      'Import de sauvegarde non supporté sur cette plateforme');
}

Future<Map<String, String>?> _pickJsonBackupFileWindows() async {
  const script = r'''
Add-Type -AssemblyName System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Title = 'Choisir une sauvegarde Frags Addicts'
$dialog.Filter = 'Sauvegardes JSON (*.json)|*.json|Tous les fichiers (*.*)|*.*'
$dialog.Multiselect = $false
if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  Write-Output $dialog.FileName
}
''';

  final result = await Process.run(
    'powershell.exe',
    ['-NoProfile', '-Sta', '-ExecutionPolicy', 'Bypass', '-Command', script],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    final message = '${result.stderr}'.trim();
    throw PlatformException(
      code: 'picker_unavailable',
      message: message.isEmpty
          ? 'Impossible d\'ouvrir le sélecteur de fichier.'
          : message,
    );
  }

  final selectedPath = _lastNonEmptyLine('${result.stdout}');
  if (selectedPath == null) return null;

  final file = File(selectedPath);
  final content = await file.readAsString(encoding: utf8);
  return {'name': path.basename(file.path), 'content': content};
}

String? _stripUtf8Bom(String? content) {
  if (content == null) return null;
  return content.startsWith('\uFEFF') ? content.substring(1) : content;
}

String? _lastNonEmptyLine(String value) {
  String? last;
  for (final line in value.split(RegExp(r'\r?\n'))) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) last = trimmed;
  }
  return last;
}

Future<bool> confirm(BuildContext context, String message) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmation'),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmer')),
          ],
        ),
      ) ??
      false;
}

void snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
