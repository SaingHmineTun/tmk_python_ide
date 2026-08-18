enum ConsoleMessageType { stdout, stderr, input, system }

class ConsoleMessage {
  const ConsoleMessage({
    required this.type,
    required this.text,
    required this.timestamp,
  });

  final ConsoleMessageType type;
  final String text;
  final DateTime timestamp;
}
