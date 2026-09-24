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

import { BlockNoteEditor, PartialBlock } from '@blocknote/core';
import { NodeSelection, TextSelection } from 'prosemirror-state';
import { userEvent } from 'vitest/browser';
import { KeyboardAwareScrollExtension } from './keyboard-aware-scroll';

const KEYBOARD_HEIGHT = 300;
const LINE_HEIGHT = 24;
const PARAGRAPHS = 80;

// A keyboard cannot be summoned in a test; all it does is shrink the visual viewport.
class StandInViewport extends EventTarget {
  occluded = 0;

  scale = 1;

  get height():number { return (window.innerHeight - this.occluded) / this.scale; }

  resize(changes:Partial<Pick<StandInViewport, 'occluded'|'scale'>>):void {
    Object.assign(this, changes);
    this.dispatchEvent(new Event('resize'));
  }
}

const keyboardTop = () => window.innerHeight - KEYBOARD_HEIGHT;

function nextFrame():Promise<void> {
  return new Promise((resolve) => { requestAnimationFrame(() => resolve()); });
}

describe('KeyboardAwareScrollExtension', () => {
  let viewport:StandInViewport;
  // Screen-tall like #content-wrapper, so its bottom runs under the keyboard.
  let scroller:HTMLElement;
  let editor:BlockNoteEditor|undefined;

  const raiseKeyboard = () => viewport.resize({ occluded: KEYBOARD_HEIGHT });
  const view = () => editor!.prosemirrorView;
  const caretBottom = () => view().coordsAtPos(view().state.selection.head, 1).bottom;

  function mountEditor(parent:Element|ShadowRoot = scroller, blocks:PartialBlock[] = []):void {
    const paragraphs = Array.from({ length: PARAGRAPHS }, (_, index):PartialBlock => ({
      type: 'paragraph',
      content: `Paragraph ${index + 1}`,
    }));
    editor = BlockNoteEditor.create({
      initialContent: [...paragraphs.slice(0, PARAGRAPHS / 2), ...blocks, ...paragraphs.slice(PARAGRAPHS / 2)],
      extensions: [KeyboardAwareScrollExtension],
    });
    const mountPoint = document.createElement('div');
    parent.appendChild(mountPoint);
    editor.mount(mountPoint);
    view().focus();
  }

  // Selects the end of the first line lying wholly between `from` and `to`, without scrolling.
  function placeCaretBetween(from:number, to:number):void {
    let target:number|undefined;
    view().state.doc.descendants((node, pos) => {
      if (target !== undefined) return false;
      if (!node.isTextblock) return true;

      const end = pos + node.nodeSize - 1;
      const { top, bottom } = view().coordsAtPos(end, 1);
      if (top >= from && bottom <= to) target = end;
      return false;
    });
    if (target === undefined) throw new Error(`No line lies between ${from}px and ${to}px`);

    view().dispatch(view().state.tr.setSelection(TextSelection.create(view().state.doc, target)));
  }

  const placeCaretUnderKeyboard = () => placeCaretBetween(keyboardTop() + LINE_HEIGHT, window.innerHeight - LINE_HEIGHT);
  const placeCaretAboveKeyboard = () => placeCaretBetween(0, keyboardTop() - LINE_HEIGHT);

  beforeEach(() => {
    viewport = new StandInViewport();
    Object.defineProperty(window, 'visualViewport', { configurable: true, get: () => viewport });
    document.body.style.margin = '0';
    scroller = document.createElement('div');
    scroller.setAttribute('style', `height: 100vh; overflow-y: auto; font: 16px/${LINE_HEIGHT}px sans-serif`);
    document.body.appendChild(scroller);
  });

  afterEach(() => {
    editor?.unmount();
    editor = undefined;
    scroller.remove();
    document.body.style.margin = '';
    delete (window as { visualViewport?:unknown }).visualViewport;
  });

  describe('with the keyboard up', () => {
    beforeEach(() => {
      mountEditor();
      raiseKeyboard();
      placeCaretUnderKeyboard();
    });

    it('lifts a caret the reader types at above the keyboard', async () => {
      await userEvent.keyboard('x');

      expect(caretBottom()).toBeLessThanOrEqual(keyboardTop());
    });

    it('lifts the line an Enter opens, which BlockNote never scrolls to', async () => {
      await userEvent.keyboard('{Enter}');

      expect(caretBottom()).toBeLessThanOrEqual(keyboardTop());
    });

    it('scrolls no further than it takes to clear the keyboard', async () => {
      await userEvent.keyboard('x');

      expect(caretBottom()).toBeGreaterThan(keyboardTop() - LINE_HEIGHT);
    });

    it('lifts the caret for a change that asks to scroll into view', () => {
      view().dispatch(view().state.tr.insertText('x').scrollIntoView());

      expect(caretBottom()).toBeLessThanOrEqual(keyboardTop());
    });

    it('does not follow a change the reader did not make, such as a collaborator\'s', () => {
      view().dispatch(view().state.tr.insertText('x', 1));

      expect(scroller.scrollTop).toBe(0);
    });
  });

  it('lifts a selected block above the keyboard', () => {
    mountEditor(scroller, [{ type: 'image' }]);
    raiseKeyboard();
    let imagePos = -1;
    view().state.doc.descendants((node, pos) => {
      if (node.type.name === 'image') imagePos = pos;
    });
    const imageBox = view().nodeDOM(imagePos) as HTMLElement;
    scroller.scrollTop += imageBox.getBoundingClientRect().top - (keyboardTop() + LINE_HEIGHT);

    view().dispatch(view().state.tr.setSelection(NodeSelection.create(view().state.doc, imagePos)).scrollIntoView());

    expect(imageBox.getBoundingClientRect().bottom).toBeLessThanOrEqual(keyboardTop());
  });

  it('crosses the shadow root the documents page mounts the editor in', async () => {
    const host = document.createElement('div');
    scroller.appendChild(host);
    mountEditor(host.attachShadow({ mode: 'open' }));
    raiseKeyboard();
    placeCaretUnderKeyboard();

    await userEvent.keyboard('x');

    expect(caretBottom()).toBeLessThanOrEqual(keyboardTop());
  });

  describe('when the keyboard rises', () => {
    beforeEach(() => mountEditor());

    it('keeps a caret it covers in view', async () => {
      placeCaretUnderKeyboard();

      raiseKeyboard();
      await nextFrame();

      expect(caretBottom()).toBeLessThanOrEqual(keyboardTop());
    });

    it('leaves a caret the reader had scrolled away from', async () => {
      placeCaretUnderKeyboard();
      scroller.scrollTop = window.innerHeight;
      const { scrollTop } = scroller;

      raiseKeyboard();
      await nextFrame();

      expect(scroller.scrollTop).toBe(scrollTop);
    });

    it('leaves a caret it does not cover', async () => {
      placeCaretAboveKeyboard();

      raiseKeyboard();
      await nextFrame();

      expect(scroller.scrollTop).toBe(0);
    });

    it('leaves an editor without focus', async () => {
      placeCaretUnderKeyboard();
      view().dom.blur();

      raiseKeyboard();
      await nextFrame();

      expect(scroller.scrollTop).toBe(0);
    });
  });

  describe('without a keyboard', () => {
    beforeEach(() => {
      mountEditor();
      placeCaretUnderKeyboard();
    });

    it('scrolls nothing', async () => {
      await userEvent.keyboard('x');

      expect(scroller.scrollTop).toBe(0);
    });

    it('takes a pinch-zoomed viewport for zoom, not for a keyboard', async () => {
      viewport.resize({ scale: 2 });

      await userEvent.keyboard('x');

      expect(scroller.scrollTop).toBe(0);
    });

    it('stops listening once unmounted', () => {
      const { dom } = view();
      const removed = vi.spyOn(dom, 'removeEventListener');

      editor!.unmount();
      editor = undefined;

      expect(removed).toHaveBeenCalledWith('keydown', expect.any(Function), true);
    });
  });
});
