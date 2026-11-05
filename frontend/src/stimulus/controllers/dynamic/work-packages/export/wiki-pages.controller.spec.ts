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

import { waitFor } from '@testing-library/dom';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import type WikiPagesControllerType from './wiki-pages.controller';

describe('Work package export wiki pages controller', () => {
  let ctx:StimulusTestContext;
  let WikiPagesController:typeof WikiPagesControllerType;
  let added:{ id:string; name:string }[][] = [];

  function addedOptions():{ id:string; name:string }[][] {
    return added;
  }

  beforeAll(async () => {
    ({ default: WikiPagesController } = await import('./wiki-pages.controller'));
  });

  beforeEach(async () => {
    added = [];
    ctx = await setupStimulusTest({
      controllers: { 'work-packages--export--wiki-pages': WikiPagesController },
    });
  });

  afterEach(() => ctx.dispose());

  const identifier = 'work-packages--export--wiki-pages';

  function checkedInput(nodeId:string, path:string[]):string {
    return `<input type="hidden" value='${JSON.stringify({ path, nodeId })}'>`;
  }

  async function mount(checked = '') {
    await ctx.mount(`
      <div data-controller="${identifier}" data-${identifier}-provider-id-value="7">
        <opce-draggable-autocompleter data-${identifier}-target="autocompleter"></opce-draggable-autocompleter>
        <dialog data-${identifier}-target="dialog" data-action="close->${identifier}#resetTree">
          <div data-${identifier}-target="treeContainer">${checked}</div>
          <template data-${identifier}-target="treeTemplate"><div class="fresh-tree"></div></template>
          <button data-action="${identifier}#add">Add</button>
        </dialog>
      </div>
    `);

    document.querySelector<HTMLDialogElement>('dialog')!.show();
    document.querySelector('opce-draggable-autocompleter')!
      .addEventListener('op:draggable-autocompleter:add', (event) => {
        added.push((event as CustomEvent<{ id:string; name:string }[]>).detail);
      });

    return ctx.getController<WikiPagesControllerType>(identifier);
  }


  it('hands the autocompleter every checked page, labeled by its project', async () => {
    await mount(checkedInput('page:42', ['Arcanos', 'Legal information']));

    document.querySelector<HTMLButtonElement>('dialog button')!.click();

    expect(addedOptions()).toEqual([[{ id: '7:42', name: 'Arcanos: Legal information' }]]);
  });

  it('ignores nodes that are not pages', async () => {
    await mount(checkedInput('wiki:1', ['Arcanos']));

    document.querySelector<HTMLButtonElement>('dialog button')!.click();

    expect(addedOptions()).toEqual([[]]);
  });

  it('labels a page found by URL search, which has no project ancestor', async () => {
    await mount(checkedInput('page:42', ['Legal information']));

    document.querySelector<HTMLButtonElement>('dialog button')!.click();

    expect(addedOptions()).toEqual([[{ id: '7:42', name: 'Legal information' }]]);
  });

  it('replaces the tree with a fresh one once the dialog closes', async () => {
    await mount(checkedInput('page:42', ['Arcanos', 'Legal information']));

    document.querySelector<HTMLButtonElement>('dialog button')!.click();

    await waitFor(() => expect(document.querySelector('.fresh-tree')).not.toBeNull());
  });
});
