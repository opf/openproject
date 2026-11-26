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

import { vi, type MockInstance } from 'vitest';

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import HierarchyItemController from './hierarchy-item.controller';

describe('Hierarchy item controller', () => {
  let ctx:StimulusTestContext;
  let fetchSpy:MockInstance<typeof window.fetch>;

  const item = (id:string, sortOrder:number) => `
    <li data-controller="admin--hierarchy-item"
        data-action="drop->admin--hierarchy-item#drop"
        data-hierarchy-item-id="${id}"
        data-sort-order="${sortOrder}"
        data-move-url="https://example.com/items/${id}/move"
        data-index-url="https://example.com/items">${id}</li>
  `;

  const drop = (target:Element, dragKey:string) => {
    const dataTransfer = new DataTransfer();
    dataTransfer.setData('application/dragkey', dragKey);
    target.dispatchEvent(new DragEvent('drop', { dataTransfer, bubbles: true, cancelable: true }));
  };

  beforeEach(async () => {
    fetchSpy = vi.spyOn(window, 'fetch').mockReturnValue(new Promise(() => undefined));
    ctx = await setupStimulusTest({ controllers: { 'admin--hierarchy-item': HierarchyItemController } });
    await ctx.mount(`<ul>${item('1', 0)}${item('2', 1)}</ul>`);
  });

  afterEach(() => {
    ctx.dispose();
    vi.restoreAllMocks();
  });

  it('moves the dragged item to the drop target', () => {
    drop(document.querySelector('[data-hierarchy-item-id="1"]')!, '2');

    expect(fetchSpy).toHaveBeenCalledExactlyOnceWith(
      new URL('https://example.com/items/2/move'),
      expect.objectContaining({ method: 'POST' }),
    );
  });

  it('ignores a drag key that names no item', () => {
    drop(document.querySelector('[data-hierarchy-item-id="1"]')!, "3'], [data-hierarchy-item-id='2");

    expect(fetchSpy).not.toHaveBeenCalled();
  });
});
