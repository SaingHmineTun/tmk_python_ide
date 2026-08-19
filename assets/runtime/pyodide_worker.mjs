import { loadPyodide } from '../pyodide/pyodide.mjs';

let pyodide;
let running = false;
let activeExecution;
let providedInputs = [];
let inputOffset = 0;
let pendingPrompt = '';
let stdoutBytes = [];
let stdoutTimer;

const inputRequiredMarker = '__TMK_INPUT_REQUIRED__';

const stdoutDecoder = new TextDecoder();

function flushStdout() {
  if (stdoutTimer !== undefined) clearTimeout(stdoutTimer);
  stdoutTimer = undefined;
  if (stdoutBytes.length === 0) return;
  const text = stdoutDecoder.decode(Uint8Array.from(stdoutBytes), {stream: true});
  stdoutBytes = [];
  if (text) self.postMessage({type: 'stdout', data: text});
}

function handleStdoutByte(byte) {
  stdoutBytes.push(byte);
  if (byte === 10) {
    flushStdout();
  } else if (stdoutTimer === undefined) {
    stdoutTimer = setTimeout(flushStdout, 0);
  }
}

async function initialize() {
  try {
    pyodide = await loadPyodide({indexURL: '../pyodide/'});
    pyodide.setStdout({raw: handleStdoutByte});
    pyodide.setStderr({batched: (text) => self.postMessage({type: 'stderr', data: text + '\n'})});
    pyodide.globals.set('__tmk_read_input', (prompt = '') => {
      pendingPrompt = String(prompt ?? '');
      if (inputOffset < providedInputs.length) {
        return providedInputs[inputOffset++];
      }
      return inputRequiredMarker;
    });
    pyodide.runPython(`
import builtins

def __tmk_input(prompt=''):
    value = __tmk_read_input(prompt)
    if value == '${inputRequiredMarker}':
        raise RuntimeError('${inputRequiredMarker}')
    return str(value)

builtins.input = __tmk_input
`);
    self.postMessage({type: 'ready', version: pyodide.version});
  } catch (error) {
    self.postMessage({type: 'runtimeError', data: String(error)});
  }
}

const ready = initialize();

function flushPythonStreams() {
  pyodide.runPython(`
import sys
sys.stdout.flush()
sys.stderr.flush()
`);
}

async function runActiveExecution({resetOutput = false} = {}) {
  await ready;
  if (!pyodide || running || !activeExecution) return;
  running = true;
  inputOffset = 0;
  pendingPrompt = '';
  if (resetOutput) self.postMessage({type: 'resetOutput'});
  try {
    await pyodide.loadPackagesFromImports(activeExecution.code);
    await pyodide.runPythonAsync(activeExecution.code);
    flushPythonStreams();
    flushStdout();
    self.postMessage({
      type: 'completed',
      id: activeExecution.id,
      success: true,
      exitCode: 0,
    });
    activeExecution = undefined;
  } catch (error) {
    flushPythonStreams();
    flushStdout();
    const text = String(error);
    if (text.includes(inputRequiredMarker)) {
      self.postMessage({type: 'inputRequest', prompt: pendingPrompt});
    } else {
      // PythonError.toString() contains the real Python traceback. Its JS
      // stack only contains WebAssembly frames and hides NameError, etc.
      self.postMessage({type: 'stderr', data: text.endsWith('\n') ? text : text + '\n'});
      self.postMessage({
        type: 'completed',
        id: activeExecution.id,
        success: false,
        exitCode: 1,
        error: text,
      });
      activeExecution = undefined;
    }
  } finally {
    running = false;
  }
}

self.onmessage = async (event) => {
  const message = event.data;
  if (message.type === 'execute') {
    if (running || activeExecution) return;
    activeExecution = {id: message.id, code: message.code};
    providedInputs = [];
    await runActiveExecution();
  } else if (message.type === 'input' && activeExecution && !running) {
    providedInputs.push(String(message.input ?? ''));
    await runActiveExecution({resetOutput: true});
  }
};
