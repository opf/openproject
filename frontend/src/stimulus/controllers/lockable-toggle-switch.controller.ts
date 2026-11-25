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

import { Controller } from '@hotwired/stimulus';

const ACTIVATION_KEYS = ['Enter', ' ', 'Spacebar'];

export default class LockableToggleSwitchController extends Controller {
  static values = {
    buttonId: String,
  };

  declare buttonIdValue:string;

  connect():void {
    this.anchorTooltipToButton();

    this.element.addEventListener('click', this.blockActivation, { capture: true });
    this.element.addEventListener('keydown', this.blockActivation, { capture: true });
  }

  disconnect():void {
    this.element.removeEventListener('click', this.blockActivation, { capture: true });
    this.element.removeEventListener('keydown', this.blockActivation, { capture: true });
  }

  // Primer resolves a tooltip's anchor with `document.getElementById(for)` and listens for
  // `focus` on it, which does not bubble. ToggleSwitch exposes no way to set an id on the
  // button it renders, so the anchor is moved onto that button here - otherwise the tooltip
  // would only ever appear on hover.
  private anchorTooltipToButton():void {
    const button = this.element.querySelector('button.ToggleSwitch-track');
    const tooltip = this.element.nextElementSibling;

    if (!button || !this.buttonIdValue || tooltip?.tagName.toLowerCase() !== 'tool-tip') {
      return;
    }

    button.id = this.buttonIdValue;

    // Re-assigning `for` is what makes the tooltip look the anchor up again.
    tooltip.setAttribute('for', '');
    tooltip.setAttribute('for', this.buttonIdValue);
  }

  // `aria-disabled` keeps the switch focusable, so it has to refuse activation here.
  private blockActivation = (event:Event):void => {
    const target = event.target as HTMLElement|null;

    if (!target?.closest('[aria-disabled="true"]')) {
      return;
    }

    if (event instanceof KeyboardEvent && !ACTIVATION_KEYS.includes(event.key)) {
      return;
    }

    event.preventDefault();
    event.stopImmediatePropagation();
  };
}
