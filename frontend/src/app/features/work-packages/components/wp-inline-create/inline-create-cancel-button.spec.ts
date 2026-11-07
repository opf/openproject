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

import { Injector } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent, screen } from '@testing-library/dom';
import { InlineCreateCancelButton, inlineCreateCancelClassName } from './inline-create-cancel-button';

describe('InlineCreateCancelButton', () => {
  const mount = (onCancel = vi.fn()) => {
    const cancelButton = new InlineCreateCancelButton(TestBed.inject(Injector), 'Cancel', onCancel);
    document.body.append(cancelButton.element);
    return cancelButton;
  };

  afterEach(() => {
    document.body.replaceChildren();
    TestBed.resetTestingModule();
  });

  it('renders an invisible icon button named by its label', () => {
    const cancelButton = mount();

    const button = screen.getByRole('button', { name: 'Cancel' });
    expect(button).toHaveClass('Button--invisible', 'Button--iconOnly');
    expect(cancelButton.element).toHaveClass(inlineCreateCancelClassName);
  });

  it('cancels on click', () => {
    const onCancel = vi.fn();
    mount(onCancel);

    fireEvent.click(screen.getByRole('button', { name: 'Cancel' }));

    expect(onCancel).toHaveBeenCalledOnce();
  });

  it('keeps working after its element moves to another cell', () => {
    const onCancel = vi.fn();
    const cancelButton = mount(onCancel);
    const cell = document.createElement('td');
    document.body.append(cell);

    cell.append(cancelButton.element);
    fireEvent.click(screen.getByRole('button', { name: 'Cancel' }));

    expect(onCancel).toHaveBeenCalledOnce();
  });

  it('leaves the DOM and stops responding once destroyed', () => {
    const onCancel = vi.fn();
    const cancelButton = mount(onCancel);
    const button = screen.getByRole('button', { name: 'Cancel' });

    cancelButton.destroy();
    fireEvent.click(button);

    expect(button).not.toBeInTheDocument();
    expect(onCancel).not.toHaveBeenCalled();
  });
});
