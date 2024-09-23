/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 *
 */

import { Controller } from '@hotwired/stimulus';

export default class AttributeController extends Controller {
  static targets = [
    'expandButton',
    'textHider',
  ];

  static values = {
    backgroundReferenceId: { type: String, default: 'content' },
  };

  declare backgroundReferenceIdValue:string;

  declare readonly expandButtonTarget:HTMLButtonElement;
  declare readonly textHiderTarget:HTMLElement;

  descriptionTextTargetConnected(element:HTMLParagraphElement) {
    if (this.isEllipssed(element)) {
      this.setBackgroundToReference();
      this.unhideElement(this.textHiderTarget);
      this.unhideElement(this.expandButtonTarget);
    }
  }

  // When the displayed field contains a macro only, the ellipsis is being shown all the time,
  // in this case, we should take the textHiderTarget's width into account, otherwise the
  // text will overflow the ellipsis icon. When a text with the exact size of the column is
  // displayed, the textHiderTarget is hidden having the offsedWidth 0. This means we will allow
  // the full width of the column to be used for the text, and not truncate it unnecessarily.
  private isEllipssed(e:HTMLElement) {
    return (e.offsetWidth - this.textHiderTarget.offsetWidth) < e.scrollWidth
      || e.offsetHeight < e.scrollHeight;
  }

  // Sets the background of the text hider element (the one below the expand button) to the background of the reference.
  // That reference by default is the `#content` element. This is necessary so that the text hider can actually lay on top
  // of the text and hide it without being obvious. It would have been sufficient to just use the button element for this
  // if that button were not using a background color with an 0.2 alpha value. Without the text hider, the text would
  // shine through.
  private setBackgroundToReference() {
    const backgroundReference = document.getElementById(this.backgroundReferenceIdValue);
    if (backgroundReference) {
      const backgroundColor = window.getComputedStyle(backgroundReference).backgroundColor;
      this.textHiderTarget.style.backgroundColor = backgroundColor;
      this.textHiderTarget.classList.remove('d-none');
    }
  }

  private unhideElement(element:HTMLElement) {
    element.classList.remove('d-none');
  }
}
