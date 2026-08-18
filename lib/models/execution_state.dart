enum PythonRuntimeStatus { starting, ready, running, stopped, error }

extension PythonRuntimeStatusLabel on PythonRuntimeStatus {
  String get label => switch (this) {
    PythonRuntimeStatus.starting => 'Starting Python…',
    PythonRuntimeStatus.ready => 'Python Ready',
    PythonRuntimeStatus.running => 'Running…',
    PythonRuntimeStatus.stopped => 'Stopped',
    PythonRuntimeStatus.error => 'Runtime Error',
  };
}
