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

import { act, createElement } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { AddWorkPackageCard } from './AddWorkPackageCard';

describe('AddWorkPackageCard', () => {
  let container:HTMLElement;
  let root:Root;
  let onAdd:ReturnType<typeof vi.fn<(id:string) => void>>;

  const query = <T extends Element>(selector:string) => container.querySelector<T>(selector);

  function openForm() {
    act(() => query<HTMLButtonElement>('[data-test-selector="whiteboard-add-work-package"]')!.click());
  }

  function submit(text:string) {
    const input = query<HTMLInputElement>('[data-test-selector="whiteboard-add-work-package-input"]')!;
    act(() => {
      Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')!.set!.call(input, text);
      input.dispatchEvent(new Event('input', { bubbles: true }));
    });
    act(() => input.form!.requestSubmit());
  }

  beforeAll(() => {
    (globalThis as { IS_REACT_ACT_ENVIRONMENT?:boolean }).IS_REACT_ACT_ENVIRONMENT = true;
  });

  beforeEach(() => {
    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
    onAdd = vi.fn<(id:string) => void>();
    act(() => root.render(createElement(AddWorkPackageCard, { onAdd })));
  });

  afterEach(() => {
    act(() => root.unmount());
    container.remove();
  });

  it('adds the work package that was typed or pasted into the field', () => {
    openForm();
    submit(`${window.location.origin}/work_packages/42/activity`);

    expect(onAdd).toHaveBeenCalledWith('42');
    expect(query('form')).toBeNull();
  });

  it('keeps the form open and explains what is accepted for other input', () => {
    openForm();
    submit('something else');

    expect(onAdd).not.toHaveBeenCalled();
    expect(query('[role="alert"]')).not.toBeNull();
  });
});
