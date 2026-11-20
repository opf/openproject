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

import { fireEvent, within } from '@testing-library/dom';
import { suspendDraggableWhileEditing } from './suspend-draggable-while-editing';

describe('suspendDraggableWhileEditing', () => {
  let item:HTMLElement;
  let input:HTMLElement;
  let textarea:HTMLElement;
  let checkbox:HTMLElement;
  let button:HTMLElement;
  let label:HTMLElement;

  beforeEach(() => {
    item = document.createElement('div');
    item.setAttribute('draggable', 'true');
    item.innerHTML = `
      <input type="text" aria-label="Subject">
      <textarea aria-label="Description"></textarea>
      <input type="checkbox" aria-label="Done">
      <button type="button">Open</button>
      <span>Label</span>
    `;
    document.body.appendChild(item);

    const fields = within(item);
    input = fields.getByRole('textbox', { name: 'Subject' });
    textarea = fields.getByRole('textbox', { name: 'Description' });
    checkbox = fields.getByRole('checkbox', { name: 'Done' });
    button = fields.getByRole('button', { name: 'Open' });
    label = fields.getByText('Label');
  });

  afterEach(() => {
    document.body.replaceChildren();
  });

  it('suspends dragging while a text field has focus', () => {
    suspendDraggableWhileEditing(item);

    fireEvent.focusIn(input);

    expect(item).toHaveAttribute('draggable', 'false');
  });

  it('restores dragging when focus leaves the item', () => {
    suspendDraggableWhileEditing(item);

    fireEvent.focusIn(input);
    fireEvent.focusOut(input, { relatedTarget: null });

    expect(item).toHaveAttribute('draggable', 'true');
  });

  it('stays suspended when focus moves to another text field in the item', () => {
    suspendDraggableWhileEditing(item);

    fireEvent.focusIn(input);
    fireEvent.focusOut(input, { relatedTarget: textarea });

    expect(item).toHaveAttribute('draggable', 'false');
  });

  it('restores dragging when focus moves to a non-text control in the item', () => {
    suspendDraggableWhileEditing(item);

    fireEvent.focusIn(input);
    fireEvent.focusOut(input, { relatedTarget: checkbox });

    expect(item).toHaveAttribute('draggable', 'true');
  });

  it('leaves dragging on when a non-text control gains focus', () => {
    suspendDraggableWhileEditing(item);

    fireEvent.focusIn(button);

    expect(item).toHaveAttribute('draggable', 'true');
  });

  it('suspends at setup when a text field in the item is already focused', () => {
    input.focus();
    expect(input).toHaveFocus();

    suspendDraggableWhileEditing(item);

    expect(item).toHaveAttribute('draggable', 'false');
  });

  it('suspends on pointerdown in a text field before it has focus', () => {
    suspendDraggableWhileEditing(item);

    fireEvent.pointerDown(input);

    expect(item).toHaveAttribute('draggable', 'false');
  });

  it('restores on the next pointerdown after the focused field was removed without focusout', () => {
    suspendDraggableWhileEditing(item);

    fireEvent.focusIn(input);
    input.remove();
    fireEvent.pointerDown(label);

    expect(item).toHaveAttribute('draggable', 'true');
  });

  it('cleanup stops reacting and leaves the attribute alone', () => {
    const cleanup = suspendDraggableWhileEditing(item);

    fireEvent.focusIn(input);
    cleanup();
    expect(item).toHaveAttribute('draggable', 'false');

    fireEvent.focusOut(input, { relatedTarget: null });
    expect(item).toHaveAttribute('draggable', 'false');

    item.removeAttribute('draggable');
    fireEvent.pointerDown(label);
    expect(item).not.toHaveAttribute('draggable');
  });
});
