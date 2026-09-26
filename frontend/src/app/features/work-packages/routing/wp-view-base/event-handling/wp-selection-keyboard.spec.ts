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

import { createEvent, fireEvent } from '@testing-library/dom';
import { usePlatform } from 'core-common/testing/platform';
import {
  registerWorkPackageDeselectAll,
  registerWorkPackageSelectAll,
  WorkPackageSelectAllOptions,
} from './wp-selection-keyboard';

describe('registerWorkPackageSelectAll', () => {
  let roots:HTMLElement[];
  let destroyers:(() => void)[];

  usePlatform();

  beforeEach(() => {
    roots = [];
    destroyers = [];
  });

  afterEach(() => {
    destroyers.reverse().forEach((destroy) => destroy());
    roots.forEach((root) => root.remove());
  });

  function rootWithRows():HTMLElement {
    const root = document.createElement('div');
    root.innerHTML = `
      <table><tbody>
        <tr tabindex="0" class="wp-table--row" data-work-package-id="2" data-class-identifier="wp-row-2">
          <td>
            <span>Subject</span><span tabindex="0">Readonly focus target</span>
            <input><button>Action</button>
            <a href="/work_packages/2">Link</a><span role="button">ARIA action</span>
            <span contenteditable="true">Editable</span>
          </td>
        </tr>
        <tr tabindex="0" class="wp-table--row" data-work-package-id="3" data-class-identifier="wp-row-3">
          <td>Another subject</td>
        </tr>
      </tbody></table>
    `;
    document.body.append(root);
    roots.push(root);
    return root;
  }

  function register(options:WorkPackageSelectAllOptions):() => void {
    const destroy = registerWorkPackageSelectAll(options);
    destroyers.push(destroy);
    return destroy;
  }

  function shortcut(target:HTMLElement):boolean {
    return !fireEvent.keyDown(target, { key: 'a', ctrlKey: true });
  }

  it('selects all from the focused occurrence and disposes its listener', () => {
    const root = rootWithRows();
    const rows:RenderedWorkPackage[] = [
      { workPackageId: '2', classIdentifier: 'wp-row-2', hidden: false },
      { workPackageId: '3', classIdentifier: 'wp-row-3', hidden: false },
    ];
    const selectAll = vi.fn();
    const destroy = register({
      root,
      focusSelector: '.wp-table--row',
      occurrenceSelector: '[data-class-identifier]',
      rendered: () => rows,
      selectAll,
    });
    const row = root.querySelector<HTMLTableRowElement>('tr')!;

    const handled = shortcut(row);

    expect(handled).toBe(true);
    expect(selectAll).toHaveBeenCalledExactlyOnceWith(rows, rows[0]);

    selectAll.mockClear();
    destroy();
    destroyers = destroyers.filter((candidate) => candidate !== destroy);
    const afterDestroy = shortcut(row);

    expect(afterDestroy).toBe(false);
    expect(selectAll).not.toHaveBeenCalled();
  });

  it('leaves native and unresolved targets unhandled', () => {
    const root = rootWithRows();
    const row = root.querySelector<HTMLTableRowElement>('tr')!;
    const rendered:RenderedWorkPackage[] = [
      { workPackageId: '2', classIdentifier: 'wp-row-2', hidden: false },
    ];
    const selectAll = vi.fn();
    register({
      root,
      focusSelector: '.wp-table--row',
      occurrenceSelector: '.wp-table--row[data-work-package-id][data-class-identifier]',
      rendered: () => rendered,
      selectAll,
    });

    root.querySelectorAll<HTMLElement>('input, button, a, [role="button"], [contenteditable]')
      .forEach((target) => expect(shortcut(target)).toBe(false));
    expect(selectAll).not.toHaveBeenCalled();

    const subject = root.querySelector<HTMLElement>('td span')!;
    expect(shortcut(subject)).toBe(true);
    expect(selectAll).toHaveBeenCalledExactlyOnceWith(rendered, rendered[0]);
    selectAll.mockClear();

    const alreadyPrevented = createEvent.keyDown(row, { key: 'a', ctrlKey: true });
    alreadyPrevented.preventDefault();
    fireEvent(row, alreadyPrevented);
    expect(alreadyPrevented.defaultPrevented).toBe(true);
    expect(selectAll).not.toHaveBeenCalled();

    const group = document.createElement('tr');
    group.className = 'wp-table--row';
    row.after(group);
    const outsideFocus = document.createElement('div');
    root.append(outsideFocus);
    [group, outsideFocus].forEach((target) => {
      expect(shortcut(target)).toBe(false);
    });

    rendered.splice(0);
    expect(shortcut(row)).toBe(false);
    rendered.push({ workPackageId: '9', classIdentifier: 'wp-row-9', hidden: false });
    expect(shortcut(row)).toBe(false);
    expect(selectAll).not.toHaveBeenCalled();
  });

  it('selects all from a readonly focus target with tabindex', () => {
    const root = rootWithRows();
    const rendered:RenderedWorkPackage[] = [
      { workPackageId: '2', classIdentifier: 'wp-row-2', hidden: false },
    ];
    const selectAll = vi.fn();
    register({
      root,
      focusSelector: '.wp-table--row',
      occurrenceSelector: '.wp-table--row[data-work-package-id][data-class-identifier]',
      rendered: () => rendered,
      selectAll,
    });

    const target = root.querySelector<HTMLElement>('span[tabindex="0"]')!;
    const handled = shortcut(target);

    expect(handled).toBe(true);
    expect(selectAll).toHaveBeenCalledExactlyOnceWith(rendered, rendered[0]);
  });

  it('lets only the nearest registered view own a shortcut', () => {
    const outer = document.createElement('div');
    outer.innerHTML = `
      <div class="occurrence" data-work-package-id="1" data-class-identifier="outer-1">
        <div class="focus" tabindex="0">Outer
          <div class="inner-root">
            <div class="occurrence" data-work-package-id="2" data-class-identifier="inner-2">
              <div class="focus" tabindex="0">Inner</div>
            </div>
          </div>
        </div>
      </div>
    `;
    const sibling = document.createElement('div');
    sibling.innerHTML = `
      <div class="occurrence" data-work-package-id="3" data-class-identifier="sibling-3">
        <div class="focus" tabindex="0">Sibling</div>
      </div>
    `;
    document.body.append(outer, sibling);
    roots.push(outer, sibling);
    const inner = outer.querySelector<HTMLElement>('.inner-root')!;
    const outerRows:RenderedWorkPackage[] = [{ workPackageId: '1', classIdentifier: 'outer-1', hidden: false }];
    const innerRows:RenderedWorkPackage[] = [{ workPackageId: '2', classIdentifier: 'inner-2', hidden: false }];
    const siblingRows:RenderedWorkPackage[] = [{ workPackageId: '3', classIdentifier: 'sibling-3', hidden: false }];
    const outerSelectAll = vi.fn();
    const innerSelectAll = vi.fn();
    const siblingSelectAll = vi.fn();
    const shared = { focusSelector: '.focus', occurrenceSelector: '.occurrence' };
    register({ root: outer, rendered: () => outerRows, selectAll: outerSelectAll, ...shared });
    register({ root: inner, rendered: () => innerRows, selectAll: innerSelectAll, ...shared });
    register({ root: sibling, rendered: () => siblingRows, selectAll: siblingSelectAll, ...shared });

    const innerFocus = inner.querySelector<HTMLElement>('.focus')!;
    expect(shortcut(innerFocus)).toBe(true);
    expect(innerSelectAll).toHaveBeenCalledExactlyOnceWith(innerRows, innerRows[0]);
    expect(outerSelectAll).not.toHaveBeenCalled();
    expect(siblingSelectAll).not.toHaveBeenCalled();

    const siblingFocus = sibling.querySelector<HTMLElement>('.focus')!;
    expect(shortcut(siblingFocus)).toBe(true);
    expect(siblingSelectAll).toHaveBeenCalledExactlyOnceWith(siblingRows, siblingRows[0]);
    expect(outerSelectAll).not.toHaveBeenCalled();
  });

  it('handles a shortcut once after teardown and reattachment', () => {
    const root = rootWithRows();
    const row = root.querySelector<HTMLTableRowElement>('tr')!;
    const rows:RenderedWorkPackage[] = [{ workPackageId: '2', classIdentifier: 'wp-row-2', hidden: false }];
    const selectAll = vi.fn();
    const options:WorkPackageSelectAllOptions = {
      root,
      focusSelector: '.wp-table--row',
      occurrenceSelector: '[data-class-identifier]',
      rendered: () => rows,
      selectAll,
    };
    const firstDestroy = register(options);
    firstDestroy();
    destroyers = destroyers.filter((candidate) => candidate !== firstDestroy);
    register(options);

    expect(shortcut(row)).toBe(true);
    expect(selectAll).toHaveBeenCalledExactlyOnceWith(rows, rows[0]);
  });
});

describe('registerWorkPackageDeselectAll', () => {
  let roots:HTMLElement[];
  let destroyers:(() => void)[];

  beforeEach(() => {
    roots = [];
    destroyers = [];
  });

  afterEach(() => {
    destroyers.reverse().forEach((destroy) => destroy());
    roots.forEach((root) => root.remove());
  });

  function view(hasState = true) {
    const root = document.createElement('div');
    root.innerHTML = '<div class="wp-table--row" tabindex="0">Row</div>';
    document.body.append(root);
    roots.push(root);
    const clear = vi.fn();
    const destroy = registerWorkPackageDeselectAll({ root, hasState: () => hasState, clear });
    destroyers.push(destroy);
    return { root, clear, destroy };
  }

  function keydown(target:Element, init:KeyboardEventInit):KeyboardEvent {
    const event = createEvent.keyDown(target, init) as KeyboardEvent;
    fireEvent(target, event);
    return event;
  }

  it('clears every registered view from anywhere in the document', () => {
    const first = view();
    const second = view();
    const elsewhere = document.createElement('button');
    document.body.append(elsewhere);
    roots.push(elsewhere);

    expect(keydown(document.body, { key: 'Escape' }).defaultPrevented).toBe(true);
    expect(first.clear).toHaveBeenCalledOnce();
    expect(second.clear).toHaveBeenCalledOnce();

    expect(keydown(elsewhere, { key: 'Escape' }).defaultPrevented).toBe(true);
    expect(first.clear).toHaveBeenCalledTimes(2);
    expect(second.clear).toHaveBeenCalledTimes(2);
  });

  it('stops clearing a disposed view while the others survive', () => {
    const first = view();
    const second = view();
    first.destroy();
    destroyers = destroyers.filter((destroy) => destroy !== first.destroy);

    keydown(document.body, { key: 'Escape' });

    expect(first.clear).not.toHaveBeenCalled();
    expect(second.clear).toHaveBeenCalledOnce();
  });

  it('leaves Escape unconsumed when no view has state', () => {
    const { clear } = view(false);

    const event = keydown(document.body, { key: 'Escape' });

    expect(clear).not.toHaveBeenCalled();
    expect(event.defaultPrevented).toBe(false);
  });
});
