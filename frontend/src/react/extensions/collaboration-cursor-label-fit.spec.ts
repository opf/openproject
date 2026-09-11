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

import { EditorView } from 'prosemirror-view';
import { vi } from 'vitest';
import {
  BELOW_ATTRIBUTE,
  CollaborationCursorLabelFitExtension,
  fitCollaborationCursorLabels,
  FLIPPED_ATTRIBUTE,
} from './collaboration-cursor-label-fit';

const EDITOR_WIDTH = 300;
const EDITOR_HEIGHT = 200;
const TABLE_WIDTH = 150;

const OPEN_SPACE = { left: 10, top: 60 };
// Wider than the 20rem BlockNote will ever draw a label at.
const LONG_NAME = 'Ivana Dubas '.repeat(30);
const AGAINST_RIGHT = { ...OPEN_SPACE, left: EDITOR_WIDTH - 20 };
const AGAINST_TOP = { ...OPEN_SPACE, top: 5 };

function buildEditor(width:number = EDITOR_WIDTH):HTMLElement {
  const editor = document.createElement('div');
  editor.className = 'bn-editor';
  editor.setAttribute('style', `position: relative; width: ${width}px; height: ${EDITOR_HEIGHT}px; overflow: hidden; font: 12px sans-serif`);
  document.body.appendChild(editor);

  return editor;
}

// A table's scroll container: narrower than the editor and clipping on both axes, so
// it - not the editor - is the box a label inside it has to fit. Sits 80px down, which
// leaves every position inside it well clear of the editor's own edges.
function buildTableWrapper(editor:HTMLElement):HTMLElement {
  const wrapper = document.createElement('div');
  wrapper.className = 'tableWrapper';
  wrapper.setAttribute('style', `position: absolute; left: 0; top: 80px; width: ${TABLE_WIDTH}px; height: 60px; overflow-x: auto; overflow-y: hidden`);
  editor.appendChild(wrapper);

  return wrapper;
}

// BlockNote collapses an idle label to a nub and expands it while its author is typing.
// Both states have to reach the same verdict, so tests can ask for either.
const COLLAPSED_LABEL = 'top: -1px; max-width: 4px; padding: 0';
const EXPANDED_LABEL = 'top: -17px; max-width: 20rem; padding: 0.1rem 0.3rem';

interface CursorOptions {
  expanded?:boolean;
  name?:string;
}

function addCursor(
  parent:HTMLElement,
  { left, top }:{ left:number, top:number },
  { expanded = false, name = 'Ivana Dubas' }:CursorOptions = {},
):HTMLElement {
  const base = document.createElement('span');
  base.className = 'bn-collaboration-cursor__base';
  base.setAttribute('style', `position: absolute; left: ${left}px; top: ${top}px`);

  const label = document.createElement('span');
  label.className = 'bn-collaboration-cursor__label';
  label.setAttribute('style', `position: absolute; left: 0; white-space: nowrap; overflow: hidden; ${expanded ? EXPANDED_LABEL : COLLAPSED_LABEL}`);
  label.textContent = name;

  base.appendChild(label);
  parent.appendChild(base);

  return base;
}

function textWidthOf(base:HTMLElement):number {
  return (base.firstElementChild as HTMLElement).scrollWidth;
}

function nextFrame():Promise<void> {
  return new Promise((resolve) => { requestAnimationFrame(() => resolve()); });
}

describe('fitCollaborationCursorLabels', () => {
  let editor:HTMLElement;

  beforeEach(() => {
    editor = buildEditor();
  });

  afterEach(() => {
    document.querySelectorAll('.bn-editor').forEach((node) => node.remove());
    document.documentElement.style.fontSize = '';
  });

  describe('at the right edge', () => {
    it('flips a label that would run past the editor', () => {
      const base = addCursor(editor, AGAINST_RIGHT);

      fitCollaborationCursorLabels(editor);

      expect(base.hasAttribute(FLIPPED_ATTRIBUTE)).toBe(true);
    });

    it('leaves a label that fits where BlockNote put it', () => {
      const base = addCursor(editor, OPEN_SPACE);

      fitCollaborationCursorLabels(editor);

      expect(base.hasAttribute(FLIPPED_ATTRIBUTE)).toBe(false);
    });

    it('counts the padding of an expanded label once', () => {
      const collapsed = addCursor(editor, OPEN_SPACE);
      const textWidth = textWidthOf(collapsed);
      collapsed.remove();

      // Room for the label's own padding and four pixels to spare, so it only overflows
      // if that padding - which `scrollWidth` already carries here - is counted twice.
      const base = addCursor(editor, { ...OPEN_SPACE, left: EDITOR_WIDTH - textWidth - 15 }, { expanded: true });

      fitCollaborationCursorLabels(editor);

      expect(base.hasAttribute(FLIPPED_ATTRIBUTE)).toBe(false);
    });

    it('reserves no more than the width BlockNote caps a label at', () => {
      const wide = buildEditor(600);
      const base = addCursor(wide, OPEN_SPACE, { expanded: true, name: LONG_NAME });

      fitCollaborationCursorLabels(wide);

      expect(base.hasAttribute(FLIPPED_ATTRIBUTE)).toBe(false);
    });

    it('reads that cap in rem, as a reader with a larger default font gets it', () => {
      // 20rem of label clears a 380px editor at the browser default, but not at 20px.
      document.documentElement.style.fontSize = '20px';
      const wide = buildEditor(380);
      const base = addCursor(wide, OPEN_SPACE, { expanded: true, name: LONG_NAME });

      fitCollaborationCursorLabels(wide);

      expect(base.hasAttribute(FLIPPED_ATTRIBUTE)).toBe(true);
    });

    it('unflips once the cursor moves back into open space', () => {
      const base = addCursor(editor, AGAINST_RIGHT);
      fitCollaborationCursorLabels(editor);

      base.style.left = `${OPEN_SPACE.left}px`;
      fitCollaborationCursorLabels(editor);

      expect(base.hasAttribute(FLIPPED_ATTRIBUTE)).toBe(false);
    });
  });

  describe('at the top edge', () => {
    it('drops a label that would run above the editor below the caret', () => {
      const base = addCursor(editor, AGAINST_TOP);

      fitCollaborationCursorLabels(editor);

      expect(base.hasAttribute(BELOW_ATTRIBUTE)).toBe(true);
    });

    it('leaves a label with room above it where BlockNote put it', () => {
      const base = addCursor(editor, OPEN_SPACE);

      fitCollaborationCursorLabels(editor);

      expect(base.hasAttribute(BELOW_ATTRIBUTE)).toBe(false);
    });

    it('lifts the label back once the cursor moves down', () => {
      const base = addCursor(editor, AGAINST_TOP);
      fitCollaborationCursorLabels(editor);

      base.style.top = `${OPEN_SPACE.top}px`;
      fitCollaborationCursorLabels(editor);

      expect(base.hasAttribute(BELOW_ATTRIBUTE)).toBe(false);
    });

    it('flips both ways in the top right corner', () => {
      const base = addCursor(editor, { left: AGAINST_RIGHT.left, top: AGAINST_TOP.top });

      fitCollaborationCursorLabels(editor);

      expect(base.hasAttribute(FLIPPED_ATTRIBUTE)).toBe(true);
      expect(base.hasAttribute(BELOW_ATTRIBUTE)).toBe(true);
    });
  });

  describe('inside a table', () => {
    let wrapper:HTMLElement;

    beforeEach(() => {
      wrapper = buildTableWrapper(editor);
    });

    it('measures against the table, not the editor, on the right', () => {
      // The label still fits the 300px editor from here, but not the 150px table.
      const base = addCursor(wrapper, { left: TABLE_WIDTH - 50, top: 30 });

      fitCollaborationCursorLabels(editor);

      expect(base.hasAttribute(FLIPPED_ATTRIBUTE)).toBe(true);
    });

    it('measures against the table, not the editor, on top', () => {
      const base = addCursor(wrapper, { left: 10, top: 2 });

      fitCollaborationCursorLabels(editor);

      expect(base.hasAttribute(BELOW_ATTRIBUTE)).toBe(true);
    });

    it('keeps a first row\'s label above, where it fits by a hair', () => {
      // A real first row leaves the label its full 17px rise and not a pixel more (9px
      // of table-wrapper padding, 5px of cell padding, 1px of border, 2px of line box),
      // so rounding alone must not throw the label under the caret.
      const base = addCursor(wrapper, { left: 10, top: 16 });

      fitCollaborationCursorLabels(editor);

      expect(base.hasAttribute(BELOW_ATTRIBUTE)).toBe(false);
    });

    it('leaves a cursor with room inside the table alone', () => {
      const base = addCursor(wrapper, { left: 10, top: 30 });

      fitCollaborationCursorLabels(editor);

      expect(base.hasAttribute(FLIPPED_ATTRIBUTE)).toBe(false);
      expect(base.hasAttribute(BELOW_ATTRIBUTE)).toBe(false);
    });
  });
});

describe('CollaborationCursorLabelFitExtension', () => {
  let editor:HTMLElement;

  function mountPlugin():{ update:() => void, destroy:() => void } {
    const [plugin] = CollaborationCursorLabelFitExtension({} as never).prosemirrorPlugins ?? [];
    const view = plugin.spec.view?.({ dom: editor } as unknown as EditorView);

    return view as unknown as { update:() => void, destroy:() => void };
  }

  beforeEach(() => {
    editor = buildEditor();
  });

  afterEach(() => {
    document.querySelectorAll('.bn-editor').forEach((node) => node.remove());
    vi.restoreAllMocks();
  });

  it('coalesces a burst of updates into a single measurement', async () => {
    const base = addCursor(editor, AGAINST_RIGHT);
    const plugin = mountPlugin();
    const frames = vi.spyOn(window, 'requestAnimationFrame');

    plugin.update();
    plugin.update();
    plugin.update();

    expect(frames).toHaveBeenCalledTimes(1);

    await nextFrame();

    expect(base.hasAttribute(FLIPPED_ATTRIBUTE)).toBe(true);

    plugin.destroy();
  });

  it('stops measuring once the view is destroyed', async () => {
    const base = addCursor(editor, AGAINST_RIGHT);
    const plugin = mountPlugin();

    plugin.update();
    plugin.destroy();
    await nextFrame();

    expect(base.hasAttribute(FLIPPED_ATTRIBUTE)).toBe(false);
  });
});
