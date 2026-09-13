import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/app_database.dart';
import '../models/python_project.dart';
import 'web_storage_keys.dart';

class ProjectRepository {
  Future<List<PythonProject>> getAll({String search = ''}) async {
    final projects = await _load();
    final query = search.trim().toLowerCase();
    final filtered = query.isEmpty
        ? List.of(projects)
        : projects
              .where(
                (project) => project.name.toLowerCase().contains(query),
              )
              .toList();
    return filtered
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<PythonProject?> getById(int id) async {
    final projects = await _load();
    for (final project in projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  Future<PythonProject> getDefault() async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await _load(prefs);
    for (final project in projects) {
      if (project.name == AppDatabase.defaultProjectName) {
        await prefs.setInt(WebStorageKeys.defaultProjectId, project.id!);
        return project;
      }
    }
    final now = DateTime.now();
    final saved = await save(
      PythonProject(
        name: AppDatabase.defaultProjectName,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await prefs.setInt(WebStorageKeys.defaultProjectId, saved.id!);
    return saved;
  }

  Future<PythonProject> save(PythonProject project) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await _load(prefs);
    final now = DateTime.now();
    late final PythonProject saved;
    if (project.id == null) {
      final id = prefs.getInt(WebStorageKeys.projectsNextId) ?? 1;
      saved = project.copyWith(id: id, createdAt: now, updatedAt: now);
      projects.add(saved);
      await prefs.setInt(WebStorageKeys.projectsNextId, id + 1);
    } else {
      saved = project.copyWith(updatedAt: now);
      final index = projects.indexWhere((item) => item.id == project.id);
      if (index == -1) {
        projects.add(saved);
      } else {
        projects[index] = saved;
      }
    }
    await _write(prefs, projects);
    return saved;
  }

  Future<void> delete(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final projects = await _load(prefs)
      ..removeWhere((project) => project.id == id);
    await _write(prefs, projects);

    final programs = await _loadPrograms(prefs)
      ..removeWhere((program) => program.projectId == id);
    await prefs.setString(
      WebStorageKeys.programs,
      jsonEncode(programs.map((program) => program.toMap()).toList()),
    );
  }

  Future<List<PythonProject>> _load([SharedPreferences? preferences]) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(WebStorageKeys.projects);
    if (raw == null || raw.isEmpty) return <PythonProject>[];
    final rows = jsonDecode(raw) as List<dynamic>;
    return rows
        .map(
          (row) => PythonProject.fromMap(
            (row as Map<dynamic, dynamic>).cast<String, Object?>(),
          ),
        )
        .toList();
  }

  Future<List<dynamic>> _loadPrograms(SharedPreferences prefs) async {
    final raw = prefs.getString(WebStorageKeys.programs);
    if (raw == null || raw.isEmpty) return <dynamic>[];
    return jsonDecode(raw) as List<dynamic>;
  }

  Future<void> _write(
    SharedPreferences prefs,
    List<PythonProject> projects,
  ) => prefs.setString(
    WebStorageKeys.projects,
    jsonEncode(projects.map((project) => project.toMap()).toList()),
  );
}