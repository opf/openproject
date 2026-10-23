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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type CheckboxConfirmationControllerType from './checkbox-confirmation.controller';

describe('Checkbox confirmation controller', () => {
  let ctx:StimulusTestContext;
  let CheckboxConfirmationController:typeof CheckboxConfirmationControllerType;

  beforeAll(async () => {
    ({ default: CheckboxConfirmationController } = await import('./checkbox-confirmation.controller'));
  });

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'checkbox-confirmation': CheckboxConfirmationController },
    });
  });

  afterEach(() => {
    ctx.dispose();
  });

  async function render({ checked, trigger }:{ checked:boolean, trigger?:string }) {
    const triggerAttribute = trigger ? `data-checkbox-confirmation-trigger-value="${trigger}"` : '';

    await ctx.mount(`
      <div data-controller="checkbox-confirmation" ${triggerAttribute}>
        <input type="checkbox" ${checked ? 'checked' : ''} data-checkbox-confirmation-target="checkbox">
        <dialog id="confirmation-dialog" data-checkbox-confirmation-target="dialog">
          <button type="button" data-close-dialog-id="confirmation-dialog">Cancel</button>
          <button type="button" data-submit-dialog-id="confirmation-dialog">Confirm</button>
        </dialog>
      </div>
    `);

    return {
      checkbox: document.querySelector<HTMLInputElement>('input[type="checkbox"]')!,
      dialog: document.querySelector<HTMLDialogElement>('dialog')!,
    };
  }

  function toggle(checkbox:HTMLInputElement) {
    checkbox.checked = !checkbox.checked;
    checkbox.dispatchEvent(new Event('change', { bubbles: true }));
  }

  function closed(dialog:HTMLDialogElement) {
    return new Promise((resolve) => {
      dialog.addEventListener('close', resolve, { once: true });
    });
  }

  it('asks for confirmation when unchecking', async () => {
    const { checkbox, dialog } = await render({ checked: true });

    toggle(checkbox);

    expect(dialog.open).toBe(true);
  });

  it('keeps the change once confirmed', async () => {
    const { checkbox, dialog } = await render({ checked: true });

    toggle(checkbox);
    const dialogClosed = closed(dialog);
    document.querySelector<HTMLButtonElement>('[data-submit-dialog-id]')!.click();
    await dialogClosed;

    expect(checkbox.checked).toBe(false);
  });

  it('reverts the change when cancelling', async () => {
    const { checkbox, dialog } = await render({ checked: true });

    toggle(checkbox);
    const dialogClosed = closed(dialog);
    document.querySelector<HTMLButtonElement>('[data-close-dialog-id]')!.click();
    dialog.close();
    await dialogClosed;

    expect(checkbox.checked).toBe(true);
  });

  it('reverts the change when the dialog is closed without confirming', async () => {
    const { checkbox, dialog } = await render({ checked: true });

    toggle(checkbox);
    const dialogClosed = closed(dialog);
    dialog.close();
    await dialogClosed;

    expect(checkbox.checked).toBe(true);
  });

  it('does not ask for confirmation when changing to the other state', async () => {
    const { checkbox, dialog } = await render({ checked: false });

    toggle(checkbox);

    expect(dialog.open).toBe(false);
  });

  it('asks for confirmation when checking with a checked trigger', async () => {
    const { checkbox, dialog } = await render({ checked: false, trigger: 'checked' });

    toggle(checkbox);

    expect(dialog.open).toBe(true);
  });
});
