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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { createExtension } from '@blocknote/core';
import { Plugin, PluginKey } from 'prosemirror-state';
import { buildExternalRedirectUrl, isExternalLinkCandidate, isLinkExternal } from 'core-stimulus/helpers/external-link-helpers';

/**
 * BlockNote extension that intercepts clicks on external links and routes them
 * through `/external_redirect` for phishing prevention.
 *
 * Uses ProseMirror's `handleDOMEvents.mousedown` to intercept before
 * ProseMirror creates its internal MouseDown tracker. Returning `true`
 * prevents the entire ProseMirror click chain (mousedown → MouseDown.up →
 * handleSingleClick → handleClick), so the editor never calls
 * `window.open` with the original URL. Only our redirect window opens.
 *
 * This extension should only be registered when external link capture is
 * enabled — when disabled, the editor's default link handling applies and
 * link clicks are handled natively.
 */
export const ExternalLinkCaptureExtension = createExtension({
  key: 'externalLinkCapture',

  prosemirrorPlugins: [
    new Plugin({
      key: new PluginKey('externalLinkCapture'),
      props: {
        handleDOMEvents: {
          mousedown: (view, event) => {
            // Left-click (0) and middle-click (1) only — right-click (2)
            // opens the native context menu which reads href from the DOM
            // and cannot be intercepted via JavaScript.
            if (event.button !== 0 && event.button !== 1) return false;

            const target = event.target instanceof Element
              ? event.target
              : (event.target as Node)?.parentElement;
            const link = target?.closest('a');
            if (!(link instanceof HTMLAnchorElement)) return false;
            if (!view.dom.contains(link)) return false;
            if (!isExternalLinkCandidate(link)) return false;
            if (!isLinkExternal(link)) return false;
            if (link.dataset.allowExternalLink) return false;

            event.preventDefault();
            window.open(buildExternalRedirectUrl(link.href), '_blank', 'noopener,noreferrer');
            return true;
          },
        },
      },
    }),
  ],
});
