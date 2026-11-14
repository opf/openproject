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

import { RenderedMenuScope } from './rendered-menu-scope';

describe('RenderedMenuScope', () => {
  let container:HTMLElement;

  beforeEach(() => {
    container = document.createElement('ul');
    document.body.appendChild(container);
  });

  afterEach(() => {
    container.remove();
  });

  function scopeOwner(count:string|null, ids:string|null = null):HTMLElement {
    const list = document.createElement('ul');
    if (count !== null) list.setAttribute('data-sortable-lists-scope-count', count);
    if (ids !== null) list.setAttribute('data-sortable-lists-scope-ids', ids);
    return list;
  }

  function liveItems(...ids:string[]):HTMLElement[] {
    return ids.map((id) => {
      const item = document.createElement('li');
      item.setAttribute('data-sortable-lists--item-id-value', id);
      container.appendChild(item);
      return item;
    });
  }

  it('is absent for markup without a scope count', () => {
    expect(RenderedMenuScope.of(scopeOwner(null, '["1"]'))).toBeNull();
    expect(RenderedMenuScope.of(null)).toBeNull();
  });

  it('reads the scope from the nearest ancestor, itself included', () => {
    const owner = scopeOwner('3');
    const nested = document.createElement('li');
    owner.appendChild(nested);

    expect(RenderedMenuScope.of(owner)?.count).toBe(3);
    expect(RenderedMenuScope.of(nested)?.count).toBe(3);
  });

  it.each(['', 'x'])('falls back to one for the count %j', (count) => {
    expect(RenderedMenuScope.of(scopeOwner(count))?.count).toBe(1);
  });

  it('matches live items with the same ids in document order', () => {
    const [first, second] = liveItems('2', '3');
    const scope = RenderedMenuScope.of(scopeOwner('2', '["2","3"]'))!;

    expect(scope.matches([first, second])).toBe(true);
    expect(scope.matches([second, first])).toBe(true);
  });

  it('does not match when an item was added, removed or replaced', () => {
    const [first, second, third] = liveItems('2', '3', '4');
    const scope = RenderedMenuScope.of(scopeOwner('2', '["2","3"]'))!;

    expect(scope.matches([first, second, third])).toBe(false);
    expect(scope.matches([first])).toBe(false);
    expect(scope.matches([first, third])).toBe(false);
  });

  it('does not match rendered ids in another order than the document', () => {
    const items = liveItems('2', '3');

    expect(RenderedMenuScope.of(scopeOwner('2', '["3","2"]'))!.matches(items)).toBe(false);
  });

  it.each([
    ['missing', null],
    ['malformed', '{'],
    ['empty', '[]'],
    ['not strings', '[2,3]'],
    ['duplicated', '["2","2"]'],
    ['not a list', '"2"'],
  ])('does not match ids that are %s', (_name, ids) => {
    const items = liveItems('2', '3');

    expect(RenderedMenuScope.of(scopeOwner('2', ids))!.matches(items)).toBe(false);
  });

  it('does not match a live item without an id', () => {
    const [item] = liveItems('');

    expect(RenderedMenuScope.of(scopeOwner('1', '[""]'))!.matches([item])).toBe(false);
  });
});
