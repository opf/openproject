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

import { attributeTokenList, ensureId, generateId } from './dom-helpers';

export type TooltipType = 'label'|'description';

export function withTooltip(control:HTMLElement, text:string, type:TooltipType):DocumentFragment {
  const fragment = document.createDocumentFragment();
  control.title = '';
  fragment.append(control);
  if (!text) return fragment;

  const tooltip = document.createElement('tool-tip');
  tooltip.id = generateId('tooltip');
  tooltip.setAttribute('for', ensureId(control));
  tooltip.setAttribute('popover', 'manual');
  tooltip.dataset.type = type;
  tooltip.dataset.direction = 's';
  tooltip.classList.add('sr-only', 'position-absolute');
  tooltip.textContent = text;

  // Primer's pending focus handler can outlive owner removal: https://community.openproject.org/wp/DREAM-955.
  const showPopover = tooltip.showPopover.bind(tooltip);
  tooltip.showPopover = (options?:ShowPopoverOptions) => {
    if (tooltip.isConnected) showPopover(options);
  };

  if (type === 'label') tooltip.setAttribute('aria-hidden', 'true');
  attributeTokenList(control, type === 'label' ? 'aria-labelledby' : 'aria-describedby').add(tooltip.id);
  fragment.append(tooltip);
  return fragment;
}

export function hideTooltip(control:HTMLElement):void {
  const tooltip = control.ownerDocument.querySelector<HTMLElement>(`tool-tip[for="${CSS.escape(control.id)}"]`);
  if (tooltip?.matches(':popover-open')) tooltip.hidePopover();
}
