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

import { isTextEditable } from './interactive-element-helper';

function inputOfType(type:string):HTMLInputElement {
  const input = document.createElement('input');
  input.type = type;
  return input;
}

describe('isTextEditable', () => {
  it.each(['text', 'search', 'number', 'email', 'date'])('accepts input type %s', (type) => {
    expect(isTextEditable(inputOfType(type))).toBe(true);
  });

  it.each([
    'checkbox', 'radio', 'button', 'submit', 'reset', 'file', 'range', 'color', 'image', 'hidden',
  ])('rejects input type %s', (type) => {
    expect(isTextEditable(inputOfType(type))).toBe(false);
  });

  it('accepts a textarea and a contenteditable element', () => {
    const editable = document.createElement('div');
    editable.contentEditable = 'true';
    document.body.appendChild(editable);

    expect(isTextEditable(document.createElement('textarea'))).toBe(true);
    expect(isTextEditable(editable)).toBe(true);

    editable.remove();
  });

  it('rejects a disabled text input and a disabled textarea', () => {
    const input = inputOfType('text');
    input.disabled = true;
    const textarea = document.createElement('textarea');
    textarea.disabled = true;

    expect(isTextEditable(input)).toBe(false);
    expect(isTextEditable(textarea)).toBe(false);
  });

  it('accepts a readonly text input', () => {
    const input = inputOfType('text');
    input.readOnly = true;

    expect(isTextEditable(input)).toBe(true);
  });

  it('rejects a button, a span and null', () => {
    expect(isTextEditable(document.createElement('button'))).toBe(false);
    expect(isTextEditable(document.createElement('span'))).toBe(false);
    expect(isTextEditable(null)).toBe(false);
  });
});
