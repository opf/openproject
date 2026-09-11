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
import { Plugin, PluginKey } from 'prosemirror-state';

const pluginKey = new PluginKey('collaborationCursorLabelFit');

const BASE_SELECTOR = '.bn-collaboration-cursor__base';
const LABEL_SELECTOR = '.bn-collaboration-cursor__label';
export const FLIPPED_ATTRIBUTE = 'data-op-label-flipped';
export const BELOW_ATTRIBUTE = 'data-op-label-below';

// Inline padding BlockNote gives an expanded label (2 * 0.3rem), plus a pixel of slack.
const LABEL_PADDING = 11;
// Ceiling BlockNote puts on an expanded label (`max-width: 20rem`); a longer name is cut.
// In rem, so a reader's larger default font raises it and the label is measured as wide
// as it will actually be drawn.
const LABEL_MAX_WIDTH_REM = 20;
// How far above the caret BlockNote lifts an expanded label (`top: -17px`).
const LABEL_RISE = 17;
// A table's first row leaves a label exactly that rise and nothing more, so rounding
// alone would decide its fit. Flip only for a clip deeper than the label's corner.
const CLIP_TOLERANCE = 2;

interface LabelFit {
  base:HTMLElement;
  flipped:boolean;
  below:boolean;
}

function clippingRect(base:HTMLElement, editorDom:HTMLElement):DOMRect {
  for (let node = base.parentElement; node && node !== editorDom; node = node.parentElement) {
    const { overflowX, overflowY } = window.getComputedStyle(node);

    if (overflowX !== 'visible' || overflowY !== 'visible') return node.getBoundingClientRect();
  }

  return editorDom.getBoundingClientRect();
}

function expandedLabelWidth(label:HTMLElement):number {
  const { paddingLeft, paddingRight } = window.getComputedStyle(label);
  const text = label.scrollWidth - parseFloat(paddingLeft) - parseFloat(paddingRight);
  const rem = parseFloat(window.getComputedStyle(document.documentElement).fontSize);

  return Math.min(text + LABEL_PADDING, LABEL_MAX_WIDTH_REM * rem);
}

function measureLabelFit(base:HTMLElement, editorDom:HTMLElement):LabelFit|null {
  const label = base.querySelector<HTMLElement>(LABEL_SELECTOR);
  if (!label) return null;

  const bounds = clippingRect(base, editorDom);
  const caret = base.getBoundingClientRect();

  return {
    base,
    flipped: caret.left + expandedLabelWidth(label) > bounds.right,
    below: caret.top - LABEL_RISE < bounds.top - CLIP_TOLERANCE,
  };
}

export function fitCollaborationCursorLabels(editorDom:HTMLElement):void {
  const bases = Array.from(editorDom.querySelectorAll<HTMLElement>(BASE_SELECTOR));

  const fits = bases
    .map((base) => measureLabelFit(base, editorDom))
    .filter((fit):fit is LabelFit => fit !== null);

  fits.forEach(({ base, flipped, below }) => {
    base.toggleAttribute(FLIPPED_ATTRIBUTE, flipped);
    base.toggleAttribute(BELOW_ATTRIBUTE, below);
  });
}

export const CollaborationCursorLabelFitExtension = createExtension({
  key: 'collaborationCursorLabelFit',

  prosemirrorPlugins: [
    new Plugin({
      key: pluginKey,
      view: (view) => {
        let frame:number|null = null;

        const schedule = ():void => {
          if (frame !== null) return;
          frame = requestAnimationFrame(() => {
            frame = null;
            fitCollaborationCursorLabels(view.dom);
          });
        };

        const resizeObserver = new ResizeObserver(schedule);
        resizeObserver.observe(view.dom);

        return {
          update: schedule,
          destroy: () => {
            resizeObserver.disconnect();
            if (frame !== null) cancelAnimationFrame(frame);
          },
        };
      },
    }),
  ],
});
