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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { registerPragmaticDndMorphAttributePreservation } from './pragmatic-dnd-morph-attributes';

describe('Pragmatic DnD morph attribute preservation', () => {
  function beforeMorphAttributeEvent(attributeName:string, mutationType = 'remove') {
    return new CustomEvent('turbo:before-morph-attribute', {
      bubbles: true,
      cancelable: true,
      detail: { attributeName, mutationType },
    });
  }

  function appendSortableRow():HTMLElement {
    const root = document.createElement('div');
    const element = document.createElement('li');

    root.setAttribute('data-controller', 'sortable-lists');
    root.appendChild(element);
    document.body.appendChild(root);

    return element;
  }

  beforeEach(() => {
    registerPragmaticDndMorphAttributePreservation();
  });

  afterEach(() => {
    document.body.replaceChildren();
  });

  it('preserves Pragmatic DnD drop target markers during Turbo morphs', () => {
    const element = appendSortableRow();
    const event = beforeMorphAttributeEvent('data-drop-target-for-element');

    element.setAttribute('data-drop-target-for-element', 'true');
    element.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
  });

  it('preserves the active drag marker during Turbo morphs', () => {
    const element = appendSortableRow();
    const event = beforeMorphAttributeEvent('data-dragging');

    element.setAttribute('data-dragging', 'source');
    element.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
  });

  it('lets marker attributes morph when the mutation is not a removal', () => {
    const element = appendSortableRow();
    const event = beforeMorphAttributeEvent('data-dragging', 'updated');

    element.setAttribute('data-dragging', 'source');
    element.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(false);
  });

  it('lets unrelated attributes continue morphing', () => {
    const element = appendSortableRow();
    const event = beforeMorphAttributeEvent('class');

    element.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(false);
  });

  it('lets marker attributes morph outside sortable lists roots', () => {
    const element = document.createElement('li');
    const event = beforeMorphAttributeEvent('data-dragging');

    element.setAttribute('data-dragging', 'source');
    document.body.appendChild(element);
    element.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(false);
  });
});
