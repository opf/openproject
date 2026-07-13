import { I18n } from 'i18n-js';
import '@testing-library/jest-dom/vitest';
import { afterEach, vi } from 'vitest';
import { registerDialogStreamAction } from 'core-turbo/dialog-stream-action';

registerDialogStreamAction();

afterEach(() => {
  vi.useRealTimers();
});

// eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-member-access
(window as any).global = window;

window.I18n = new I18n();

// jsdom does not implement CSS.escape; production helpers (e.g. getMetaElement)
// call it unconditionally.
if (typeof CSS === 'undefined' || typeof CSS.escape !== 'function') {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  (globalThis as any).CSS = (globalThis as any).CSS || {};
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  (globalThis as any).CSS.escape = (value:string) => String(value).replace(/[^a-zA-Z0-9_\-]/g, (ch) => `\\${ch}`);
}

// jsdom does not implement ResizeObserver. The shim declares the native
// constructor signature so static analysis resolving the global to this class
// still accepts the callback every real call site passes.
if (typeof (globalThis as any).ResizeObserver === 'undefined') {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  (globalThis as any).ResizeObserver = class {
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    constructor(_callback:ResizeObserverCallback) {}
    observe() {}
    unobserve() {}
    disconnect() {}
  };
}

// jsdom does not implement HTMLDialogElement.showModal/close.
if (typeof HTMLDialogElement !== 'undefined') {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const proto = HTMLDialogElement.prototype as any;
  if (typeof proto.showModal !== 'function') {
    proto.showModal = function showModal() { this.open = true; };
  }
  if (typeof proto.show !== 'function') {
    proto.show = function show() { this.open = true; };
  }
  if (typeof proto.close !== 'function') {
    proto.close = function close() { this.open = false; };
  }
}
