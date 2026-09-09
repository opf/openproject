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

// Inline padding BlockNote gives an expanded label (2 * 0.3rem), plus a pixel of slack.
const LABEL_PADDING = 11;

export function fitCollaborationCursorLabels(editorDom:HTMLElement):void {
  const bases = editorDom.querySelectorAll<HTMLElement>(BASE_SELECTOR);
  if (bases.length === 0) return;

  const editorRight = editorDom.getBoundingClientRect().right;

  bases.forEach((base) => {
    const label = base.querySelector<HTMLElement>(LABEL_SELECTOR);
    if (!label) return;

    const labelRight = base.getBoundingClientRect().left + label.scrollWidth + LABEL_PADDING;

    base.toggleAttribute(FLIPPED_ATTRIBUTE, labelRight > editorRight);
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
