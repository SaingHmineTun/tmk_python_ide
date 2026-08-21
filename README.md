# Python IDE

Python IDE is an offline-first Flutter IDE for writing and running Python on Android, iOS, and the web. It is an editor and runtime—not a course, tutorial, quiz, or account-based product.

The core path is implemented and device-tested:

```text
Flutter editor → PythonRuntime → Web Worker → bundled Pyodide
               ← stdout / stderr / completion ←
```

## Milestone 1 features

- Python editor with syntax highlighting, line numbers, undo/redo, selection, horizontal/vertical scrolling, auto-closing symbols, and Python colon auto-indent
- phone coding toolbar with Tab, outdent, symbols, undo, and redo
- iPhone/iPad web editor workaround plus a dedicated Space key
- name-first file creation and Python syntax checking before execution
- real on-device Python execution; no `Process.run`, server, CDN, or installed system Python
- streamed stdout/stderr, real Python tracebacks, expandable/draggable output console, clear, and copy
- hard Stop: terminates the Web Worker and recreates a clean runtime, including for `while True`
- persistent programs with create, save, open, rename, duplicate, search, and confirmed delete
- debounced autosave for saved programs and recovery drafts for unsaved programs
- UTF-8 `.py` import, export, code sharing, and file sharing
- system/light/dark themes and editor preferences
- responsive phone/tablet navigation and portrait/landscape support
- app lifecycle draft persistence and on-device-only source storage
- installable, phone-first web app with browser-local program storage

## Python runtime

`PyodideRuntime` implements the replaceable `PythonRuntime` interface. The application bundles Pyodide 314.0.4 core under `assets/pyodide`; basic Python and the standard library work after installation with no network connection.

On Android and iOS, a hidden platform WebView loads assets from an ephemeral loopback-only HTTP server. In a browser, Flutter starts the bundled worker directly. Both paths run Python outside Flutter's UI thread. Pressing Stop terminates the worker, so an infinite Python loop cannot permanently freeze the interface.

See [docs/python_runtime_decision.md](docs/python_runtime_decision.md) for the evaluated alternatives and technical rationale.

### Supported now

- Python language features and Unicode
- common standard-library modules such as `math`, `random`, `datetime`, `statistics`, and `json`
- async execution, progressive line-oriented stdout/stderr, Python tracebacks, and hard termination
- Pyodide's sandboxed in-memory filesystem for the lifetime of the runtime

### Known limitations

- Third-party Pyodide wheels are not bundled in Milestone 1. Imports such as NumPy/pandas are intentionally not promised offline yet.
- `input()` opens an in-app prompt on Android, iOS, and web, and supports multiple prompts in one learner program.
- The Pyodide filesystem is sandboxed from the device and browser filesystems. Its in-memory files are not persisted yet.
- Stopping execution destroys the worker and any Python globals/files in that runtime session.
- Output streaming is line/batch oriented. Python code that does not flush or print a newline may appear later.
- iOS App Store review must still be performed for the final distribution configuration and product behavior.

## Storage and privacy

Programs are stored in SQLite on Android and iOS. The web build stores the same program model in browser-local persistent storage, keeping files on that browser profile.

The mobile `programs` table is:

```sql
CREATE TABLE programs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

Source code stays on-device or in the current browser profile. It is not sent to analytics, a server, or an AI API. Code leaves the app only when the user explicitly imports, exports, or shares it. Opening/importing a program never executes it.

## Development setup

Requirements:

- Flutter stable (implemented with Flutter 3.44 / Dart 3.12)
- Android SDK with API 24 or newer target device
- Xcode with iOS 14 or newer target device/simulator
- an Apple development account/profile to install on a physical iPhone/iPad

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter run -d chrome
```

Build each platform target:

```bash
flutter build apk --debug
flutter build ios --debug --no-codesign
flutter build web --release
```

### Vercel deployment

Build the Flutter web target before deployment and configure the Vercel build
step to run `flutter build web --release`. The checked-in `vercel.json` serves
`build/web` and keeps Flutter's entry files revalidated so a new deployment
cannot mix an old bootstrap or service worker with new assets.

The iOS bundle identifier is independent of the web deployment. The Runner and
RunnerTests identifiers are aligned under `it.saimao.pythonide`.

Run the end-to-end Python proof on a connected target:

```bash
flutter test integration_test/python_runtime_test.dart -d <device-id>
```

For a wireless physical iPhone, use the integration driver (Flutter requires published debug ports):

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/python_runtime_test.dart \
  -d <device-id>
```

The integration test waits for Python readiness, runs `print("Hello, World!")`, verifies Flutter console output, verifies a real `NameError`, starts `while True`, and verifies Stop recovers the app.

## Verification performed

- `flutter analyze`: clean
- Dart/SQLite tests: CRUD, search, model behavior, and Unicode round-trip pass
- phone-sized web browser: bundled Python execution, output, browser-local save, reload persistence, and Files listing pass
- release web, debug Android APK, and no-codesign iOS device builds compile successfully
- iOS 26.5 iPhone simulator: runtime/output/error/stop integration test passes
- Android 17 API 37 arm64 emulator: runtime/output/error/stop integration test passes
- physical iPhone device build: compiles successfully; deployment on the available phone was blocked by the machine's missing Apple account/provisioning profile

## Project layout

```text
lib/
├── app/                    themes and application shell
├── core/
│   ├── database/           SQLite initialization
│   ├── files/              UTF-8 import/export/share
│   └── python/             runtime abstraction and Pyodide bridge
├── features/
│   ├── editor/             editor, toolbar, console, Python editing behavior
│   ├── programs/           saved program management
│   ├── settings/           editor and theme preferences
│   └── shell/              responsive navigation/runtime host
├── models/
├── providers/              Riverpod controllers and autosave
└── repositories/           SQL-free UI storage boundary
```

The app name is centralized as `appName` in `lib/app/app.dart`, so the temporary product name can be changed without touching feature widgets.
