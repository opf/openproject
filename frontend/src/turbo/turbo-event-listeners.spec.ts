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

import { addTurboEventListeners } from './turbo-event-listeners';

describe('addTurboEventListeners — dialog close on turbo:submit-end', () => {
  let controller:AbortController;

  beforeEach(() => {
    controller = new AbortController();
    addTurboEventListeners(document, controller.signal);
  });

  afterEach(() => {
    controller.abort();
    document.body.innerHTML = '';
  });

  function submitEnd(form:HTMLFormElement, success:boolean) {
    form.dispatchEvent(new CustomEvent('turbo:submit-end', {
      bubbles: true,
      detail: { success },
    }));
  }

  it('closes the dialog and dispatches dialog:close on a successful submit', () => {
    document.body.innerHTML = '<dialog><form></form></dialog>';
    const dialog = document.querySelector('dialog')!;
    const form = document.querySelector('form')!;
    dialog.showModal();

    const onClose = vi.fn();
    document.addEventListener('dialog:close', onClose, { signal: controller.signal });

    submitEnd(form, true);

    expect(dialog.open).toBe(false);
    expect(onClose).toHaveBeenCalledOnce();
  });

  it('keeps the dialog open when data-keep-open-on-submit is set', () => {
    document.body.innerHTML = '<dialog data-keep-open-on-submit="true"><form></form></dialog>';
    const dialog = document.querySelector('dialog')!;
    const form = document.querySelector('form')!;
    dialog.showModal();

    const onClose = vi.fn();
    document.addEventListener('dialog:close', onClose, { signal: controller.signal });

    submitEnd(form, true);

    expect(dialog.open).toBe(true);
    expect(onClose).not.toHaveBeenCalled();
  });

  it('does nothing when the submit was not successful', () => {
    document.body.innerHTML = '<dialog><form></form></dialog>';
    const dialog = document.querySelector('dialog')!;
    const form = document.querySelector('form')!;
    dialog.showModal();

    submitEnd(form, false);

    expect(dialog.open).toBe(true);
  });
});

describe('addTurboEventListeners — Turbo nonce header on fetch requests', () => {
  let controller:AbortController;

  beforeEach(() => {
    controller = new AbortController();
    document.head.insertAdjacentHTML('beforeend', '<meta name="csp-nonce" content="nonce-xyz">');
    addTurboEventListeners(document, controller.signal);
  });

  afterEach(() => {
    controller.abort();
    document.querySelector('meta[name="csp-nonce"]')?.remove();
  });

  it('adds Turbo-Referrer and X-Turbo-Nonce headers', () => {
    const headers:Record<string, string> = {};
    document.dispatchEvent(new CustomEvent('turbo:before-fetch-request', {
      detail: { fetchOptions: { headers } },
    }));

    expect(headers['Turbo-Referrer']).toBe(window.location.href);
    expect(headers['X-Turbo-Nonce']).toBe('nonce-xyz');
  });
});

describe('addTurboEventListeners — CSP script-nonce enforcement', () => {
  let controller:AbortController;

  beforeEach(() => {
    controller = new AbortController();
    document.head.insertAdjacentHTML('beforeend', '<meta name="csp-nonce" content="nonce-abc">');
    addTurboEventListeners(document, controller.signal);
    vi.spyOn(console, 'warn').mockImplementation(() => undefined);
  });

  afterEach(() => {
    controller.abort();
    document.querySelector('meta[name="csp-nonce"]')?.remove();
    vi.restoreAllMocks();
  });

  function scriptWithNonce(nonce:string | null):HTMLScriptElement {
    const script = document.createElement('script');
    if (nonce !== null) {
      script.setAttribute('nonce', nonce);
    }
    return script;
  }

  it('strips a mismatched-nonce script from a Turbo Drive page render', () => {
    const newBody = document.createElement('body');
    const badScript = scriptWithNonce('wrong-nonce');
    const goodScript = scriptWithNonce('nonce-abc');
    newBody.append(badScript, goodScript);

    document.dispatchEvent(new CustomEvent('turbo:before-render', {
      detail: { newBody },
    }));

    expect(newBody.contains(badScript)).toBe(false);
    expect(newBody.contains(goodScript)).toBe(true);
  });

  it('strips a mismatched-nonce script from a Turbo Frame render', () => {
    const newFrame = document.createElement('turbo-frame');
    const badScript = scriptWithNonce('wrong-nonce');
    const goodScript = scriptWithNonce('nonce-abc');
    newFrame.append(badScript, goodScript);

    document.dispatchEvent(new CustomEvent('turbo:before-frame-render', {
      detail: { newFrame },
    }));

    expect(newFrame.contains(badScript)).toBe(false);
    expect(newFrame.contains(goodScript)).toBe(true);
  });

  it('strips a mismatched-nonce script from a Turbo Stream render', async () => {
    const content = document.createDocumentFragment();
    const badScript = scriptWithNonce('wrong-nonce');
    const goodScript = scriptWithNonce('nonce-abc');
    content.append(badScript, goodScript);

    const streamElement = { templateElement: { content } };
    const fallbackToDefaultActions = vi.fn().mockResolvedValue(undefined);
    const detail = { render: fallbackToDefaultActions };

    document.dispatchEvent(new CustomEvent('turbo:before-stream-render', { detail }));
    await detail.render(streamElement);

    expect(content.contains(badScript)).toBe(false);
    expect(content.contains(goodScript)).toBe(true);
    expect(fallbackToDefaultActions).toHaveBeenCalledWith(streamElement);
  });
});
