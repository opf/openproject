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

import { createExtension } from '@blocknote/core';
import { EditorState, Plugin, PluginKey } from 'prosemirror-state';
import { EditorView } from 'prosemirror-view';

// ProseMirror reads the visual viewport only for the window, but on a phone the documents
// page scrolls in #content-wrapper, whose `dvh` height does not shrink for the on-screen
// keyboard. A caret under the keyboard therefore still counts as visible.

const SCROLL_MARGIN = 5;

// BlockNote splits a block on Enter without `scrollIntoView`, so changes right after the
// reader's own input are followed too.
const INPUT_EVENTS = ['keydown', 'beforeinput', 'input', 'compositionend'] as const;
const TYPING_WINDOW_MS = 500;

// Size only, never `offsetTop`: engines disagree on which viewport client rects are relative to.
// A pinch-zoomed viewport shrinks for the zoom, not for a keyboard.
function keyboardTop():number {
  const viewport = window.visualViewport;
  if (viewport?.scale !== 1) return window.innerHeight;

  return Math.min(viewport.height, window.innerHeight);
}

function parentOf(element:Element):Element|null {
  if (element.parentElement) return element.parentElement;

  const root = element.getRootNode();
  return root instanceof ShadowRoot ? root.host : null;
}

// Stops short of the body: ProseMirror scrolls the window against the visual viewport itself.
function* scrollContainersAround(element:Element):Generator<Element> {
  for (let parent = parentOf(element); parent && parent !== document.body; parent = parentOf(parent)) {
    const { overflowY, position } = window.getComputedStyle(parent);
    if (overflowY === 'auto' || overflowY === 'scroll') yield parent;
    if (position === 'fixed' || position === 'sticky') return;
  }
}

function caretRect(view:EditorView):{ top:number, bottom:number } {
  return view.coordsAtPos(view.state.selection.head, 1);
}

function liftAboveKeyboard(view:EditorView):void {
  const keyboardEdge = keyboardTop();
  if (keyboardEdge >= window.innerHeight) return;

  const limit = keyboardEdge - SCROLL_MARGIN;
  let { top, bottom } = caretRect(view);

  for (const container of scrollContainersAround(view.dom)) {
    if (bottom <= limit) return;

    const box = container.getBoundingClientRect();
    if (box.bottom <= limit || top < box.top) continue;

    const before = container.scrollTop;
    container.scrollTop += Math.min(bottom - limit, top - box.top);
    const moved = container.scrollTop - before;
    top -= moved;
    bottom -= moved;
  }
}

function followKeyboard(view:EditorView) {
  const viewport = window.visualViewport;
  let lastKeyboardTop = keyboardTop();
  let lastInputAt = -Infinity;

  const onInput = ():void => { lastInputAt = performance.now(); };

  // Only a caret the keyboard just covered; one the reader scrolled away from stays put.
  const onResize = ():void => {
    const previous = lastKeyboardTop;
    lastKeyboardTop = keyboardTop();
    if (lastKeyboardTop < previous && view.hasFocus() && caretRect(view).bottom <= previous) liftAboveKeyboard(view);
  };

  INPUT_EVENTS.forEach((type) => view.dom.addEventListener(type, onInput, true));
  viewport?.addEventListener('resize', onResize);

  return {
    update: (_view:EditorView, prevState:EditorState) => {
      const moved = view.state.doc !== prevState.doc || !view.state.selection.eq(prevState.selection);
      const typing = performance.now() - lastInputAt < TYPING_WINDOW_MS;
      if (moved && typing && view.hasFocus()) liftAboveKeyboard(view);
    },
    destroy: () => {
      INPUT_EVENTS.forEach((type) => view.dom.removeEventListener(type, onInput, true));
      viewport?.removeEventListener('resize', onResize);
    },
  };
}

export const KeyboardAwareScrollExtension = createExtension({
  key: 'keyboardAwareScroll',

  prosemirrorPlugins: [
    new Plugin({
      key: new PluginKey('keyboardAwareScroll'),
      props: {
        handleScrollToSelection: (view) => {
          liftAboveKeyboard(view);
          return false;
        },
      },
      view: followKeyboard,
    }),
  ],
});
