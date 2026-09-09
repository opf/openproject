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

import {
  fitCollaborationCursorLabels,
  FLIPPED_ATTRIBUTE,
} from './collaboration-cursor-label-fit';

const EDITOR_WIDTH = 300;

function buildEditor(caretLeft:number):{ editor:HTMLElement, base:HTMLElement } {
  const editor = document.createElement('div');
  editor.className = 'bn-editor';
  editor.setAttribute('style', `position: relative; width: ${EDITOR_WIDTH}px; overflow: hidden; font: 12px sans-serif`);

  const base = document.createElement('span');
  base.className = 'bn-collaboration-cursor__base';
  base.setAttribute('style', `position: absolute; left: ${caretLeft}px; top: 20px`);

  const label = document.createElement('span');
  label.className = 'bn-collaboration-cursor__label';
  label.setAttribute('style', 'position: absolute; left: 0; top: -17px; white-space: nowrap; overflow: hidden; max-width: 4px; padding: 0');
  label.textContent = 'Ivana Dubas';

  base.appendChild(label);
  editor.appendChild(base);
  document.body.appendChild(editor);

  return { editor, base };
}

describe('fitCollaborationCursorLabels', () => {
  afterEach(() => {
    document.querySelectorAll('.bn-editor').forEach((node) => node.remove());
  });

  it('flips a label that would run past the editor', () => {
    const { editor, base } = buildEditor(EDITOR_WIDTH - 20);

    fitCollaborationCursorLabels(editor);

    expect(base.hasAttribute(FLIPPED_ATTRIBUTE)).toBe(true);
  });

  it('leaves a label that fits alone', () => {
    const { editor, base } = buildEditor(10);

    fitCollaborationCursorLabels(editor);

    expect(base.hasAttribute(FLIPPED_ATTRIBUTE)).toBe(false);
  });

  it('unflips once the cursor moves back into open space', () => {
    const { editor, base } = buildEditor(EDITOR_WIDTH - 20);
    fitCollaborationCursorLabels(editor);

    base.style.left = '10px';
    fitCollaborationCursorLabels(editor);

    expect(base.hasAttribute(FLIPPED_ATTRIBUTE)).toBe(false);
  });
});
