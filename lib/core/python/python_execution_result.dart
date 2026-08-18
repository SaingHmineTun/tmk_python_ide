class PythonExecutionResult {
  const PythonExecutionResult({
    required this.succeeded,
    required this.exitCode,
    required this.duration,
    this.error,
  });

  final bool succeeded;
  final int exitCode;
  final Duration duration;
  final String? error;
}
