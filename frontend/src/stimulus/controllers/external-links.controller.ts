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

import { attributeTokenList } from 'core-app/shared/helpers/dom-helpers';
import { ApplicationController } from 'stimulus-use';
import { useMutation } from 'stimulus-use';
import { buildExternalRedirectUrl, isExternalLinkCandidate, isLinkBlank, isLinkExternal } from '../helpers/external-link-helpers';

const BLANK_LINK_DESCRIPTION_ID = 'open-blank-target-link-description';
const LINK_QUERY = 'a[target="_blank"], a[href^="http://"], a[href^="https://"]';

const isElement = (node:Node):node is Element => node.nodeType === Node.ELEMENT_NODE;
const isLink = (elem:Element):elem is HTMLAnchorElement => elem.matches(LINK_QUERY);

/**
 * Dynamically observes and processes all links on the page, including those added later via Turbo
 * frames or DOM mutations.
 *
 * Part A) for links with `target="_blank"`
 *   - Adds `aria-describedby` pointing to a description element (`BLANK_LINK_DESCRIPTION_ID`) to
 *     inform users of assistive technologies that the link opens in a new tab.
 *
 * Part B) for external links (pointing to a different domain than the current page):
 *   - Sets `target="_blank"` to open in a new tab.
 *   - Sets `rel="noopener noreferrer"` for security and performance.
 *   - Rewrites the href to go through `/external_redirect` for link capture functionality.
 *   - and by virtue of setting `target="_blank"`, should be processed as in Part A.
 *
 * This ensures accessibility, security, and consistent behavior for all links, including
 * dynamically loaded content.
 */
export default class ExternalLinksController extends ApplicationController {
  static values = {
    enabled: Boolean
  };

  declare readonly enabledValue:boolean;

  connect() {
    useMutation(this, { attributes: true, childList: true, subtree: true, attributeFilter: ['target', 'href'] });

    // Initial pass: handle existing external links (accessibility)
    this.element.querySelectorAll<HTMLAnchorElement>(LINK_QUERY).forEach((link)=>{
      if (!isExternalLinkCandidate(link)) return;

      if (isLinkBlank(link)) this.updateBlankLink(link);

      if (isLinkExternal(link)) this.updateExternalLink(link);
    });
  }

  mutate(mutations:MutationRecord[]) {
    mutations.forEach((mutation) => {
      mutation.addedNodes.forEach((node) => {
        if (isElement(node)) {
          // Added element itself is an external link
          if (isLink(node) && isExternalLinkCandidate(node)) {
            if (isLinkBlank(node)) this.updateBlankLink(node);
            if (isLinkExternal(node)) this.updateExternalLink(node);
          }

          node.querySelectorAll<HTMLAnchorElement>(LINK_QUERY).forEach((link)=>{
            if (!isExternalLinkCandidate(link)) return;

            if (isLinkBlank(link)) this.updateBlankLink(link);

            if (isLinkExternal(link)) this.updateExternalLink(link);
          });
        }
      });

      // Attribute changes
      if (
        mutation.type === 'attributes' &&
        isElement(mutation.target) &&
        isLink(mutation.target) &&
        isExternalLinkCandidate(mutation.target)
      ) {
        if (mutation.attributeName === 'target' && isLinkBlank(mutation.target)) this.updateBlankLink(mutation.target);
        if (mutation.attributeName === 'href' && isLinkExternal(mutation.target)) this.updateExternalLink(mutation.target);
      }
    });
  }

  private updateBlankLink(link:HTMLAnchorElement) {
    attributeTokenList(link, 'aria-describedby').add(BLANK_LINK_DESCRIPTION_ID);
  }

  private updateExternalLink(link:HTMLAnchorElement) {
    if (!link.dataset.skipExternalLinkBlank) {
      link.target = '_blank';
    }
    attributeTokenList(link, 'rel').add('noopener', 'noreferrer');

    // Capture external links through redirect page
    // The backend controller will redirect directly if the feature is disabled
    if (this.enabledValue && !link.dataset.allowExternalLink) {
      link.href = buildExternalRedirectUrl(link.href);
    }
  }

}
