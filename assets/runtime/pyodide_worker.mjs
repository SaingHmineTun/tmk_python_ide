import { loadPyodide } from '../pyodide/pyodide.mjs';

let pyodide;
let running = false;

async function initialize() {
  try {
    pyodide = await loadPyodide({indexURL: '../pyodide/'});
    pyodide.setStdout({batched: (text) => self.postMessage({type: 'stdout', data: text + '\n'})});
    pyodide.setStderr({batched: (text) => self.postMessage({type: 'stderr', data: text + '\n'})});
    self.postMessage({type: 'ready', version: pyodide.version});
  } catch (error) {
    self.postMessage({type: 'runtimeError', data: String(error)});
  }
}

const ready = initialize();

self.onmessage = async (event) => {
  const message = event.data;
  if (message.type === 'execute') {
    await ready;
    if (!pyodide || running) return;
    running = true;
    try {
      await pyodide.loadPackagesFromImports(message.code);
      await pyodide.runPythonAsync(message.code);
      self.postMessage({type: 'completed', id: message.id, success: true, exitCode: 0});
    } catch (error) {
      // PythonError.toString() contains the real Python traceback. Its JS
      // stack only contains WebAssembly frames and hides NameError, etc.
      const text = String(error);
      self.postMessage({type: 'stderr', data: text.endsWith('\n') ? text : text + '\n'});
      self.postMessage({type: 'completed', id: message.id, success: false, exitCode: 1, error: text});
    } finally {
      running = false;
    }
  }
};
