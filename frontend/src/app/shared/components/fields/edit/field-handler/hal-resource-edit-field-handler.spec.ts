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

import { States } from 'core-app/core/states/states.service';
import { buildTable, TableHarness } from 'core-app/features/work-packages/components/wp-fast-table/testing/table-harness';
import { TableEditForm } from 'core-app/features/work-packages/components/wp-edit-form/table-edit-form';
import { HalResourceEditFieldHandler } from './hal-resource-edit-field-handler';

describe('HalResourceEditFieldHandler focus ownership', () => {
  let harness:TableHarness;
  let form:TableEditForm;
  let handler:HalResourceEditFieldHandler;
  let external:HTMLButtonElement;

  beforeEach(async () => {
    harness = buildTable({
      workPackages: [{ id: '1' }],
      editing: {},
      productionMarkup: true,
      configuration: { keyboardNavigationEnabled: true },
    });
    await harness.render();
    const wp = harness.injector.get(States).workPackages.get('1').value!;
    harness.table.editing.startEditing(wp, harness.row('1').dataset.classIdentifier!);
    form = harness.table.editing.forms['1'];
    handler = await form.activate('subject') as HalResourceEditFieldHandler;
    external = document.createElement('button');
    document.body.append(external);
  });

  afterEach(async () => {
    external.remove();
    await harness.destroy();
  });

  it('leaves grid editor focus to keyboard navigation', () => {
    expect(handler.allowsAutofocus()).toBe(false);
  });

  it('retains autofocus when keyboard navigation is disabled', () => {
    harness.table.configuration.keyboardNavigationEnabled = false;

    expect(handler.allowsAutofocus()).toBe(true);
  });

  it('retains autofocus outside the grid', () => {
    const container = form.findContainer('subject')!;
    const parent = container.parentElement!;
    document.body.append(container);

    try {
      expect(handler.allowsAutofocus()).toBe(true);
    } finally {
      parent.append(container);
    }
  });

  it('marks the input invalid when errors are set and when it is focused afterwards', () => {
    const input = harness.row('1').querySelector<HTMLInputElement>('input.inline-edit--field')!;
    expect(input).not.toHaveAttribute('aria-invalid');

    handler.setErrors(['Required']);
    expect(input).toHaveAttribute('aria-invalid', 'true');

    input.removeAttribute('aria-invalid');
    handler.focus();
    expect(input).toHaveAttribute('aria-invalid', 'true');
    expect(input).toHaveFocus();
  });

  it('preserves focus in an unregistered foreign overlay', () => {
    external.focus();

    handler.blurActiveField();

    expect(external).toHaveFocus();
  });

  it('blurs focus inside a registered overlay', () => {
    handler.registerOverlay(external);
    external.focus();

    handler.blurActiveField();

    expect(external).not.toHaveFocus();
  });

  it('deactivates only once when an overlay close is reported twice', () => {
    const reset = vi.spyOn(form, 'reset');

    handler.deactivate(false, true);
    handler.deactivate(false, true);

    expect(reset).toHaveBeenCalledOnce();
  });

  it('marks and owns overlays only in their registering table', async () => {
    handler.registerOverlay(external);

    expect(external.dataset.wpTableEditor).toBe(harness.table.editing.ownerId);
    expect(harness.table.editing.owns(external)).toBe(true);

    const second = buildTable({ workPackages: [{ id: '1' }], productionMarkup: true });
    await second.render();
    expect(second.table.editing.owns(external)).toBe(false);
    expect(external.dataset.wpTableEditor).not.toBe(second.table.editing.ownerId);
    await second.destroy();
  });

  it('returns to the origin after an owned overlay closes', () => {
    const cell = harness.row('1').querySelector<HTMLElement>('td.subject')!;
    const origin = harness.table.keyboardNavigation!.positionOfCell(cell)!;
    harness.table.keyboardNavigation!.recordPosition(origin);
    handler.registerOverlay(external);
    external.focus();
    handler.deactivate(false);

    harness.table.keyboardNavigation!.returnFocus(origin, handler);

    expect(cell).toHaveFocus();
  });

  it('does not return when a foreign overlay owns focus', () => {
    const cell = harness.row('1').querySelector<HTMLElement>('td.subject')!;
    const origin = harness.table.keyboardNavigation!.positionOfCell(cell)!;
    harness.table.keyboardNavigation!.recordPosition(origin);
    external.focus();
    handler.deactivate(false);

    harness.table.keyboardNavigation!.returnFocus(origin, handler);

    expect(external).toHaveFocus();
    expect(cell).not.toHaveFocus();
  });

  it('does not return after focus leaves an owned overlay for an external control', () => {
    const cell = harness.row('1').querySelector<HTMLElement>('td.subject')!;
    const origin = harness.table.keyboardNavigation!.positionOfCell(cell)!;
    harness.table.keyboardNavigation!.recordPosition(origin);
    const overlay = document.createElement('div');
    const overlayButton = document.createElement('button');
    overlay.append(overlayButton);
    document.body.append(overlay);
    handler.registerOverlay(overlay);
    overlayButton.focus();
    external.focus();
    handler.deactivate(false);

    harness.table.keyboardNavigation!.returnFocus(origin, handler);

    expect(external).toHaveFocus();
    expect(cell).not.toHaveFocus();
    overlay.remove();
  });
});
