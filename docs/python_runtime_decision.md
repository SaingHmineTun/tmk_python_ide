# Python runtime decision

Date: 2026-08-16  
Decision: bundled Pyodide 314.0.4 in a Web Worker behind `PythonRuntime`

## Decision drivers

The runtime must execute locally and offline on Android and iOS, keep Flutter responsive, return real stdout/stderr, terminate infinite loops, avoid an assumed system Python executable, and remain replaceable.

## Selected architecture

```text
Flutter UI
  → PythonRuntime interface
  → PyodideRuntime
  → hidden Android WebView / iOS WKWebView
  → loopback-only bundled-asset server
  → ES module Web Worker
  → bundled Pyodide + WebAssembly + Python standard library
```

Pyodide's official documentation recommends a Web Worker because synchronous Python/WebAssembly on the browser main thread can make a UI unresponsive. Current Pyodide uses an ES module worker. The worker is also the termination boundary: Stop calls `Worker.terminate()` and immediately creates a fresh worker.

Flutter's maintained `webview_flutter` package provides Android WebView and iOS WKWebView from one supported API. Direct `file:` Flutter assets were rejected by WKWebView when creating a module worker during the iOS integration proof. The app therefore serves only its bundled runtime assets from an ephemeral `127.0.0.1` port. This is not remote execution, does not require network connectivity, and is unreachable off-device because the server binds only to loopback.

Structured JSON messages cross the JavaScript channel (`ready`, `stdout`, `stderr`, `completed`, `runtimeError`, and `stopped`). Python source is passed as a JavaScript string argument encoded by `jsonEncode`; response handling does not scrape displayed browser text.

## Alternatives considered

### Pyodide on the WebView main thread

Rejected. It is simpler, but long-running Python blocks the WebView JavaScript thread and does not provide a dependable hard-stop boundary. The official Pyodide guidance recommends a worker for this workload.

### Chaquopy

Not selected as the shared V1 runtime. Chaquopy 17 is maintained, supports current Android/Python versions, and can integrate with Flutter through Android platform code, but its official FAQ says iOS is not supported. It remains a viable future `AndroidNativePythonRuntime` if Android-specific compatibility or performance requires it.

### Native CPython on both platforms

Deferred. A native runtime can provide broader CPython compatibility, but it requires separate Android/iOS embedding, native extension packaging, stream/input bridges, termination design, App Store review work, and significantly more platform maintenance. The `PythonRuntime` boundary intentionally permits future `AndroidNativePythonRuntime` and `IOSNativePythonRuntime` implementations.

### Remote execution service

Rejected for V1. It violates offline operation and on-device privacy, adds ongoing infrastructure cost, and sends user source off-device.

### `Process.run('python3', ...)`

Rejected. Android and iOS do not generally expose a system Python executable to applications, and subprocess assumptions are incompatible with the mobile-first requirement.

## Compatibility and tradeoffs

| Area | Decision impact |
|---|---|
| Android/iOS | One runtime and bridge; tested on Android WebView and iOS WKWebView simulators/emulators |
| Offline | Core WASM and standard library are application assets; no CDN |
| UI safety | Python runs in a worker; Flutter remains responsive |
| Stop | Hard worker termination; runtime state is reset |
| Python compatibility | Strong language/stdlib compatibility, but WebAssembly OS/filesystem/process limits apply |
| Packages | Only compatible Pyodide packages can work; third-party wheels are not bundled in Milestone 1 |
| App size | The bundled Pyodide core adds roughly 14 MB before app-store compression |
| Startup | Runtime initializes asynchronously and stays warm after startup |
| Privacy | Source never leaves the device unless the user explicitly shares/exports it |

## App-store consideration

No claim is made that every future feature or downloaded package will be accepted automatically. Before release, validate the final behavior against current Google Play and Apple App Review policies, especially any future ability to download executable packages. Milestone 1 bundles the interpreter/runtime and executes only code the user explicitly writes or imports; imported/opened programs never auto-run.

## Official references reviewed

- [Pyodide: Using Pyodide](https://pyodide.org/en/stable/usage/index.html)
- [Pyodide: Using Pyodide in a web worker](https://pyodide.org/en/stable/usage/webworker.html)
- [Pyodide: Downloading and deploying](https://pyodide.org/en/stable/usage/downloading-and-deploying.html)
- [Pyodide: Redirecting standard streams](https://pyodide.org/en/stable/usage/streams.html)
- [Pyodide: Interrupting execution](https://pyodide.org/en/stable/usage/keyboard-interrupt.html)
- [Flutter-maintained webview_flutter](https://pub.dev/packages/webview_flutter)
- [Chaquopy current documentation](https://chaquo.com/chaquopy/doc/current/)
- [Chaquopy FAQ: Flutter and iOS support](https://chaquo.com/chaquopy/doc/current/faq.html)
