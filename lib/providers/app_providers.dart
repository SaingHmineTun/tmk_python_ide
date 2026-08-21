import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/files/program_file_service.dart';
import '../core/python/pyodide_runtime.dart';
import '../core/python/python_runtime.dart';
import '../models/console_message.dart';
import '../models/execution_state.dart';
import '../models/python_program.dart';
import '../repositories/program_repository.dart';

const defaultStarterCode = 'print("Hello, World!")\n';

final programRepositoryProvider = Provider((ref) => ProgramRepository());
final programFileServiceProvider = Provider((ref) => ProgramFileService());

final programsProvider = FutureProvider.family<List<PythonProgram>, String>((
  ref,
  search,
) {
  return ref.watch(programRepositoryProvider).getAll(search: search);
});

final editorSessionProvider = ChangeNotifierProvider<EditorSession>((ref) {
  return EditorSession(ref.read(programRepositoryProvider), ref);
});

class EditorSession extends ChangeNotifier {
  EditorSession(this._repository, this._ref);

  static const _draftCodeKey = 'editor_draft_code';
  static const _draftNameKey = 'editor_draft_name';
  static const _lastProgramKey = 'last_program_id';

  final ProgramRepository _repository;
  final Ref _ref;
  PythonProgram? current;
  Timer? _autoSave;
  bool dirty = false;
  bool loading = true;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt(_lastProgramKey);
    if (lastId != null) current = await _repository.getById(lastId);
    current ??= PythonProgram(
      name: prefs.getString(_draftNameKey) ?? 'Untitled',
      code: prefs.getString(_draftCodeKey) ?? defaultStarterCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    loading = false;
    notifyListeners();
  }

  void updateCode(String code) {
    final value = current;
    if (value == null || value.code == code) return;
    current = value.copyWith(code: code);
    dirty = true;
    _autoSave?.cancel();
    _autoSave = Timer(const Duration(milliseconds: 900), save);
  }

  Future<void> newProgram({
    String code = defaultStarterCode,
    String name = 'Untitled',
  }) async {
    await flush();
    current = PythonProgram(
      name: name,
      code: code,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    dirty = true;
    await _writeDraft();
    notifyListeners();
  }

  Future<void> open(PythonProgram program) async {
    await flush();
    current = program;
    dirty = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastProgramKey, program.id!);
    notifyListeners();
  }

  Future<void> rename(String name) async {
    final value = current;
    if (value == null || name.trim().isEmpty) return;
    if (value.id != null) {
      await renameProgram(value, name);
      return;
    }
    current = value.copyWith(name: name.trim());
    dirty = true;
    await _writeDraft();
    notifyListeners();
  }

  Future<PythonProgram> renameProgram(
    PythonProgram program,
    String name,
  ) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Program name cannot be empty.');
    final saved = await _repository.save(program.copyWith(name: trimmed));
    if (current?.id == saved.id) {
      current = current!.copyWith(name: saved.name, updatedAt: saved.updatedAt);
      notifyListeners();
    }
    _ref.invalidate(programsProvider);
    return saved;
  }

  Future<PythonProgram?> save() async {
    _autoSave?.cancel();
    final value = current;
    if (value == null) return null;
    if (value.id == null) {
      await _writeDraft();
      return value;
    }
    current = await _repository.save(value);
    dirty = false;
    _ref.invalidate(programsProvider);
    return current;
  }

  Future<PythonProgram?> saveAsProgram() async {
    final value = current;
    if (value == null) return null;
    current = await _repository.save(value);
    dirty = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastProgramKey, current!.id!);
    await prefs.remove(_draftCodeKey);
    await prefs.remove(_draftNameKey);
    _ref.invalidate(programsProvider);
    notifyListeners();
    return current;
  }

  Future<void> flush() async {
    if (current?.id == null) {
      await _writeDraft();
    } else if (dirty) {
      await save();
    }
  }

  Future<void> _writeDraft() async {
    final value = current;
    if (value == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftCodeKey, value.code);
    await prefs.setString(_draftNameKey, value.name);
  }

  @override
  void dispose() {
    _autoSave?.cancel();
    super.dispose();
  }
}

final runtimeControllerProvider = ChangeNotifierProvider<RuntimeController>((
  ref,
) {
  return RuntimeController(PyodideRuntime());
});

class RuntimeController extends ChangeNotifier {
  RuntimeController(this.runtime);

  final PythonRuntime runtime;
  PythonRuntimeStatus status = PythonRuntimeStatus.idle;
  final List<ConsoleMessage> messages = [];
  String? runtimeError;
  bool _requestingInput = false;

  Future<void> initialize() async {
    status = PythonRuntimeStatus.starting;
    notifyListeners();
    try {
      await runtime.initialize();
      status = PythonRuntimeStatus.ready;
    } catch (error) {
      runtimeError = '$error';
      status = PythonRuntimeStatus.error;
      _add(ConsoleMessageType.stderr, 'Python failed to start: $error\n');
    }
    notifyListeners();
  }

  Future<void> run(
    String code, {
    Future<String?> Function(String prompt)? onInput,
  }) async {
    if (status == PythonRuntimeStatus.running) return;
    if (!runtime.isReady) await initialize();
    if (!runtime.isReady) return;
    status = PythonRuntimeStatus.running;
    final executionMessageStart = messages.length;
    notifyListeners();
    try {
      final result = await runtime.execute(
        code,
        onStdout: (text) => _add(ConsoleMessageType.stdout, text),
        onStderr: (text) => _add(ConsoleMessageType.stderr, text),
        onOutputReset: () {
          if (messages.length > executionMessageStart) {
            messages.removeRange(executionMessageStart, messages.length);
            notifyListeners();
          }
        },
        onInputRequested: (prompt) {
          if (onInput != null) {
            unawaited(_requestInput(prompt, onInput));
          }
        },
      );
      status = result.exitCode == 130
          ? PythonRuntimeStatus.stopped
          : PythonRuntimeStatus.ready;
      _add(
        ConsoleMessageType.system,
        result.succeeded
            ? 'Finished successfully in ${(result.duration.inMilliseconds / 1000).toStringAsFixed(2)}s\n'
            : result.exitCode == 130
            ? 'Stopped\n'
            : 'Finished with errors\n',
      );
    } catch (error) {
      status = PythonRuntimeStatus.error;
      _add(ConsoleMessageType.stderr, '$error\n');
    }
    notifyListeners();
  }

  Future<bool> checkSyntax(String code, {bool quietSuccess = false}) async {
    if (status == PythonRuntimeStatus.running ||
        status == PythonRuntimeStatus.starting) {
      return false;
    }
    if (!runtime.isReady) await initialize();
    if (!runtime.isReady) return false;

    status = PythonRuntimeStatus.running;
    notifyListeners();
    try {
      final result = await runtime.execute(
        'compile(${jsonEncode(code)}, "<editor>", "exec")',
        onStdout: (text) => _add(ConsoleMessageType.stdout, text),
        onStderr: (text) => _add(ConsoleMessageType.stderr, text),
        onOutputReset: () {},
        onInputRequested: (_) {},
      );
      status = PythonRuntimeStatus.ready;
      if (result.succeeded) {
        if (!quietSuccess) {
          _add(ConsoleMessageType.system, 'Syntax check passed\n');
        }
        notifyListeners();
        return true;
      }
      _add(ConsoleMessageType.system, 'Fix the syntax error before running.\n');
    } catch (error) {
      status = PythonRuntimeStatus.error;
      _add(ConsoleMessageType.stderr, 'Syntax check failed: $error\n');
    }
    notifyListeners();
    return false;
  }

  Future<void> _requestInput(
    String prompt,
    Future<String?> Function(String prompt) provider,
  ) async {
    if (_requestingInput || status != PythonRuntimeStatus.running) return;
    _requestingInput = true;
    try {
      final input = await provider(prompt);
      if (status != PythonRuntimeStatus.running) return;
      _requestingInput = false;
      if (input == null) {
        await stop();
      } else {
        await runtime.provideInput(input);
      }
    } finally {
      _requestingInput = false;
    }
  }

  Future<void> stop() => runtime.stop();

  void clear() {
    messages.clear();
    notifyListeners();
  }

  void _add(ConsoleMessageType type, String text) {
    messages.add(
      ConsoleMessage(type: type, text: text, timestamp: DateTime.now()),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    runtime.dispose();
    super.dispose();
  }
}

class EditorSettings {
  const EditorSettings({
    this.themeMode = ThemeMode.system,
    this.fontSize = 15,
    this.tabSize = 4,
    this.wordWrap = false,
    this.lineNumbers = true,
    this.autoIndent = true,
    this.autoClosingBrackets = true,
  });

  final ThemeMode themeMode;
  final double fontSize;
  final int tabSize;
  final bool wordWrap;
  final bool lineNumbers;
  final bool autoIndent;
  final bool autoClosingBrackets;

  EditorSettings copyWith({
    ThemeMode? themeMode,
    double? fontSize,
    int? tabSize,
    bool? wordWrap,
    bool? lineNumbers,
    bool? autoIndent,
    bool? autoClosingBrackets,
  }) => EditorSettings(
    themeMode: themeMode ?? this.themeMode,
    fontSize: fontSize ?? this.fontSize,
    tabSize: tabSize ?? this.tabSize,
    wordWrap: wordWrap ?? this.wordWrap,
    lineNumbers: lineNumbers ?? this.lineNumbers,
    autoIndent: autoIndent ?? this.autoIndent,
    autoClosingBrackets: autoClosingBrackets ?? this.autoClosingBrackets,
  );
}

final editorSettingsProvider =
    StateNotifierProvider<EditorSettingsController, EditorSettings>(
      (ref) => EditorSettingsController()..restore(),
    );

class EditorSettingsController extends StateNotifier<EditorSettings> {
  EditorSettingsController() : super(const EditorSettings());

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      themeMode: ThemeMode.values[prefs.getInt('theme_mode') ?? 0],
      fontSize: prefs.getDouble('font_size') ?? 15,
      wordWrap: prefs.getBool('word_wrap') ?? false,
      lineNumbers: prefs.getBool('line_numbers') ?? true,
      autoIndent: prefs.getBool('auto_indent') ?? true,
      autoClosingBrackets: prefs.getBool('auto_brackets') ?? true,
    );
  }

  Future<void> update(EditorSettings value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt('theme_mode', value.themeMode.index),
      prefs.setDouble('font_size', value.fontSize),
      prefs.setBool('word_wrap', value.wordWrap),
      prefs.setBool('line_numbers', value.lineNumbers),
      prefs.setBool('auto_indent', value.autoIndent),
      prefs.setBool('auto_brackets', value.autoClosingBrackets),
    ]);
  }
}
