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
import type TypeProjectsSelectionControllerType from './type-projects-selection.controller';

describe('Type projects selection controller', () => {
  let ctx:StimulusTestContext;
  let TypeProjectsSelectionController:typeof TypeProjectsSelectionControllerType;

  beforeAll(async () => {
    ({ default: TypeProjectsSelectionController } = await import('./type-projects-selection.controller'));
  });

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'admin--type-projects-selection': TypeProjectsSelectionController },
    });
  });

  afterEach(() => {
    ctx.dispose();
  });

  function row(id:string, selected:boolean) {
    return `
      <div data-sortable-lists--item-id-value="${id}" ${selected ? 'data-batch-selected' : ''}>
        <action-menu>
          <button type="button" aria-haspopup="true" id="menu-${id}-button">More</button>
          <ul>
            <li data-type-projects-selection-scope="single"><a href="/single/switch?project_ids[]=${id}">Switch variant</a></li>
            <li data-type-projects-selection-scope="single"><a href="/single/remove?project_ids[]=${id}">Remove type from this project</a></li>
            <li data-type-projects-selection-scope="batch" hidden><a data-type-projects-selection-action="switch" href="#">Switch variant</a></li>
            <li data-type-projects-selection-scope="batch" hidden><a data-type-projects-selection-action="remove" href="#">Remove type from these projects</a></li>
          </ul>
        </action-menu>
      </div>
    `;
  }

  async function renderTable(selected:string[]) {
    await ctx.mount(`
      <div data-controller="admin--type-projects-selection"
           data-admin--type-projects-selection-switch-url-value="/types/1/projects/switch/new"
           data-admin--type-projects-selection-remove-url-value="/types/1/projects/link/deletion/new">
        ${['1', '2', '3'].map((id) => row(id, selected.includes(id))).join('')}
      </div>
    `);
  }

  function rowElement(id:string) {
    return ctx.container.querySelector<HTMLElement>(`[data-sortable-lists--item-id-value="${id}"]`)!;
  }

  function invokeContextMenu(id:string) {
    rowElement(id).dispatchEvent(new CustomEvent('contextual-action-menu:beforeOpen', { bubbles: true, cancelable: true }));
  }

  function visibleScopes(id:string) {
    return Array.from(rowElement(id).querySelectorAll<HTMLElement>('[data-type-projects-selection-scope]'))
      .filter((item) => !item.hidden)
      .map((item) => item.dataset.typeProjectsSelectionScope);
  }

  function batchHref(id:string, action:string) {
    return rowElement(id).querySelector(`a[data-type-projects-selection-action="${action}"]`)!.getAttribute('href');
  }

  it('acts on the whole selection from a selected row', async () => {
    await renderTable(['1', '2']);

    invokeContextMenu('2');

    expect(visibleScopes('2')).toEqual(['batch', 'batch']);
    expect(batchHref('2', 'switch')).toBe('/types/1/projects/switch/new?project_ids%5B%5D=1&project_ids%5B%5D=2');
    expect(batchHref('2', 'remove')).toBe('/types/1/projects/link/deletion/new?project_ids%5B%5D=1&project_ids%5B%5D=2');
  });

  it('acts on the row alone when it is outside the selection', async () => {
    await renderTable(['1', '2']);

    invokeContextMenu('3');

    expect(visibleScopes('3')).toEqual(['single', 'single']);
  });

  it('treats a selection of one row as that row alone', async () => {
    await renderTable(['2']);

    invokeContextMenu('2');

    expect(visibleScopes('2')).toEqual(['single', 'single']);
  });

  it('gives the kebab the same scope as the right-click', async () => {
    await renderTable(['1', '2']);

    rowElement('2').querySelector<HTMLElement>('[aria-haspopup="true"]')!.click();

    expect(visibleScopes('2')).toEqual(['batch', 'batch']);
  });

  it('returns to the single row once the selection is gone', async () => {
    await renderTable(['1', '2']);
    invokeContextMenu('2');

    rowElement('1').removeAttribute('data-batch-selected');
    rowElement('2').removeAttribute('data-batch-selected');
    invokeContextMenu('2');

    expect(visibleScopes('2')).toEqual(['single', 'single']);
  });
});
