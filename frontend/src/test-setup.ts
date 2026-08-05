//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { I18n } from 'i18n-js';
import '@testing-library/jest-dom/vitest';
import { afterEach, vi } from 'vitest';
import { registerDialogStreamAction } from 'core-turbo/dialog-stream-action';
import { installElements } from '@openproject/stimulus-elements';

// Blesses every controller registered afterwards with `static elements`
// accessors, mirroring the production bootstrap in stimulus/setup.ts. Must run
// before any controller is registered, so it lives in this global setup file.
installElements();

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
