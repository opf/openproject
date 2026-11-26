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

import { OpenProject } from 'core-app/core/setup/globals/openproject';
import { hasUnsavedChanges } from './meetings-helpers';

describe('hasUnsavedChanges', () => {
  let originalOpenProject:typeof window.OpenProject;
  let container:HTMLElement;

  beforeEach(() => {
    originalOpenProject = window.OpenProject;
    window.OpenProject = new OpenProject();

    container = document.createElement('div');
    document.body.append(container);
  });

  afterEach(() => {
    container.remove();
    window.OpenProject = originalOpenProject;
  });

  function render(html:string):HTMLElement {
    container.innerHTML = html;
    return container.querySelector('[data-root]')!;
  }

  it('ignores dirty inputs outside the root', () => {
    const root = render(`
      <div data-root><input type="text" data-initial-value="A" value="A"></div>
      <input type="text" value="typed">
    `);

    expect(hasUnsavedChanges(root)).toBe(false);
  });

  it('detects a changed input inside the root', () => {
    const root = render('<div data-root><input type="text" data-initial-value="A" value="B"></div>');

    expect(hasUnsavedChanges(root)).toBe(true);
  });

  it('treats typing into an empty input without initial value as dirty', () => {
    const root = render('<div data-root><input type="number"></div>');
    root.querySelector('input')!.value = '15';

    expect(hasUnsavedChanges(root)).toBe(true);
  });

  it('ignores typing only whitespace into an input without initial value', () => {
    const root = render('<div data-root><input type="text"></div>');
    root.querySelector('input')!.value = '   ';

    expect(hasUnsavedChanges(root)).toBe(false);
  });

  it('treats a prefilled input without initial value as clean until changed', () => {
    const root = render('<div data-root><input type="text" value="Section A"></div>');

    expect(hasUnsavedChanges(root)).toBe(false);

    root.querySelector('input')!.value = 'Section B';

    expect(hasUnsavedChanges(root)).toBe(true);
  });

  it('reports pageWasEdited', () => {
    window.OpenProject.pageState = 'edited';
    const root = render('<div data-root><input type="text" data-initial-value="A" value="A"></div>');

    expect(hasUnsavedChanges(root)).toBe(true);
  });
});
