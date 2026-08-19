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
 */

import { toggleElement, toggleElementByClass, toggleElementByVisibility } from 'core-app/shared/helpers/dom-helpers';
import { ApplicationController } from 'stimulus-use';

// can show OR hide items by default (with "reversed" set to hide on checking)
// can show AND hide items (toggling between them) by using "show-when" data attribute
export default class OpShowWhenCheckedController extends ApplicationController {
  static targets = ['cause', 'effect'];

  static values = {
    reversed: Boolean,
  };

  static classes = ['visibility'];

  declare reversedValue:boolean;
  declare readonly hasReversedValue:boolean;
  declare readonly effectTargets:HTMLElement[];

  declare readonly visibilityClass:string;
  declare readonly hasVisibilityClass:boolean;

  private boundListener = this.toggle.bind(this);

  causeTargetConnected(target:HTMLElement) {
    target.addEventListener('change', this.boundListener);
  }

  causeTargetDisconnected(target:HTMLElement) {
    target.removeEventListener('change', this.boundListener);
  }

  private toggle(evt:InputEvent):void {
    const input = evt.target as HTMLInputElement;
    const checked = input.checked;
    const targetName = input.dataset.targetName;

    const activeState = (this.hasReversedValue && this.reversedValue) ? !checked : checked;

    this
      .effectTargets
      .filter((el) => targetName === el.dataset.targetName)
      .forEach((el) => {
        const showWhen = el.dataset.showWhen;

        let shouldShow:boolean;

        if (showWhen === 'checked') {
          shouldShow = activeState;
        } else if (showWhen === 'unchecked') {
          shouldShow = !activeState;
        } else {
          shouldShow = activeState;
        }

        if (el.dataset.setVisibility === 'true') {
          toggleElementByVisibility(el, shouldShow);
        } else if (this.hasVisibilityClass) {
          toggleElementByClass(el, this.visibilityClass, shouldShow);
        } else if ('visibilityClass' in el.dataset) {
          toggleElementByClass(el, el.dataset.visibilityClass!, shouldShow);
        } else {
          toggleElement(el, shouldShow);
        }
      });
  }
}
