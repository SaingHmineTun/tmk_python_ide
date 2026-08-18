import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../models/python_program.dart';

class ProgramFileService {
  Future<({String name, String code})?> importPython() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['py'],
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return (
      name: p.basenameWithoutExtension(file.name),
      code: utf8.decode(bytes),
    );
  }

  Future<void> shareFile(PythonProgram program) async {
    final safeName = _safeFileName(program.name);
    final bytes = Uint8List.fromList(utf8.encode(program.code));
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'text/x-python',
            name: '$safeName.py',
          ),
        ],
        text: program.name,
      ),
    );
  }

  Future<void> shareText(PythonProgram program) => SharePlus.instance.share(
    ShareParams(text: program.code, subject: program.name),
  );

  Future<Uri?> exportFile(PythonProgram program) async {
    final bytes = Uint8List.fromList(utf8.encode(program.code));
    return FilePicker.saveFile(
      dialogTitle: 'Export Python file',
      fileName: '${_safeFileName(program.name)}.py',
      type: FileType.custom,
      allowedExtensions: const ['py'],
      bytes: bytes,
    );
  }

  String _safeFileName(String name) {
    final value = name
        .trim()
        .replaceAll(RegExp(r'[^\w\-. ]', unicode: true), '_')
        .replaceAll(' ', '_');
    return value.isEmpty ? 'untitled' : value;
  }
}
