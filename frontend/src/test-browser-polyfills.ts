// Browser test runners (Playwright) lack Node.js globals that some
// libraries read at import time (e.g. picocolors reads process.env).
const globalWithProcess = globalThis as unknown as { process?:{ env:Record<string, string|undefined> } };

if (typeof globalWithProcess.process === 'undefined') {
  globalWithProcess.process = { env: {} };
}
