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

import { StreamActions } from '@hotwired/turbo';
import { waitFor } from '@testing-library/dom';
import { DialogCloseDetail, registerDialogStreamAction } from './dialog-stream-action';

describe('registerDialogStreamAction', () => {
  let controller:AbortController;
  let closeEvents:CustomEvent<DialogCloseDetail>[];

  beforeEach(() => {
    registerDialogStreamAction();
    controller = new AbortController();
    closeEvents = [];
    document.addEventListener('dialog:close', (event) => {
      closeEvents.push(event);
    }, { signal: controller.signal });
  });

  afterEach(() => {
    controller.abort();
    vi.useRealTimers();
    document.body.innerHTML = '';
  });

  function dialog(content:string, id = 'test-dialog'):HTMLDialogElement {
    const element = document.createElement('turbo-stream');
    element.innerHTML = `<template><dialog-helper><dialog id="${id}">${content}</dialog></dialog-helper></template>`;
    StreamActions.dialog.call(element);

    return document.getElementById(id) as HTMLDialogElement;
  }

  function closeDialog(attributes:Record<string, string>):void {
    const element = document.createElement('turbo-stream');
    Object.entries(attributes).forEach(([name, value]) => element.setAttribute(name, value));
    StreamActions.closeDialog.call(element);
  }

  it('appends and shows a new dialog', () => {
    const dialogElement = dialog('<p>Initial content</p>');

    expect(dialogElement.parentElement?.tagName).toBe('DIALOG-HELPER');
    expect(dialogElement.open).toBe(true);
  });

  it('removes a newly streamed dialog and reports an unsuccessful close', async () => {
    const dialogElement = dialog('<p>Initial content</p>');

    dialogElement.close();

    await waitFor(() => expect(closeEvents).toHaveLength(1));
    expect(dialogElement).not.toBeInTheDocument();
    expect(closeEvents[0].detail).toEqual({ dialog: dialogElement, submitted: false });
  });

  it('reports a submitted close with additional data without dispatching a duplicate event', async () => {
    const dialogElement = dialog('<p>Initial content</p>');

    closeDialog({ target: 'test-dialog', additional: '{"workPackageId":42}' });

    expect(closeEvents).toHaveLength(1);
    expect(closeEvents[0].detail).toEqual({
      dialog: dialogElement,
      submitted: true,
      additional: { workPackageId: 42 },
    });

    await waitFor(() => expect(dialogElement).not.toBeInTheDocument());
    expect(closeEvents).toHaveLength(1);
  });

  it('closes the dialog matched by a targets selector', async () => {
    const dialogElement = dialog('<p>Initial content</p>');

    closeDialog({ targets: '#test-dialog' });

    expect(closeEvents).toHaveLength(1);
    await waitFor(() => expect(dialogElement).not.toBeInTheDocument());
  });

  it('defaults the additional data to an empty object', () => {
    dialog('<p>Initial content</p>');

    closeDialog({ target: 'test-dialog' });

    expect(closeEvents[0].detail.additional).toEqual({});
  });

  it('ignores a close target that matches no element', () => {
    const dialogElement = dialog('<p>Initial content</p>');

    closeDialog({ target: 'missing-dialog' });

    expect(closeEvents).toHaveLength(0);
    expect(dialogElement).toBeInTheDocument();
    expect(dialogElement.open).toBe(true);
  });

  it('ignores a close target that is not a dialog', () => {
    document.body.insertAdjacentHTML('beforeend', '<div id="not-a-dialog"></div>');

    closeDialog({ target: 'not-a-dialog' });

    expect(closeEvents).toHaveLength(0);
  });

  it('morphs and reopens the existing dialog when the same id is streamed again', () => {
    const dialogElement = dialog('<p>Initial content</p>');
    dialogElement.removeAttribute('open');
    expect(dialogElement.open).toBe(false);

    dialog('<h2>Updated content</h2>');

    expect(document.querySelectorAll('#test-dialog')).toHaveLength(1);
    expect(document.getElementById('test-dialog')).toBe(dialogElement);
    expect(dialogElement.innerHTML).toBe('<h2>Updated content</h2>');
    expect(dialogElement.open).toBe(true);
  });

  it('adjusts the dialog width after it is shown', () => {
    vi.useFakeTimers();
    const dialogElement = dialog('<p>Initial content</p>');
    Object.defineProperty(dialogElement, 'offsetWidth', { configurable: true, value: 320 });

    vi.advanceTimersByTime(250);

    expect(dialogElement.style.width).toBe('321px');
  });
});
